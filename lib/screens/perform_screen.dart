import 'package:flutter/material.dart';
import '../models/song.dart';
import '../theme/app_colors.dart';

class PerformScreen extends StatefulWidget {
  const PerformScreen({
    super.key,
    required this.songs,
    this.initialIndex = 0,
  });

  final List<SongData> songs;
  final int initialIndex;

  @override
  State<PerformScreen> createState() => _PerformScreenState();
}

class _PerformScreenState extends State<PerformScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.songs.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == widget.songs.length - 1;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Exit performance',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.songs[_currentIndex].title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_currentIndex + 1} of ${widget.songs.length}',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Placeholder to balance the close button
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Song dots indicator ──
            if (widget.songs.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.songs.length, (i) {
                    final isActive = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? colors.accent : colors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

            // ── Key badge ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: colors.surfaceDim,
              child: Text(
                'Key of ${widget.songs[_currentIndex].songKey}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // ── Paged song content ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.songs.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, pageIndex) {
                  final song = widget.songs[pageIndex];
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    itemCount: song.lines.length,
                    itemBuilder: (context, lineIndex) {
                      final line = song.lines[lineIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chords row
                            if (line.chords.any((c) => c.isNotEmpty))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: line.chords.map((chord) {
                                    if (chord.isEmpty) {
                                      return const SizedBox(width: 12);
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colors.accent.withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: colors.accent.withAlpha(80),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        chord,
                                        style: TextStyle(
                                          color: colors.accent,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            // Lyrics
                            Text(
                              line.lyrics.isEmpty ? ' ' : line.lyrics,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 20,
                                height: 1.6,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Navigation bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  // Previous button
                  _NavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: isFirst
                        ? 'Start'
                        : widget.songs[_currentIndex - 1].title,
                    onPressed: isFirst ? null : () => _goTo(_currentIndex - 1),
                    colors: colors,
                    align: CrossAxisAlignment.start,
                  ),

                  // Song title in middle
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          color: colors.accent.withAlpha(180),
                          size: 18,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.songs[_currentIndex].title,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Next button
                  _NavButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    label: isLast
                        ? 'End'
                        : widget.songs[_currentIndex + 1].title,
                    onPressed: isLast ? null : () => _goTo(_currentIndex + 1),
                    colors: colors,
                    align: CrossAxisAlignment.end,
                    iconLeading: false,
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.colors,
    required this.align,
    this.iconLeading = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final AppColors colors;
  final CrossAxisAlignment align;
  final bool iconLeading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final iconColor = isDisabled ? colors.border : colors.accent;
    final labelColor = isDisabled ? colors.border : colors.textMuted;

    return SizedBox(
      width: 110,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: align,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: iconLeading
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  children: [
                    if (iconLeading)
                      Icon(icon, color: iconColor, size: 22),
                    if (!iconLeading)
                      Text(
                        isDisabled ? '' : 'Next',
                        style: TextStyle(
                          color: isDisabled ? colors.border : colors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (iconLeading) const SizedBox(width: 4),
                    if (!iconLeading) const SizedBox(width: 4),
                    if (!iconLeading)
                      Icon(icon, color: iconColor, size: 22),
                    if (iconLeading)
                      Text(
                        isDisabled ? '' : 'Prev',
                        style: TextStyle(
                          color: isDisabled ? colors.border : colors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: iconLeading ? TextAlign.left : TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
