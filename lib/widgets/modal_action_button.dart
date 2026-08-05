import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-width modal/sheet action button used across the song action modals
/// (chords, lineup, song editor). [compact] produces the smaller chords-screen
/// sizing; [isDanger] tints the label/icon with the danger color.
class ModalActionButton extends StatelessWidget {
  const ModalActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.colors,
    required this.isPrimary,
    required this.onTap,
    this.isDanger = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final AppColors colors;
  final bool isPrimary;
  final bool isDanger;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? colors.accentSurface : colors.surfaceDim;
    final fg = isDanger
        ? colors.danger
        : (isPrimary ? colors.onAccent : colors.textPrimary);
    final borderColor = isPrimary ? colors.accentSurface : colors.border;

    final verticalPadding = compact ? 9.0 : 14.0;
    final iconSize = compact ? 17.0 : 20.0;
    final gap = compact ? 8.0 : 10.0;
    final fontSize = compact ? 13.0 : 15.0;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: iconSize),
                SizedBox(width: gap),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
