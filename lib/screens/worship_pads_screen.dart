import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../models/sound_entry.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/key_card.dart';
import '../widgets/mode_tab.dart';
import '../screens/sound_library_screen.dart';
import '../services/sound_library_service.dart';

class WorshipPadsScreen extends StatefulWidget {
  const WorshipPadsScreen({
    super.key,
    this.initialLibrarySounds = const {},
    this.initialActiveSoundPaths = const {},
  });

  final Map<String, List<SoundEntry>> initialLibrarySounds;
  final Map<String, String> initialActiveSoundPaths;

  @override
  State<WorshipPadsScreen> createState() => _WorshipPadsScreenState();
}

class _WorshipPadsScreenState extends State<WorshipPadsScreen> {
  static const List<String> _majorKeys = ['E', 'F', 'G', 'A', 'B', 'C', 'D'];
  static const List<String> _minorKeys = ['C#m', 'D#m', 'Em', 'F#m', 'G#m', 'Am', 'Bm'];

  static const Duration _fadeOutDuration = Duration(milliseconds: 7000);
  // Step every ~33ms regardless of total duration, for a smooth ramp.
  static const int _fadeStepMs = 33;
  static const double _maxVolume = 100.0;
  // Each note decodes a ~21MB mp3 in its own Player, and a fade-out keeps the
  // old one alive for 7s. Cap concurrent players so spam-tapping can't pile up
  // enough decoders to OOM a low-RAM phone.
  static const int _maxConcurrentPlayers = 4;

  bool _showMajor = true;
  String? _playingKey;
  String? _playingFolderId;
  String _selectedDrawerItem = 'Pads';
  final _libraryService = SoundLibraryService();

