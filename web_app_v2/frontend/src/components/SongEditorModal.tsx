import { useEffect, useState } from 'react'
import { Save, FileText as FileIcon } from 'lucide-react'
import { Modal } from './Modal'
import { Button } from './Button'
import { Select } from './Select'
import { api, downloadBlob } from '../api/client'
import type { Song, SongLine } from '../types'

const KEY_CHORDS: Record<string, string[]> = {
  A: ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim', 'G'],
  B: ['B', 'C#m', 'D#m', 'E', 'F#', 'G#m', 'A#dim', 'A'],
  C: ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim', 'A#'],
  D: ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim', 'C'],
  E: ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim', 'D'],
  F: ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim', 'E'],
  G: ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim', 'F'],
}

const SECTION_NAMES = ['Verse', 'Second Verse', 'Third Verse', 'Pre-Chorus', 'Chorus', 'Second Chorus', 'Bridge']

interface Props {
  open: boolean
  song: Song | null
  pendingMeta: { title: string; songKey: string; language: string } | null
  onClose: () => void
  onSaved: () => void
}

type Mode = 'lyrics' | 'chords' | 'view'

export function SongEditorModal({ open, song, pendingMeta, onClose, onSaved }: Props) {
  const title = song?.title ?? pendingMeta?.title ?? 'Untitled'
  const language = song?.language ?? pendingMeta?.language ?? 'english'
  const [songKey, setSongKey] = useState(song?.songKey ?? pendingMeta?.songKey ?? 'C')
  const [mode, setMode] = useState<Mode>('lyrics')
  const [lines, setLines] = useState<SongLine[]>(song?.lines ?? [])
  const [sections, setSections] = useState<Record<string, string>>(() => sectionsFromLines(song?.lines ?? []))

  useEffect(() => {
    if (open) {
      setSongKey(song?.songKey ?? pendingMeta?.songKey ?? 'C')
      setLines(song?.lines ?? [])
      setSections(sectionsFromLines(song?.lines ?? []))
      setMode('lyrics')
    }
  }, [open, song, pendingMeta])

  function switchMode(next: Mode) {
    if (next === mode) return
    if (mode === 'lyrics') {
      setLines(linesFromSections(sections, lines))
    } else if (next === 'lyrics') {
      setSections(sectionsFromLines(lines))
    }
    setMode(next)
  }

  function buildSongData(): Song {
    const finalLines = mode === 'lyrics' ? linesFromSections(sections, lines) : lines
    return {
      id: song?.id ?? Date.now().toString(),
      title,
      songKey,
      lines: finalLines,
      language,
    }
  }

  async function handleSave() {
    const data = buildSongData()
    if (song) await api.songs.update(song.id, data)
    else await api.songs.create(data)
    onSaved()
  }

  async function handleExportPdf() {
    const data = buildSongData()
    if (!song) await api.songs.create(data).catch(() => {})
    const blob = await api.exportPdf([data.id])
    downloadBlob(blob, `${data.title}.pdf`)
  }

  return (
    <Modal open={open} onClose={onClose} maxWidth="max-w-3xl">
      <div className="-m-6 flex flex-col h-[85vh]">
        <div className="flex items-center flex-wrap gap-2 px-4 py-3 border-b border-border shrink-0">
          <div className="flex bg-accent rounded-lg p-1 w-full sm:flex-1 sm:w-auto order-last sm:order-none max-w-full sm:max-w-xs">
            {(['chords', 'lyrics', 'view'] as Mode[]).map((m) => (
              <button
                key={m}
                onClick={() => switchMode(m)}
                className={`flex-1 py-1.5 rounded-md text-xs font-bold capitalize transition-colors ${
                  mode === m ? 'bg-surface text-accent' : 'text-on-accent'
                }`}
              >
                {m}
              </button>
            ))}
          </div>
          <Select
            variant="accent"
            className="w-20"
            value={songKey}
            onChange={setSongKey}
            options={Object.keys(KEY_CHORDS).map((k) => ({ value: k, label: k }))}
          />
          <Button variant="secondary" icon={<Save size={15} />} onClick={handleSave}>Save</Button>
          <Button variant="ghost" onClick={onClose}>Exit</Button>
        </div>
        <div className="text-center py-2 bg-surface-dim text-sm font-semibold text-text-secondary shrink-0">
          {title} • Key of {songKey}
        </div>
        <div className="flex-1 overflow-y-auto p-5">
          {mode === 'lyrics' && (
            <LyricsEditor sections={sections} setSections={setSections} />
          )}
          {mode === 'chords' && (
            <ChordsEditor lines={lines} setLines={setLines} songKey={songKey} />
          )}
          {mode === 'view' && (
            <ChordsEditor lines={lines} setLines={setLines} songKey={songKey} readOnly />
          )}
        </div>
        <div className="px-5 py-3 border-t border-border shrink-0">
          <Button variant="secondary" icon={<FileIcon size={15} />} onClick={handleExportPdf} className="w-full">
            Export as PDF
          </Button>
        </div>
      </div>
    </Modal>
  )
}

