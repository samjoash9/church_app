import { useEffect, useMemo, useState } from 'react'
import { Plus, Presentation, Search, FileDown, Trash2, Music2, CornerDownRight, RectangleHorizontal } from 'lucide-react'
import { TopBar } from '../components/TopBar'
import { Modal } from '../components/Modal'
import { Button } from '../components/Button'
import { api, downloadBlob } from '../api/client'
import { ThemePickerModal } from '../components/ThemePickerModal'
import type { Ppt, Song } from '../types'

// Fixed section slides that wrap every presentation (same as mobile/backend).
const INTRO_SECTIONS = ['SUNDAY SCHOOL', 'ANNOUNCEMENT', 'PRAISE & WORSHIP']
const OUTRO_SECTIONS = ['WORD', 'TITHES & OFFERING', 'ANNOUNCEMENT']

/**
 * Mirrors the exporter's grouping (mobile buildSongSlides / backend
 * ppt_themes.build_song_slides): a [Section] line starts a new slide group,
 * lyric lines pack 4-per-slide with a (cont.) marker once a group overflows.
 * What the overview lists is exactly what the PPTX contains.
 */
function buildSongSlides(song: Song): { label: string }[] {
  const slides: { label: string }[] = []
  let title = `[${song.title}]`
  let buffered = 0
  const flush = () => {
    if (buffered > 0) {
      const raw = title.replace(/[[\]]/g, '')
      const label = raw.includes(' - ') ? raw.slice(raw.indexOf(' - ') + 3) : 'Lyrics'
      slides.push({ label })
      buffered = 0
    }
  }
  for (const line of song.lines) {
    const text = line.lyrics.trim()
    if (!text) continue
    if (text.startsWith('[') && text.endsWith(']')) {
      flush()
      title = `[${song.title} - ${text.slice(1, -1)}]`
    } else {
      buffered++
      if (buffered >= 4) {
        flush()
        if (!title.endsWith('(cont.)]')) title = title.replace(']', ' (cont.)]')
      }
    }
  }
  flush()
  return slides
}

