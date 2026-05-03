import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import 'theme_screen.dart';

/// The Settings screen with navigation tiles for Audio Settings, Theme, and About.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      drawer: AppDrawer(
        selectedItem: 'Settings',
        onSelectItem: (_) {},
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
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
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Settings items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  _SettingsTile(
                    title: 'Audio Settings',
                    subtitle: 'Configure audio playback settings',
                    colors: colors,
                    onTap: () {
                      // TODO: Navigate to Audio Settings sub-page
                    },
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    title: 'Theme',
                    subtitle: 'Customize app appearance',
                    colors: colors,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ThemeScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                    colors: colors,
                    onTap: () {
                      // TODO: Navigate to About sub-page
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: colors.border, width: 3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
