import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class KeyCard extends StatelessWidget {
  const KeyCard({
    super.key,
    required this.label,
    required this.isPlaying,
    required this.onTap,
  });

  final String label;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AnimatedScale(
      scale: isPlaying ? 1.02 : 1,
      duration: const Duration(milliseconds: 220),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isPlaying ? colors.playingSurface : colors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: colors.accent.withAlpha(85),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
          border: Border.all(
            color: isPlaying ? colors.accent : Colors.transparent,
            width: 1.3,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Stack(
              children: [
                Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: isPlaying ? 30 : 28,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(label),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: AnimatedOpacity(
                    opacity: isPlaying ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: PlayingIndicator(colors: colors),
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

class PlayingIndicator extends StatefulWidget {
  const PlayingIndicator({super.key, required this.colors});

  final AppColors colors;

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.colors.accent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.graphic_eq, size: 18, color: accent),
        const SizedBox(width: 6),
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final glow = 0.5 + (_controller.value * 0.5);
              return Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: glow),
                      accent.withAlpha(180),
                      accent.withValues(alpha: glow),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
