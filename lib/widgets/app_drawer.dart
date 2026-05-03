import 'package:flutter/material.dart';

import '../models/sound_entry.dart';
import '../screens/chords_screen.dart';
import '../screens/lineup_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/simple_page.dart';
import '../screens/sound_library_screen.dart';
import '../theme/app_colors.dart';

import '../services/sound_library_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.selectedItem,
    required this.onSelectItem,
  });

  final String selectedItem;
  final void Function(String) onSelectItem;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Drawer(
      backgroundColor: colors.drawerBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 12, 20),
              child: Row(
                children: [
                  Icon(Icons.music_note, color: colors.accent, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Menu',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.textPrimary, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _buildItem(context, colors, 'drawer-pads', Icons.sensors, 'Pads', () {
              if (selectedItem == 'Pads') {
                Navigator.of(context).pop();
                return;
              }
              onSelectItem('Pads');
              Navigator.of(context).popUntil((route) => route.isFirst);
            }),
            _buildItem(context, colors, 'drawer-sound-library', Icons.library_music_outlined, 'Sound Library', () {
              if (selectedItem == 'Sound Library') {
                Navigator.of(context).pop();
                return;
              }
              onSelectItem('Sound Library');
              Navigator.of(context).pop();
              
              final service = SoundLibraryService();
              final screen = SoundLibraryScreen(
                soundsFor: service.soundsFor, 
                activeSoundPathFor: service.activeSoundPathFor,
                onAddSound: service.addSoundToFolder, 
                onDeleteSound: service.removeSoundFromFolder,
                onSetActiveSound: service.setActiveSoundForFolder, 
                onClearActiveSound: service.clearActiveSoundForFolder,
              );

              _jumpTo(context, screen);
            }),
            _buildItem(context, colors, 'drawer-chords', Icons.music_note_outlined, 'Chords', () {
              if (selectedItem == 'Chords') {
                Navigator.of(context).pop();
                return;
              }
              onSelectItem('Chords');
              Navigator.of(context).pop();
              _jumpTo(context, const ChordsScreen());
            }),
            _buildItem(context, colors, 'drawer-lineup', Icons.playlist_play_rounded, 'Line up', () {
              if (selectedItem == 'Line up') {
                Navigator.of(context).pop();
                return;
              }
              onSelectItem('Line up');
              Navigator.of(context).pop();
              _jumpTo(context, const LineupScreen());
            }),
            _buildItem(context, colors, 'drawer-ppt', Icons.description_outlined, 'PPT', () {
              if (selectedItem == 'PPT') {
                Navigator.of(context).pop();
                return;
              }
              onSelectItem('PPT');
              Navigator.of(context).pop();
              _jumpTo(context, const SimplePage(title: 'PPT', icon: Icons.description_outlined, message: 'Presentations will appear here.'));
            }),
            _buildItem(context, colors, 'drawer-settings', Icons.settings_outlined, 'Settings', () {
              if (selectedItem == 'Settings') {
                Navigator.of(context).pop();
                return;
              }
              onSelectItem('Settings');
              Navigator.of(context).pop();
              _jumpTo(context, const SettingsScreen());
            }),
          ],
        ),
      ),
    );
  }

  void _jumpTo(BuildContext context, Widget screen) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildItem(BuildContext context, AppColors colors, String key, IconData icon, String title, VoidCallback onTap) {
    final isSelected = selectedItem == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? colors.drawerSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key(key),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? colors.accent : colors.textMuted, size: 22),
                const SizedBox(width: 14),
                Text(title, style: TextStyle(
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                  fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
