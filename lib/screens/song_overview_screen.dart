import 'package:flutter/material.dart';
import '../models/song.dart';
import '../theme/app_colors.dart';
import '../widgets/section_header.dart';
import 'song_editor_screen.dart';

class SongOverviewScreen extends StatelessWidget {
  const SongOverviewScreen({
    super.key,
    required this.song,
  });

  final SongData song;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            SectionHeader(
              title: song.title,
              onBack: () => Navigator.of(context).pop(),
            ),
            
            // ── Info Bar ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: colors.surfaceDim,
              child: Text(
                'Key of ${song.songKey}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            // ── Content Area ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: song.lines.length,
                itemBuilder: (context, index) {
                  final line = song.lines[index];
                  
                  if (line.lyrics.trim().isEmpty && line.chords.every((c) => c.isEmpty)) {
                    return const SizedBox(height: 16);
                  }

                  final isSectionHeader = line.lyrics.trim().startsWith('[') && line.lyrics.trim().endsWith(']');

                  return Padding(
                    padding: EdgeInsets.only(
                      top: isSectionHeader && index > 0 ? 16.0 : 0.0,
                      bottom: isSectionHeader ? 12.0 : 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chords
                        if (!isSectionHeader && line.chords.any((c) => c.isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Wrap(
                              spacing: 4,
                              children: line.chords.map((chord) {
                                if (chord.isEmpty) return const SizedBox(width: 20);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.accentSurface.withAlpha(51),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    chord,
                                    style: TextStyle(
                                      color: colors.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
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
                              fontSize: 22,
                              fontWeight: isSectionHeader ? FontWeight.bold : FontWeight.normal,
                              height: 1.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Bottom Buttons ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.surfaceDim,
                        foregroundColor: colors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colors.border),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => SongEditorScreen(
                              songId: song.id,
                              title: song.title,
                              songKey: song.songKey,
                              initialLines: song.lines,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
