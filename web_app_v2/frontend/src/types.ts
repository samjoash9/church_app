export interface SongLine {
  lyrics: string
  chords: string[]
}

export interface Song {
  id: string
  title: string
  songKey: string
  lines: SongLine[]
  language: string
}

export interface LineupItem {
  id: number
  order_index: number
  song_id: string
}

export interface Ppt {
  id: string
  title: string
  song_ids: string[]
}

export interface SoundEntry {
  id: number
  mode: 'Major' | 'Minor'
  key: string
  name: string
  path: string
  size_in_bytes: number
  is_asset: boolean
  is_active: boolean
}

export const LANGUAGES = ['bisaya', 'tagalog', 'english'] as const
export type Language = (typeof LANGUAGES)[number]

export const LANGUAGE_LABELS: Record<string, string> = {
  bisaya: 'Bisaya',
  tagalog: 'Tagalog',
  english: 'English',
}

export const ALL_KEYS = ['A', 'B', 'C', 'D', 'E', 'F', 'G'] as const
export const MAJOR_KEYS = ['E', 'F', 'G', 'A', 'B', 'C', 'D']
export const MINOR_KEYS = ['C#m', 'D#m', 'Em', 'F#m', 'G#m', 'Am', 'Bm']
