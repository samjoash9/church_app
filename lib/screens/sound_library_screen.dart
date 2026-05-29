import 'package:flutter/material.dart';

import '../models/sound_entry.dart';
import '../theme/app_colors.dart';
import '../widgets/dialog_action_button.dart';
import '../widgets/section_header.dart';

class SoundLibraryScreen extends StatelessWidget {
  const SoundLibraryScreen({
    super.key,
    required this.soundsFor,
    required this.activeSoundPathFor,
    required this.onAddSound,
    required this.onDeleteSound,
    required this.onSetActiveSound,
    required this.onClearActiveSound,
  });

  static const List<String> _majorFolders = ['E', 'F', 'G', 'A', 'B', 'C', 'D'];
  static const List<String> _minorFolders = ['C#m', 'D#m', 'Em', 'F#m', 'G#m', 'Am', 'Bm'];

  final List<SoundEntry> Function(String mode, String key) soundsFor;
  final String? Function(String mode, String key) activeSoundPathFor;
  final Future<void> Function(BuildContext context, String mode, String key) onAddSound;
  final void Function(String mode, String key, SoundEntry sound) onDeleteSound;
  final void Function(String mode, String key, SoundEntry sound) onSetActiveSound;
  final void Function(String mode, String key) onClearActiveSound;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SectionHeader(
              title: 'Sound Library',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: GridView.count(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.95,
                  children: [
                    LibraryFolderCard(cardKey: const Key('sound-library-major'), label: 'Major', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => FolderCollectionPage(
                        title: 'Major', folders: _majorFolders, soundsFor: soundsFor,
                        activeSoundPathFor: activeSoundPathFor, onAddSound: onAddSound,
                        onDeleteSound: onDeleteSound, onSetActiveSound: onSetActiveSound,
                        onClearActiveSound: onClearActiveSound,
                      )));
                    }),
                    LibraryFolderCard(cardKey: const Key('sound-library-minor'), label: 'Minor', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => FolderCollectionPage(
                        title: 'Minor', folders: _minorFolders, soundsFor: soundsFor,
                        activeSoundPathFor: activeSoundPathFor, onAddSound: onAddSound,
                        onDeleteSound: onDeleteSound, onSetActiveSound: onSetActiveSound,
                        onClearActiveSound: onClearActiveSound,
                      )));
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryFolderCard extends StatelessWidget {
  const LibraryFolderCard({super.key, this.cardKey, required this.label, this.onTap});
  final Key? cardKey;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: cardKey, borderRadius: BorderRadius.circular(16), onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_outlined, color: colors.textPrimary, size: 48),
              const SizedBox(height: 16),
              Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class FolderCollectionPage extends StatelessWidget {
  const FolderCollectionPage({
    super.key, required this.title, required this.folders, required this.soundsFor,
    required this.activeSoundPathFor, required this.onAddSound, required this.onDeleteSound,
    required this.onSetActiveSound, required this.onClearActiveSound,
  });
  final String title;
  final List<String> folders;
  final List<SoundEntry> Function(String mode, String key) soundsFor;
  final String? Function(String mode, String key) activeSoundPathFor;
  final Future<void> Function(BuildContext context, String mode, String key) onAddSound;
  final void Function(String mode, String key, SoundEntry sound) onDeleteSound;
  final void Function(String mode, String key, SoundEntry sound) onSetActiveSound;
  final void Function(String mode, String key) onClearActiveSound;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SectionHeader(title: title, onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: GridView.builder(
                  itemCount: folders.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return LibraryFolderCard(label: folder, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SoundFolderPage(
                        mode: title, folder: folder,
                        soundsFor: () => soundsFor(title, folder),
                        activeSoundPathFor: () => activeSoundPathFor(title, folder),
                        onAddSound: () => onAddSound(context, title, folder),
                        onDeleteSound: (sound) => onDeleteSound(title, folder, sound),
                        onSetActiveSound: (sound) => onSetActiveSound(title, folder, sound),
                        onClearActiveSound: () => onClearActiveSound(title, folder),
                      )));
                    });
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

