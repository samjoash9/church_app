import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../widgets/section_header.dart';

/// Screen that lets the user toggle between Daylight and Nightmode.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeNotifier = ThemeProvider.of(context);
    final isDark = themeNotifier.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SectionHeader(
              title: 'Theme',
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // ── Dynamic label ──
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            isDark ? 'Nightmode' : 'Daylight',
                            key: ValueKey(isDark),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Segmented toggle ──
                    _SegmentedToggle(
                      isDark: isDark,
                      colors: colors,
                      onChanged: (dark) => themeNotifier.setDark(dark),
                    ),
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

/// A two-option segmented toggle styled to match the app's design.
/// The active segment gets an accent-colored pill; the inactive one
/// is plain text on a transparent background.
class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.isDark,
    required this.colors,
    required this.onChanged,
  });

  final bool isDark;
  final AppColors colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentButton(
            label: '☀️',
            isActive: !isDark,
            colors: colors,
            onTap: () => onChanged(false),
          ),
          _SegmentButton(
            label: '🌙',
            isActive: isDark,
            colors: colors,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 56,
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? colors.accentSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: isActive ? colors.onAccent : colors.textMuted,
          ),
        ),
      ),
    );
  }
}
