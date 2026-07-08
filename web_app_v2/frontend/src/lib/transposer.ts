/**
 * Chord transposition engine.
 *
 * Shifts chord symbols up or down by a number of semitones while preserving
 * suffixes (m, maj7, sus4, add9, …) and slash-bass notes (e.g. `C/E`).
 * Plain lyrics and section headers contain no root note and pass through
 * untouched, so this can be run over any chord slot safely.
 *
 * Ported from the Flutter app's lib/services/transposer.dart.
 */

/** The twelve pitch classes, indexed 0–11 starting at C. */
const SHARP_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
const FLAT_NAMES = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B']

/** Maps every accepted note spelling to its pitch class (0–11). */
const PITCH_CLASS: Record<string, number> = {
  C: 0, 'B#': 0,
  'C#': 1, Db: 1,
  D: 2,
  'D#': 3, Eb: 3,
  E: 4, Fb: 4,
  F: 5, 'E#': 5,
  'F#': 6, Gb: 6,
  G: 7,
  'G#': 8, Ab: 8,
  A: 9,
  'A#': 10, Bb: 10,
  B: 11, Cb: 11,
}

/** Keys conventionally spelled with flats. Anything else prefers sharps. */
const FLAT_KEYS = new Set(['F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb'])

/** Matches a leading root note: a letter A–G plus an optional accidental. */
const ROOT_PATTERN = /^([A-G][#b]?)/

/** Trims whitespace and upper-cases the note letter (keeps the accidental). */
function normalizeNote(raw: string): string {
  const t = raw.trim()
  if (!t) return t
  return t[0].toUpperCase() + t.slice(1)
}

/**
 * Number of semitones to move from `fromKey` to `toKey` (range 0..11).
 * Returns 0 if either key is unrecognised.
 */
export function semitonesBetween(fromKey: string, toKey: string): number {
  const from = PITCH_CLASS[normalizeNote(fromKey)]
  const to = PITCH_CLASS[normalizeNote(toKey)]
  if (from == null || to == null) return 0
  return (((to - from) % 12) + 12) % 12
}

/**
 * Transposes a single chord symbol by `semitones`. Empty or non-chord
 * input is returned unchanged. `preferFlats` selects the accidental
 * spelling for the output (driven by the destination key).
 */
export function transposeChord(chord: string, semitones: number, preferFlats = false): string {
  if (semitones === 0 || !chord.trim()) return chord

  // Slash chord: transpose root and bass independently.
  const slash = chord.indexOf('/')
  if (slash !== -1) {
    const root = chord.slice(0, slash)
    const bass = chord.slice(slash + 1)
    return `${transposeChord(root, semitones, preferFlats)}/${transposeChord(bass, semitones, preferFlats)}`
  }

  const match = ROOT_PATTERN.exec(chord)
  if (!match) return chord // not a chord — leave it be.

  const note = match[1]
  const suffix = chord.slice(match[0].length)
  const pc = PITCH_CLASS[note]
  if (pc == null) return chord

  const shifted = (((pc + semitones) % 12) + 12) % 12
  const names = preferFlats ? FLAT_NAMES : SHARP_NAMES
  return `${names[shifted]}${suffix}`
}

/** Whether a transposed chart targeting `key` should spell with flats. */
export function prefersFlats(key: string): boolean {
  return FLAT_KEYS.has(normalizeNote(key))
}
