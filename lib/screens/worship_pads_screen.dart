import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../models/sound_entry.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/key_card.dart';
import '../widgets/mode_tab.dart';
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

  bool _showMajor = true;
  String? _playingKey;
  String? _playingFolderId;
  String _selectedDrawerItem = 'Pads';
  final _libraryService = SoundLibraryService();
  Player? _audioPlayer;

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

  Player _ensurePlayer() {
    if (_audioPlayer != null) return _audioPlayer!;
    final player = Player();
    player.stream.completed.listen((completed) {
      if (completed && mounted) {
        setState(() { _playingKey = null; _playingFolderId = null; });
      }
    });
    _audioPlayer = player;
    return player;
  }

  @override
  void dispose() {
    _libraryService.removeListener(_onLibraryChanged);
    _audioPlayer?.dispose();
    super.dispose();
  }

  String _folderId(String mode, String key) => '$mode::$key';

  Future<void> _stopPlayback() async {
    await _audioPlayer?.stop();
    if (!mounted) return;
    setState(() { _playingKey = null; _playingFolderId = null; });
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

    try {
      final player = _ensurePlayer();
      await player.stop();
      // activeSound.path is already the correct URI:
      //   - bundled assets use  "asset:///assets/audio/…"
      //   - user files use the absolute file-system path
      await player.open(Media(activeSound.path), play: true);
      if (!mounted) return;
      setState(() { _playingKey = key; _playingFolderId = folderId; });
    } on Exception catch (error, stackTrace) {
      debugPrint('Playback failed for ${activeSound.path}: $error');
      debugPrintStack(stackTrace: stackTrace);
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
                  const SizedBox(width: 48),
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
                  Expanded(child: ModeTab(label: 'Major', isSelected: _showMajor, onTap: () async {
                    if (!_showMajor) await _stopPlayback();
                    if (!mounted) return;
                    setState(() { _showMajor = true; });
                  })),
                  Expanded(child: ModeTab(label: 'Minor', isSelected: !_showMajor, onTap: () async {
                    if (_showMajor) await _stopPlayback();
                    if (!mounted) return;
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