export function PptPage() {
  const [ppts, setPpts] = useState<Ppt[]>([])
  const [songs, setSongs] = useState<Song[]>([])
  const [query, setQuery] = useState('')
  const [createOpen, setCreateOpen] = useState(false)
  const [overviewPpt, setOverviewPpt] = useState<Ppt | null>(null)
  const [exportingPpt, setExportingPpt] = useState<Ppt | null>(null)

  const refresh = () => {
    api.ppts.list().then(setPpts).catch(() => {})
    api.songs.list().then(setSongs).catch(() => {})
  }
  useEffect(() => { refresh() }, [])

  const filtered = useMemo(() => ppts.filter((p) => p.title.toLowerCase().includes(query.toLowerCase())), [ppts, query])

  async function exportPpt(ppt: Ppt, themeId: string) {
    const blob = await api.exportPpt(ppt.song_ids, themeId)
    downloadBlob(blob, `${ppt.title}.pptx`)
  }

  return (
    <div>
      <TopBar title="Presentations" />
      <div className={`p-5 md:p-8 ${ppts.length > 0 ? 'max-w-2xl mx-auto' : ''}`}>
        {ppts.length > 0 && (
          <div className="relative mb-6">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-muted" size={18} />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search presentations..."
              className="w-full pl-11 pr-4 py-3 rounded-xl bg-surface border border-border text-text-primary placeholder:text-text-muted focus:outline-none focus:border-accent"
            />
          </div>
        )}

        {ppts.length === 0 ? (
          <div className="flex flex-col items-center justify-center text-center min-h-[70vh]">
            <Presentation className="text-text-muted mb-4" size={56} />
            <h3 className="text-xl font-bold text-text-primary mb-2">No PPTs Yet</h3>
            <p className="text-text-muted mb-6">Tap "Create PPT" to build your presentation.</p>
            <Button icon={<Plus size={16} />} onClick={() => setCreateOpen(true)}>Create PPT</Button>
          </div>
        ) : (
          <div className="space-y-3">
            {filtered.map((ppt) => (
              <div key={ppt.id} className="flex items-center gap-3 px-4 py-3.5 rounded-xl bg-surface border border-border hover:border-accent/40 transition-colors">
                <button
                  onClick={() => setOverviewPpt(ppt)}
                  className="flex items-center gap-3 flex-1 min-w-0 text-left cursor-pointer"
                >
                  <div className="w-11 h-11 rounded-full bg-accent-surface/20 flex items-center justify-center shrink-0">
                    <Presentation className="text-accent" size={20} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-text-primary truncate">{ppt.title}</p>
                    <p className="text-xs text-text-secondary">{ppt.song_ids.length} song(s)</p>
                  </div>
                </button>
                <button onClick={() => setExportingPpt(ppt)} className="p-2 text-accent hover:bg-accent-surface/10 rounded-lg" title="Export PPTX">
                  <FileDown size={18} />
                </button>
                <button
                  onClick={() => { if (confirm(`Delete "${ppt.title}"?`)) api.ppts.remove(ppt.id).then(refresh) }}
                  className="p-2 text-danger hover:bg-danger/10 rounded-lg"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {ppts.length > 0 && (
        <button
          onClick={() => setCreateOpen(true)}
          className="fixed bottom-20 md:bottom-8 right-6 flex items-center gap-2 pl-5 pr-6 h-14 rounded-full bg-accent text-on-accent shadow-lg font-semibold hover:opacity-90 transition-opacity z-20"
        >
          <Plus size={22} />
          Add Presentation
        </button>
      )}

      <CreatePptModal open={createOpen} onClose={() => setCreateOpen(false)} songs={songs} onCreated={refresh} />

      {overviewPpt && (
        <PptOverviewModal ppt={overviewPpt} allSongs={songs} onClose={() => setOverviewPpt(null)} />
      )}

      <ThemePickerModal
        open={!!exportingPpt}
        onClose={() => setExportingPpt(null)}
        onConfirm={async (themeId) => { if (exportingPpt) await exportPpt(exportingPpt, themeId) }}
      />
    </div>
  )
}

/** Slide-by-slide glimpse of the deck a presentation exports to — mirrors the
 * mobile overview: title slide, intro sections, per-song slides, outro. */
function PptOverviewModal({ ppt, allSongs, onClose }: { ppt: Ppt; allSongs: Song[]; onClose: () => void }) {
  const resolved = ppt.song_ids
    .map((id) => allSongs.find((s) => s.id === id))
    .filter((s): s is Song => !!s)
  const missingCount = ppt.song_ids.length - resolved.length
  const outlines = resolved.map((song) => ({ song, slides: buildSongSlides(song) }))
  // Title slide + intro + (song title slide + lyric slides) each + outro.
  const totalSlides =
    1 + INTRO_SECTIONS.length + outlines.reduce((sum, o) => sum + 1 + o.slides.length, 0) + OUTRO_SECTIONS.length

  const sectionRow = (label: string, i: number) => (
    <div key={`${label}-${i}`} className="flex items-center gap-2.5 text-sm text-text-secondary font-semibold tracking-wide py-0.5">
      <RectangleHorizontal className="text-text-muted shrink-0" size={16} />
      {label}
    </div>
  )

  return (
    <Modal open onClose={onClose} title={ppt.title} maxWidth="max-w-lg">
      <p className="text-sm text-text-secondary -mt-2 mb-4">
        {totalSlides} slide{totalSlides === 1 ? '' : 's'} · {resolved.length} song{resolved.length === 1 ? '' : 's'}
      </p>
      <div className="space-y-2 max-h-[55vh] overflow-y-auto pr-1">
        <div className="flex items-center gap-2.5 text-sm text-text-primary font-semibold py-0.5">
          <Presentation className="text-accent shrink-0" size={16} />
          Title slide
        </div>
        {INTRO_SECTIONS.map(sectionRow)}
        {outlines.length === 0 ? (
          <p className="text-sm text-text-muted py-4 text-center">No songs in this presentation.</p>
        ) : (
          outlines.map(({ song, slides }) => (
            <div key={song.id} className="py-1.5">
              <div className="flex items-center gap-2.5">
                <Music2 className="text-accent shrink-0" size={18} />
                <span className="flex-1 font-bold text-text-primary truncate">{song.title}</span>
                <span className="text-xs text-text-muted shrink-0">
                  {1 + slides.length} slide{slides.length === 0 ? '' : 's'}
                </span>
              </div>
              <p className="pl-7 mt-0.5 text-xs text-text-secondary">Key of {song.songKey}</p>
              <div className="pl-7 mt-1.5 space-y-1">
                {slides.map((slide, i) => (
                  <div key={i} className="flex items-center gap-1.5 text-xs text-text-secondary">
                    <CornerDownRight className="text-text-muted shrink-0" size={13} />
                    {slide.label}
                  </div>
                ))}
              </div>
            </div>
          ))
        )}
        {OUTRO_SECTIONS.map(sectionRow)}
        {missingCount > 0 && (
          <p className="text-xs text-danger pt-2">
            {missingCount} song{missingCount === 1 ? '' : 's'} no longer exist and will be skipped.
          </p>
        )}
      </div>
      <Button variant="secondary" className="w-full mt-5" onClick={onClose}>Back</Button>
    </Modal>
  )
}

function CreatePptModal({
  open,
  onClose,
  songs,
  onCreated,
}: {
  open: boolean
  onClose: () => void
  songs: Song[]
  onCreated: () => void
}) {
  const [step, setStep] = useState<'select' | 'name'>('select')
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [query, setQuery] = useState('')
  const [name, setName] = useState('')

  useEffect(() => {
    if (open) {
      setStep('select')
      setSelected(new Set())
      setQuery('')
      setName(`Presentation ${new Date().toISOString().split('T')[0]}`)
    }
  }, [open])

  const filtered = songs.filter((s) => s.title.toLowerCase().includes(query.toLowerCase()))

  async function handleCreate() {
    if (!name.trim()) return
    await api.ppts.create({ id: Date.now().toString(), title: name.trim(), song_ids: [...selected] })
    onCreated()
    onClose()
  }

  return (
    <Modal open={open} onClose={onClose} title={step === 'select' ? 'Select songs for PPT' : 'Name your PPT'} maxWidth="max-w-lg">
      {step === 'select' ? (
        <>
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search songs..."
            className="w-full px-4 py-2.5 rounded-lg bg-surface-dim border border-border text-text-primary text-sm mb-4 focus:outline-none focus:border-accent"
          />
          <div className="space-y-1 max-h-96 overflow-y-auto -mx-2 mb-4">
            {filtered.length === 0 ? (
              <p className="text-center text-text-muted py-8 text-sm">No songs found</p>
            ) : (
              filtered.map((song) => {
                const checked = selected.has(song.id)
                return (
                  <label key={song.id} className="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-surface-dim cursor-pointer">
                    <span className="flex-1 text-sm font-medium text-text-primary">{song.title}</span>
                    <span className="text-xs text-text-secondary">Key of {song.songKey}</span>
                    <input
                      type="checkbox"
                      checked={checked}
                      onChange={() => setSelected((s) => { const next = new Set(s); checked ? next.delete(song.id) : next.add(song.id); return next })}
                      className="accent-accent w-4 h-4"
                    />
                  </label>
                )
              })
            )}
          </div>
          <Button className="w-full" disabled={selected.size === 0} onClick={() => setStep('name')}>
            Create PPT with {selected.size} song(s)
          </Button>
        </>
      ) : (
        <>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Enter PPT name"
            className="w-full px-4 py-3 rounded-xl bg-surface-dim border border-border text-text-primary mb-4 focus:outline-none focus:border-accent"
          />
          <div className="flex gap-3">
            <Button variant="secondary" className="flex-1" onClick={() => setStep('select')}>Back</Button>
            <Button className="flex-1" disabled={!name.trim()} onClick={handleCreate}>Save</Button>
          </div>
        </>
      )}
    </Modal>
  )
}
