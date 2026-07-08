import { useState } from 'react'
import { Pencil } from 'lucide-react'
import { Modal } from './Modal'
import { Button } from './Button'
import { Select } from './Select'
import { api } from '../api/client'
import { ALL_KEYS, type Song } from '../types'
import { semitonesBetween, transposeChord, prefersFlats } from '../lib/transposer'

/** Transpose every chord in `song` into `targetKey` and update its stored key. */
export function transposeSong(song: Song, targetKey: string): Song {
  const semitones = semitonesBetween(song.songKey, targetKey)
  const flats = prefersFlats(targetKey)
  return {
    ...song,
    songKey: targetKey,
    lines: song.lines.map((line) => ({
      lyrics: line.lyrics,
      chords: line.chords.map((c) => transposeChord(c, semitones, flats)),
    })),
  }
}

/** Pick a target key, transpose all chords, and save permanently. */
export function ChangeKeyPanel({ song, onBack, onDone }: { song: Song; onBack: () => void; onDone: () => void }) {
  const [selectedKey, setSelectedKey] = useState(song.songKey)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const semitones = semitonesBetween(song.songKey, selectedKey)

  async function save() {
    if (selectedKey === song.songKey) return
    setSaving(true)
    setError(null)
    try {
      await api.songs.update(song.id, transposeSong(song, selectedKey))
      onDone()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to change key. Is the server running?')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal open onClose={onBack} title="Change Key" maxWidth="max-w-sm">
      <div className="space-y-4">
        <p className="text-sm text-text-secondary">Current key: {song.songKey}</p>
        <div>
          <label className="block text-xs font-semibold text-text-secondary mb-2 uppercase tracking-wide">New key</label>
          <Select
            value={selectedKey}
            onChange={setSelectedKey}
            options={ALL_KEYS.map((k) => ({ value: k, label: `Key of ${k}` }))}
          />
        </div>
        <p className="text-xs text-text-muted">
          {semitones === 0
            ? 'No change'
            : `${semitones > 0 ? '+' : ''}${semitones} semitone${Math.abs(semitones) === 1 ? '' : 's'}`}
        </p>
        {error && <p className="text-xs text-danger">{error}</p>}
        <div className="flex gap-3 pt-2">
          <Button variant="secondary" className="flex-1" onClick={onBack}>Back</Button>
          <Button className="flex-1" disabled={selectedKey === song.songKey || saving} onClick={save}>Save</Button>
        </div>
      </div>
    </Modal>
  )
}

/** Read-only chord chart. `onEdit` adds an Edit button when provided. */
export function SongOverview({ song, onBack, onEdit }: { song: Song; onBack: () => void; onEdit?: () => void }) {
  return (
    <Modal open onClose={onBack} title={song.title} maxWidth="max-w-2xl">
      <p className="text-center text-sm text-text-secondary bg-surface-dim rounded-lg py-2 mb-4 -mt-2">Key of {song.songKey}</p>
      <div className="space-y-3 mb-6">
        {song.lines.map((line, i) => {
          const isSection = line.lyrics.trim().startsWith('[') && line.lyrics.trim().endsWith(']')
          const hasChords = line.chords.some((c) => c)
          if (!line.lyrics.trim() && !hasChords) return <div key={i} className="h-3" />
          return (
            <div key={i}>
              {!isSection && hasChords && (
                // Mirrors the editor's slot layout: empty slots stay as invisible
                // spacers so each chord keeps the x-position it was placed at.
                <div className="flex flex-wrap gap-px mb-1">
                  {line.chords.map((c, j) =>
                    c ? (
                      <span
                        key={j}
                        className="min-w-[20px] h-6 px-1 rounded text-xs font-bold bg-accent-surface/30 text-accent inline-flex items-center justify-center"
                      >
                        {c}
                      </span>
                    ) : (
                      <span key={j} className="min-w-[20px] h-6 px-1 text-xs font-bold invisible">+</span>
                    )
                  )}
                </div>
              )}
              {line.lyrics.trim() && (
                <p className={isSection ? 'font-bold text-accent text-sm' : 'text-text-primary text-sm'}>{line.lyrics}</p>
              )}
            </div>
          )
        })}
      </div>
      <div className="flex gap-3">
        <Button variant="secondary" className="flex-1" onClick={onBack}>Back</Button>
        {onEdit && <Button className="flex-1" icon={<Pencil size={16} />} onClick={onEdit}>Edit</Button>}
      </div>
    </Modal>
  )
}