function sectionsFromLines(lines: SongLine[]): Record<string, string> {
  const result: Record<string, string> = {}
  for (const name of SECTION_NAMES) result[name] = ''
  let current = SECTION_NAMES[0]
  let buffer: string[] = []
  const flush = () => {
    if (buffer.length) {
      const text = buffer.join('\n').trim()
      result[current] = result[current] ? `${result[current]}\n\n${text}` : text
    }
    buffer = []
  }
  for (const line of lines) {
    const clean = line.lyrics.trim().replace(/[[\]]/g, '')
    const match = SECTION_NAMES.find((s) => s.toLowerCase() === clean.toLowerCase())
    if (match) {
      flush()
      current = match
    } else if (line.lyrics.trim() || buffer.length) {
      buffer.push(line.lyrics)
    }
  }
  flush()
  return result
}

function linesFromSections(sections: Record<string, string>, oldLines: SongLine[]): SongLine[] {
  const result: SongLine[] = []
  let oldIdx = 0
  const nextOldChords = (matchLyrics?: string) => {
    if (oldIdx < oldLines.length) {
      if (matchLyrics !== undefined) {
        const clean = oldLines[oldIdx].lyrics.replace(/[[\]]/g, '').trim().toLowerCase()
        if (clean !== matchLyrics.toLowerCase()) return undefined
      }
      return oldLines[oldIdx++].chords
    }
    return undefined
  }
  for (const name of SECTION_NAMES) {
    const text = (sections[name] || '').trim()
    if (!text) continue
    result.push({ lyrics: `[${name}]`, chords: nextOldChords(name) ?? [] })
    for (const lyric of text.split('\n')) {
      result.push({ lyrics: lyric, chords: nextOldChords() ?? [] })
    }
    result.push({ lyrics: '', chords: [] })
  }
  while (result.length && !result[result.length - 1].lyrics.trim()) result.pop()
  return result
}

function LyricsEditor({ sections, setSections }: { sections: Record<string, string>; setSections: (s: Record<string, string>) => void }) {
  const [openSection, setOpenSection] = useState(SECTION_NAMES[0])
  return (
    <div className="space-y-3">
      {SECTION_NAMES.map((name) => {
        const filled = !!sections[name]?.trim()
        const isOpen = openSection === name
        return (
          <div key={name} className="rounded-lg overflow-hidden">
            <button
              onClick={() => setOpenSection(isOpen ? '' : name)}
              className={`w-full flex items-center justify-between px-4 py-3 font-semibold text-sm transition-colors ${
                filled ? 'bg-accent-surface text-on-accent' : 'bg-surface-dim text-text-primary'
              }`}
            >
              {name}
              <span>{isOpen ? '▲' : '▼'}</span>
            </button>
            {isOpen && (
              <textarea
                value={sections[name] || ''}
                onChange={(e) => setSections({ ...sections, [name]: e.target.value })}
                placeholder="Paste or type lyrics here..."
                rows={4}
                className="w-full p-4 bg-surface text-text-primary text-sm focus:outline-none resize-y"
              />
            )}
          </div>
        )
      })}
    </div>
  )
}

