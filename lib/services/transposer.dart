/// Chord transposition engine.
///
/// Shifts chord symbols up or down by a number of semitones while preserving
/// suffixes (m, maj7, sus4, add9, …) and slash-bass notes (e.g. `C/E`).
/// Plain lyrics and section headers contain no root note and pass through
/// untouched, so this can be run over any chord slot safely.
class Transposer {
  Transposer._();

  /// The twelve pitch classes, indexed 0–11 starting at C.
  ///
  /// Two spellings are kept so a transposed chart can prefer flats or sharps
  /// depending on the destination key (e.g. the key of F wants Bb, not A#).
  static const _sharpNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];
  static const _flatNames = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
  ];

  /// Maps every accepted note spelling to its pitch class (0–11).
  static const _pitchClass = <String, int>{
    'C': 0, 'B#': 0,
    'C#': 1, 'Db': 1,
    'D': 2,
    'D#': 3, 'Eb': 3,
    'E': 4, 'Fb': 4,
    'F': 5, 'E#': 5,
    'F#': 6, 'Gb': 6,
    'G': 7,
    'G#': 8, 'Ab': 8,
    'A': 9,
    'A#': 10, 'Bb': 10,
    'B': 11, 'Cb': 11,
  };

  /// Keys conventionally spelled with flats. Anything else prefers sharps.
  static const _flatKeys = {'F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb'};

  /// Number of semitones to move from [fromKey] to [toKey] (range -11..11).
  /// Returns 0 if either key is unrecognised.
  static int semitonesBetween(String fromKey, String toKey) {
    final from = _pitchClass[_normalizeNote(fromKey)];
    final to = _pitchClass[_normalizeNote(toKey)];
    if (from == null || to == null) return 0;
    return ((to - from) % 12 + 12) % 12;
  }

  /// Transposes a single chord symbol by [semitones]. Empty or non-chord
  /// input is returned unchanged. [preferFlats] selects the accidental
  /// spelling for the output (driven by the destination key).
  static String transposeChord(String chord, int semitones,
      {bool preferFlats = false}) {
    if (semitones == 0 || chord.trim().isEmpty) return chord;

    // Slash chord: transpose root and bass independently.
    final slash = chord.indexOf('/');
    if (slash != -1) {
      final root = chord.substring(0, slash);
      final bass = chord.substring(slash + 1);
      return '${transposeChord(root, semitones, preferFlats: preferFlats)}'
          '/${transposeChord(bass, semitones, preferFlats: preferFlats)}';
    }

    final match = _rootPattern.firstMatch(chord);
    if (match == null) return chord; // not a chord — leave it be.

    final note = match.group(1)!;
    final suffix = chord.substring(match.end);
    final pc = _pitchClass[note];
    if (pc == null) return chord;

    final shifted = ((pc + semitones) % 12 + 12) % 12;
    final names = preferFlats ? _flatNames : _sharpNames;
    return '${names[shifted]}$suffix';
  }

  /// Whether a transposed chart targeting [key] should spell with flats.
  static bool prefersFlats(String key) =>
      _flatKeys.contains(_normalizeNote(key));

  /// Matches a leading root note: a letter A–G plus an optional accidental.
  static final _rootPattern = RegExp(r'^([A-G][#b]?)');

  /// Trims whitespace and upper-cases the note letter (keeps the accidental).
  static String _normalizeNote(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }
}
