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
  String _currentFilter = 'Full';

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
    setState(() {
      _currentIndex = index;
      _currentFilter = 'Full';
    });
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
                onPageChanged: (i) => setState(() {
                  _currentIndex = i;
                  _currentFilter = 'Full';
                }),
                itemBuilder: (context, pageIndex) {
                  final song = widget.songs[pageIndex];

                  List<SongLineData> displayedLines = [];
                  if (_currentFilter == 'Full') {
                    displayedLines = song.lines;
                  } else {
                    bool inTargetSection = false;
                    for (final line in song.lines) {
                      final cleanLyrics = line.lyrics.trim();
                      if (cleanLyrics.startsWith('[') && cleanLyrics.endsWith(']')) {
                        final sectionName = cleanLyrics.substring(1, cleanLyrics.length - 1).trim();
                        if (sectionName.toLowerCase() == _currentFilter.toLowerCase()) {
                          inTargetSection = true;
                          displayedLines.add(line);
                        } else {
                          inTargetSection = false;
                        }
                      } else if (inTargetSection) {
                        displayedLines.add(line);
                      }
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    itemCount: displayedLines.length,
                    itemBuilder: (context, lineIndex) {
                      final line = displayedLines[lineIndex];

                      if (line.lyrics.trim().isEmpty && line.chords.every((c) => c.isEmpty)) {
                        return const SizedBox(height: 16);
                      }

                      final isSectionHeader = line.lyrics.trim().startsWith('[') && line.lyrics.trim().endsWith(']');

                      return Padding(
                        padding: EdgeInsets.only(
                          top: isSectionHeader && lineIndex > 0 ? 16.0 : 0.0,
                          bottom: isSectionHeader ? 12.0 : 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chords row
                            if (!isSectionHeader && line.chords.any((c) => c.isNotEmpty))
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
                            if (line.lyrics.trim().isNotEmpty)
                              Text(
                                line.lyrics,
                                style: TextStyle(
                                  color: isSectionHeader ? colors.accent : colors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: isSectionHeader ? FontWeight.bold : FontWeight.normal,
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

            // ── Section Filter Bar ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Builder(
                builder: (context) {
                  final currentSong = widget.songs[_currentIndex];
                  final availableSections = currentSong.lines
                      .where((l) => l.lyrics.trim().startsWith('[') && l.lyrics.trim().endsWith(']'))
                      .map((l) => l.lyrics.trim().replaceAll('[', '').replaceAll(']', '').trim().toLowerCase())
                      .toSet();

                  final allFilters = ['Full', 'Verse', 'Second Verse', 'Pre-Chorus', 'Chorus', 'Bridge'];
                  final activeFilters = allFilters.where((f) => f == 'Full' || availableSections.contains(f.toLowerCase())).toList();

                  return Row(
                    children: activeFilters.map((filter) {
                      final isSelected = _currentFilter == filter;
                      
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentFilter = filter;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? colors.accent : colors.surfaceDim,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? colors.accent : colors.border,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSelected ? colors.onAccent : colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
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