function ChordsEditor({
  lines,
  setLines,
  songKey,
  readOnly,
}: {
  lines: SongLine[]
  setLines: (l: SongLine[]) => void
  songKey: string
  readOnly?: boolean
}) {
  const [pickerFor, setPickerFor] = useState<{ lineIdx: number; wordIdx: number } | null>(null)
  const chordChoices = KEY_CHORDS[songKey] ?? KEY_CHORDS.C

  function setChord(lineIdx: number, wordIdx: number, chord: string) {
    const next = lines.map((l) => ({ ...l, chords: [...l.chords] }))
    while (next[lineIdx].chords.length <= wordIdx) next[lineIdx].chords.push('')
    next[lineIdx].chords[wordIdx] = chord
    setLines(next)
  }

  if (lines.length === 0) {
    return <p className="text-center text-text-muted py-12 text-sm">Add lyrics first, then switch here to assign chords.</p>
  }

  return (
    <div className="space-y-3">
      {lines.map((line, lineIdx) => {
        const isSection = line.lyrics.trim().startsWith('[') && line.lyrics.trim().endsWith(']')
        if (!line.lyrics.trim() && line.chords.every((c) => !c)) return <div key={lineIdx} className="h-3" />
        const words = line.lyrics.split(' ')
        // Editable slots fill the row to the right edge: enough per line that the
        // tight-packed '+' buttons wrap across the full width. Grow to fit any
        // already-stored chords too. View mode renders only filled slots.
        const MIN_SLOTS = 28
        const slotCount = Math.max(words.length + 6, line.chords.length, MIN_SLOTS)
        return (
          <div key={lineIdx}>
            {!isSection && (
              readOnly ? (
                // Same slot layout as edit mode: empty slots stay as invisible
                // spacers so each chord keeps the exact x-position it has when
                // editing (a chord in slot 6 stays above the same word).
                <div className="flex flex-wrap gap-0.5 sm:gap-px mb-1">
                  {Array.from({ length: slotCount }).map((_, wordIdx) => {
                    const chord = line.chords[wordIdx] || ''
                    return chord ? (
                      <span
                        key={wordIdx}
                        className="min-w-[28px] h-7 sm:min-w-[20px] sm:h-6 px-1 rounded text-xs font-bold bg-accent-surface/30 text-accent inline-flex items-center justify-center"
                      >
                        {chord}
                      </span>
                    ) : (
                      <span key={wordIdx} className="min-w-[28px] h-7 sm:min-w-[20px] sm:h-6 px-1 text-xs font-bold invisible">+</span>
                    )
                  })}
                </div>
              ) : (
                <div className="flex flex-wrap gap-0.5 sm:gap-px mb-1">
                  {Array.from({ length: slotCount }).map((_, wordIdx) => {
                    const chord = line.chords[wordIdx] || ''
                    return (
                      <button
                        key={wordIdx}
                        onClick={() => setPickerFor({ lineIdx, wordIdx })}
                        className={`min-w-[28px] h-7 sm:min-w-[20px] sm:h-6 px-1 rounded text-xs font-bold ${
                          chord ? 'bg-accent-surface/30 text-accent' : 'bg-accent-surface/10 text-accent/40'
                        }`}
                      >
                        {chord || '+'}
                      </button>
                    )
                  })}
                </div>
              )
            )}
            {line.lyrics.trim() && (
              <p className={isSection ? 'font-bold text-accent text-sm' : 'text-text-primary text-sm'}>{line.lyrics}</p>
            )}
          </div>
        )
      })}

      {pickerFor && (
        <Modal open onClose={() => setPickerFor(null)} title={`Select Chord (Key of ${songKey})`} maxWidth="max-w-sm">
          <div className="flex flex-wrap gap-2 justify-center mb-4">
            {chordChoices.map((c) => (
              <button
                key={c}
                onClick={() => { setChord(pickerFor.lineIdx, pickerFor.wordIdx, c); setPickerFor(null) }}
                className="px-4 py-2 rounded-lg bg-accent-surface/20 border border-accent/40 text-accent font-bold text-sm hover:bg-accent-surface/30"
              >
                {c}
              </button>
            ))}
          </div>
          <button
            onClick={() => { setChord(pickerFor.lineIdx, pickerFor.wordIdx, ''); setPickerFor(null) }}
            className="w-full text-center text-danger font-semibold text-sm py-2"
          >
            Clear Chord
          </button>
        </Modal>
      )}
    </div>
  )
}