  // The player whose note is currently selected (fading in or at full volume).
  Player? _activePlayer;
  // Every live player (active + still fading out) mapped to its completed-event
  // subscription. The subscription MUST be cancelled before the player is
  // disposed, otherwise mpv can invoke the callback after teardown and crash
  // the engine ("Callback invoked after it has been deleted").
  final Map<Player, StreamSubscription<bool>> _players = {};
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _libraryService.init(
      initialLibrarySounds: widget.initialLibrarySounds,
      initialActiveSoundPaths: widget.initialActiveSoundPaths,
    );
    _libraryService.addListener(_onLibraryChanged);
  }

  void _onLibraryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    _libraryService.removeListener(_onLibraryChanged);
    _activePlayer = null;
    // Tear each player down through _disposePlayer (cancels its subscription
    // first, then stops + disposes). Fired with unawaited(): dispose() is
    // synchronous so the async teardown completes after this returns, but
    // cancelling the subscription up front prevents any post-teardown callback.
    for (final player in _players.keys.toList()) {
      unawaited(_disposePlayer(player));
    }
    super.dispose();
  }

  String _folderId(String mode, String key) => '$mode::$key';

  // Cancels [player]'s completed-event subscription, then stops and disposes it.
  // Cancelling first is what prevents mpv from firing the callback into a torn-
  // down player. Every step is guarded so one failure can't strand the player.
  Future<void> _disposePlayer(Player player) async {
    final sub = _players.remove(player);
    try {
      await sub?.cancel();
    } catch (_) {}
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  // Ramps [player] volume 100->0 over [_fadeOutDuration]. The loop aborts the
  // moment the player is no longer tracked (it was disposed) so setVolume is
  // never called on a dead player — that race is what crashed the engine.
  // (There is no code fade-in: the mp3s already include one.)
  Future<void> _fadeOut(Player player) async {
    final steps = (_fadeOutDuration.inMilliseconds / _fadeStepMs).ceil();
    final stepDelay = Duration(milliseconds: _fadeStepMs);
    for (var i = 1; i <= steps; i++) {
      if (_disposed || !_players.containsKey(player)) return;
      final volume = (1 - i / steps) * _maxVolume;
      try {
        await player.setVolume(volume.clamp(0.0, _maxVolume));
      } catch (_) {
        return; // player went away mid-fade
      }
      await Future.delayed(stepDelay);
    }
  }

  // Detaches [player] from the active slot and fades it out independently, then
  // disposes it. Does not block the caller — the new note can start instantly.
  void _fadeOutAndDispose(Player player) {
    // Spam-tap guard: if too many players are already fading out, hard-dispose
    // the oldest ones now instead of waiting out their 7s fade. _players keeps
    // insertion order, so the first non-active keys are the oldest fades.
    if (_players.length > _maxConcurrentPlayers) {
      final excess = _players.length - _maxConcurrentPlayers;
      final oldest = _players.keys
          .where((p) => p != player && p != _activePlayer)
          .take(excess)
          .toList();
      for (final p in oldest) {
        unawaited(_disposePlayer(p));
      }
    }
    () async {
      await _fadeOut(player);
      await _disposePlayer(player);
    }();
  }

  Future<void> _stopPlayback() async {
    final player = _activePlayer;
    _activePlayer = null;
    if (mounted) {
      setState(() { _playingKey = null; _playingFolderId = null; });
    } else {
      _playingKey = null;
      _playingFolderId = null;
    }
    if (player != null) _fadeOutAndDispose(player);
  }

  Future<void> _playSoundForKey(String key) async {
    final mode = _showMajor ? 'Major' : 'Minor';
    final folderId = _folderId(mode, key);

    if (_playingFolderId == folderId) { await _stopPlayback(); return; }

    final activeSound = _libraryService.activeSoundFor(mode, key);
    if (activeSound == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No active sound selected for $mode - $key')),
      );
      return;
    }

    // For user-imported files, verify the file still exists on disk.
    if (!activeSound.isAsset) {
      final audioFile = File(activeSound.path);
      if (!await audioFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File not found: ${activeSound.name}')),
        );
        return;
      }
    }

    // Detach the outgoing note onto its own fading player so the new note can
    // play this instant while the old one fades out in parallel (crossfade).
    final outgoing = _activePlayer;
    if (outgoing != null) _fadeOutAndDispose(outgoing);

    final player = Player();
    _activePlayer = player;
    bool isActive() => _activePlayer == player;

    // Register the completed-event subscription up front so teardown can always
    // find and cancel it before disposing the player.
    final sub = player.stream.completed.listen((completed) {
      if (completed && isActive() && mounted) {
        setState(() { _playingKey = null; _playingFolderId = null; });
        _activePlayer = null;
        _disposePlayer(player);
      }
    });
    _players[player] = sub;

    try {
      // The mp3s already include a fade-in, so start at full volume — no code
      // fade-in (it would stack with the baked-in one and dull the onset).
      await player.setVolume(_maxVolume);
      // activeSound.path is already the correct URI:
      //   - bundled assets use  "asset:///assets/audio/…"
      //   - user files use the absolute file-system path
      await player.open(Media(activeSound.path), play: true);
      if (!mounted || _activePlayer != player) {
        await _disposePlayer(player);
        if (_activePlayer == player) _activePlayer = null;
        return;
      }
      setState(() { _playingKey = key; _playingFolderId = folderId; });
    } on Exception catch (error, stackTrace) {
      debugPrint('Playback failed for ${activeSound.path}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (_activePlayer == player) _activePlayer = null;
      await _disposePlayer(player);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to play ${activeSound.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = _showMajor ? _majorKeys : _minorKeys;
    final colors = AppColors.of(context);

    return Scaffold(
      drawer: AppDrawer(
        selectedItem: _selectedDrawerItem,
        onSelectItem: (item) => setState(() => _selectedDrawerItem = item),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Icon(Icons.menu, color: colors.textPrimary, size: 28),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.music_note, color: colors.accent, size: 30),
                  const SizedBox(width: 8),
                  Text('Worship Pads', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colors.textPrimary),
                    color: colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.border),
                    ),
                    onSelected: (value) {
                      if (value == 'sound_library') {
                        final service = SoundLibraryService();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SoundLibraryScreen(
                              soundsFor: service.soundsFor,
                              activeSoundPathFor: service.activeSoundPathFor,
                              onAddSound: service.addSoundToFolder,
                              onDeleteSound: service.removeSoundFromFolder,
                              onSetActiveSound: service.setActiveSoundForFolder,
                              onClearActiveSound: service.clearActiveSoundForFolder,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'sound_library',
                        child: Row(
                          children: [
                            Icon(Icons.library_music_outlined, color: colors.textPrimary, size: 20),
                            const SizedBox(width: 12),
                            Text('Sound Library', style: TextStyle(color: colors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Expanded(child: ModeTab(label: 'Major', isSelected: _showMajor, onTap: () {
                    setState(() { _showMajor = true; });
                  })),
                  Expanded(child: ModeTab(label: 'Minor', isSelected: !_showMajor, onTap: () {
                    setState(() { _showMajor = false; });
                  })),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 16, 15, 20),
                child: GridView.builder(
                  itemCount: keys.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 14, childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final keyLabel = keys[index];
                    return KeyCard(label: keyLabel, isPlaying: _playingKey == keyLabel, onTap: () => _playSoundForKey(keyLabel));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
