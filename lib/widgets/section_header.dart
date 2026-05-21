import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onMenuTap,
    this.onBack,
    this.action,
  }) : assert(onMenuTap != null || onBack != null);

  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isMenu = onMenuTap != null;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isMenu ? onMenuTap : onBack,
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceDim,
              minimumSize: const Size(40, 40),
            ),
            icon: Icon(
              isMenu ? Icons.menu : Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary,
              size: isMenu ? 24 : 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
