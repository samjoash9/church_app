import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Drag handle bar shown at the top of modal bottom sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key, required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
