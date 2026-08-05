import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular badge showing a song key, tinted with the accent color.
/// Used as list-tile leading / card avatar across chords, lineup and PPT.
class KeyAvatar extends StatelessWidget {
  const KeyAvatar({
    super.key,
    required this.songKey,
    required this.colors,
    this.size = 42,
    this.fontSize = 14,
  });

  final String songKey;
  final AppColors colors;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.accentSurface.withAlpha(51),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        songKey,
        style: TextStyle(
          color: colors.accent,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
