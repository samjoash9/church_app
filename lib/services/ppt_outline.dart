import '../models/song.dart';

/// A single lyrics slide's content: a section title and up to 4 lyric lines.
class PptLyricSlide {
  const PptLyricSlide({required this.title, required this.lyrics});

  final String title;
  final List<String> lyrics;
}

/// The slides one song contributes to a presentation: a title slide plus the
/// lyric slides built by [buildSongSlides].
class PptSongOutline {
  const PptSongOutline({required this.song, required this.lyricSlides});

  final SongData song;
  final List<PptLyricSlide> lyricSlides;

  /// Title slide (1) + every lyric slide.
  int get slideCount => 1 + lyricSlides.length;
}

/// The full slide breakdown of a presentation, in the exact order the export
/// produces them.
class PptOutline {
  const PptOutline({
    required this.introSections,
    required this.songs,
    required this.outroSections,
  });

  final List<String> introSections;
  final List<PptSongOutline> songs;
  final List<String> outroSections;

  /// Title slide (1) + intro sections + every song's slides + outro sections.
  int get totalSlides =>
      1 +
      introSections.length +
      songs.fold<int>(0, (sum, s) => sum + s.slideCount) +
      outroSections.length;
}

/// Fixed section slides that wrap every presentation.
const List<String> kPptIntroSections = [
  'SUNDAY SCHOOL',
  'ANNOUNCEMENT',
  'PRAISE & WORSHIP',
];
const List<String> kPptOutroSections = [
  'WORD',
  'TITHES & OFFERING',
  'ANNOUNCEMENT',
];

/// Splits a song's lines into lyric slides exactly as the PPTX export does:
/// a `[Section]` line starts a new slide group, and lyric lines pack 4-per-slide
/// with a `(cont.)` marker once a group overflows.
///
/// This is the single source of truth shared by the exporter and the in-app
/// overview so what the user previews matches what they export.
List<PptLyricSlide> buildSongSlides(SongData song) {
  final slides = <PptLyricSlide>[];
  String currentTitle = '[${song.title}]';
  final currentLyrics = <String>[];

  void flush() {
    if (currentLyrics.isEmpty) return;
    slides.add(PptLyricSlide(
      title: currentTitle,
      lyrics: List<String>.from(currentLyrics),
    ));
    currentLyrics.clear();
  }

  for (final line in song.lines) {
    final text = line.lyrics.trim();
    if (text.isEmpty) continue;

    if (text.startsWith('[') && text.endsWith(']')) {
      flush();
      final sectionName = text.substring(1, text.length - 1);
      currentTitle = '[${song.title} - $sectionName]';
    } else {
      currentLyrics.add(text);
      if (currentLyrics.length >= 4) {
        flush();
        if (!currentTitle.endsWith('(cont.)]')) {
          currentTitle = currentTitle.replaceAll(']', ' (cont.)]');
        }
      }
    }
  }
  flush();

  return slides;
}

/// Builds the full ordered outline for a presentation from its songs.
PptOutline buildPptOutline(List<SongData> songs) {
  return PptOutline(
    introSections: kPptIntroSections,
    songs: [
      for (final song in songs)
        PptSongOutline(song: song, lyricSlides: buildSongSlides(song)),
    ],
    outroSections: kPptOutroSections,
  );
}