class SoundFolderPage extends StatefulWidget {
  const SoundFolderPage({
    super.key, required this.mode, required this.folder, required this.soundsFor,
    required this.activeSoundPathFor, required this.onAddSound, required this.onDeleteSound,
    required this.onSetActiveSound, required this.onClearActiveSound,
  });
  final String mode;
  final String folder;
  final List<SoundEntry> Function() soundsFor;
  final String? Function() activeSoundPathFor;
  final Future<void> Function() onAddSound;
  final void Function(SoundEntry sound) onDeleteSound;
  final void Function(SoundEntry sound) onSetActiveSound;
  final VoidCallback onClearActiveSound;

  @override
  State<SoundFolderPage> createState() => _SoundFolderPageState();
}

class _SoundFolderPageState extends State<SoundFolderPage> {
  Future<void> _handleAddSound() async {
    await widget.onAddSound();
    if (mounted) setState(() {});
  }

  Future<void> _handleDeleteSound(SoundEntry sound) async {
    final colors = AppColors.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 12),
          titlePadding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          title: Text('Delete Sound', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this?', style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: DialogActionButton(label: 'Cancel', backgroundColor: colors.surfaceDim, foregroundColor: colors.textPrimary, onTap: () => Navigator.of(dialogContext).pop(false))),
                const SizedBox(width: 12),
                Expanded(child: DialogActionButton(label: 'Confirm', backgroundColor: colors.danger, foregroundColor: Colors.white, onTap: () => Navigator.of(dialogContext).pop(true))),
              ]),
            ],
          ),
          actions: const [],
        );
      },
    );
    if (shouldDelete != true || !mounted) return;
    widget.onDeleteSound(sound);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final title = '${widget.mode} - ${widget.folder}';
    final sounds = widget.soundsFor();
    final activeSoundPath = widget.activeSoundPathFor();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SectionHeader(title: title, onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (sounds.isEmpty)
                    AddSoundCard(onTap: _handleAddSound)
                  else ...[
                    CompactAddSoundButton(onTap: _handleAddSound),
                    const SizedBox(height: 14),
                    ...sounds.map((sound) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ImportedSoundTile(
                        sound: sound, isActive: activeSoundPath == sound.path,
                        onTap: () {
                          if (activeSoundPath == sound.path) { widget.onClearActiveSound(); }
                          else { widget.onSetActiveSound(sound); }
                          setState(() {});
                        },
                        onDelete: () => _handleDeleteSound(sound),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactAddSoundButton extends StatelessWidget {
  const CompactAddSoundButton({super.key, required this.onTap});
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(color: colors.accentSurface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: colors.onAccent, size: 28),
              const SizedBox(width: 10),
              Text('Add Sound', style: TextStyle(color: colors.onAccent, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class AddSoundCard extends StatelessWidget {
  const AddSoundCard({super.key, required this.onTap});
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 210,
          decoration: BoxDecoration(
            color: colors.surfaceDim, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border, width: 1.2),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 60, color: colors.accent),
                const SizedBox(height: 18),
                Text('Add Your First Sound', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Tap to browse audio files', style: TextStyle(color: colors.textMuted, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImportedSoundTile extends StatelessWidget {
  const ImportedSoundTile({super.key, required this.sound, required this.isActive, required this.onTap, required this.onDelete});
  final SoundEntry sound;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 MB';
    final megabytes = bytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('sound-tile-${sound.name}'), onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: isActive ? colors.accentSurface : colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.music_note_outlined, color: isActive ? colors.onAccent : colors.accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sound.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isActive ? colors.onAccent : colors.textPrimary, fontSize: 16, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
                    if (isActive) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: colors.accent.withAlpha(140), borderRadius: BorderRadius.circular(6)),
                        child: Text('Active', style: TextStyle(color: colors.onAccent, fontSize: 12, fontWeight: FontWeight.w500, height: 1)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(_formatSize(sound.sizeInBytes), style: TextStyle(color: isActive ? colors.onAccent.withAlpha(140) : colors.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onDelete,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero,
                icon: Icon(Icons.delete_outline, color: isActive ? colors.onAccent : colors.danger, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
