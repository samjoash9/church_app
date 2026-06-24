/**
 * Chord transposition engine — JS port of the Flutter Transposer service.
 */

const SHARP_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const FLAT_NAMES  = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

const PITCH_CLASS = {
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

const FLAT_KEYS = new Set(['F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb']);

const ROOT_PATTERN = /^([A-G][#b]?)/;

function normalizeNote(raw) {
  const t = raw.trim();
  if (!t) return t;
  return t[0].toUpperCase() + t.substring(1);
}

export function semitonesBetween(fromKey, toKey) {
  const from = PITCH_CLASS[normalizeNote(fromKey)];
  const to = PITCH_CLASS[normalizeNote(toKey)];
  if (from === undefined || to === undefined) return 0;
  return ((to - from) % 12 + 12) % 12;
}

export function prefersFlats(key) {
  return FLAT_KEYS.has(normalizeNote(key));
}

export function transposeChord(chord, semitones, preferFlatsFlag = false) {
  if (semitones === 0 || !chord.trim()) return chord;

  const slash = chord.indexOf('/');
  if (slash !== -1) {
    const root = chord.substring(0, slash);
    const bass = chord.substring(slash + 1);
    return `${transposeChord(root, semitones, preferFlatsFlag)}/${transposeChord(bass, semitones, preferFlatsFlag)}`;
  }

  const match = chord.match(ROOT_PATTERN);
  if (!match) return chord;

  const note = match[1];
  const suffix = chord.substring(match[0].length);
  const pc = PITCH_CLASS[note];
  if (pc === undefined) return chord;

  const shifted = ((pc + semitones) % 12 + 12) % 12;
  const names = preferFlatsFlag ? FLAT_NAMES : SHARP_NAMES;
  return `${names[shifted]}${suffix}`;
}

export const KEY_CHORDS = {
  'A': ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim', 'G'],
  'B': ['B', 'C#m', 'D#m', 'E', 'F#', 'G#m', 'A#dim', 'A'],
  'C': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim', 'A#'],
  'D': ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim', 'C'],
  'E': ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim', 'D'],
  'F': ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim', 'E'],
  'G': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim', 'F'],
};

export const ALL_KEYS = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
