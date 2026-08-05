import { useEffect, useState } from 'react'
import { X, ChevronLeft, ChevronRight } from 'lucide-react'
import { createPortal } from 'react-dom'
import type { Song } from '../types'

export function PerformOverlay({ songs, onClose }: { songs: Song[]; onClose: () => void }) {
  const [index, setIndex] = useState(0)
  const song = songs[index]

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
      if (e.key === 'ArrowRight') setIndex((i) => Math.min(i + 1, songs.length - 1))
      if (e.key === 'ArrowLeft') setIndex((i) => Math.max(i - 1, 0))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [songs.length, onClose])

  if (!song) {
    return createPortal(
      <div className="fixed inset-0 z-50 bg-scaffold flex items-center justify-center">
        <p className="text-text-muted">No songs to perform</p>
        <button onClick={onClose} className="absolute top-4 left-4 text-text-muted"><X size={24} /></button>
      </div>,
      document.body
    )
  }

  return createPortal(
    <div className="fixed inset-0 z-50 bg-scaffold flex flex-col">
      <div className="flex items-center gap-3 px-4 py-3 border-b border-border bg-surface shrink-0">
        <button onClick={onClose} className="text-text-muted hover:text-text-primary"><X size={22} /></button>
        <div className="flex-1 text-center">
          <p className="font-bold text-text-primary text-base">{song.title}</p>
          <p className="text-xs text-text-secondary">Key of {song.songKey} · {index + 1} / {songs.length}</p>
        </div>
        <div className="w-6" />
      </div>
      <div className="flex-1 overflow-y-auto px-6 md:px-16 py-8 max-w-3xl mx-auto w-full">
        {song.lines.map((line, i) => {
          const isSection = line.lyrics.trim().startsWith('[') && line.lyrics.trim().endsWith(']')
          const hasChords = line.chords.some((c) => c)
          if (!line.lyrics.trim() && !hasChords) return <div key={i} className="h-4" />
          return (
            <div key={i} className="mb-3">
              {!isSection && hasChords && (
                // Fixed-slot grid mirroring the editor/overview: empty slots
                // stay as invisible spacers so each chord keeps the x-position
                // it was placed at. Do NOT filter empties — that collapses the
                // grid and destroys alignment.
                <div className="flex flex-wrap gap-px mb-1">
                  {line.chords.map((c, j) =>
                    c ? (
                      <span
                        key={j}
                        className="min-w-[24px] h-7 px-1 rounded text-sm font-bold bg-accent-surface/30 text-accent inline-flex items-center justify-center"
                      >
                        {c}
                      </span>
                    ) : (
                      <span key={j} className="min-w-[24px] h-7 px-1 text-sm font-bold invisible">+</span>
                    )
                  )}
                </div>
              )}
              {line.lyrics.trim() && (
                <p className={isSection ? 'font-bold text-accent text-lg' : 'text-text-primary text-lg'}>{line.lyrics}</p>
              )}
            </div>
          )
        })}
      </div>
      <div className="flex items-center justify-between px-6 py-4 border-t border-border bg-surface shrink-0">
        <button
          onClick={() => setIndex((i) => Math.max(i - 1, 0))}
          disabled={index === 0}
          className="flex items-center gap-1 text-text-primary disabled:opacity-30 font-semibold text-sm"
        >
          <ChevronLeft size={20} /> Prev
        </button>
        <button
          onClick={() => setIndex((i) => Math.min(i + 1, songs.length - 1))}
          disabled={index === songs.length - 1}
          className="flex items-center gap-1 text-text-primary disabled:opacity-30 font-semibold text-sm"
        >
          Next <ChevronRight size={20} />
        </button>
      </div>
    </div>,
    document.body
  )
}
