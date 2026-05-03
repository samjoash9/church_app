import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/section_header.dart';
import '../widgets/app_drawer.dart';

/// A placeholder page used for sections that are not yet implemented
/// (Chords, PPT, etc.).
class SimplePage extends StatelessWidget {
  const SimplePage({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      drawer: AppDrawer(
        selectedItem: title,
        onSelectItem: (_) {},
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (context) => SectionHeader(
                title: title,
                onMenuTap: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 52, color: colors.accent),
                      const SizedBox(height: 16),
                      Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text(message, textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 16, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
