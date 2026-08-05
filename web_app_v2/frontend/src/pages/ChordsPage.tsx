import { useEffect, useMemo, useRef, useState } from 'react'
import {
  Search, Folder, FolderOpen, ChevronDown, ChevronUp, Plus, Trash2,
  Eye, Pencil, ListPlus, FileText, ArrowUpDown, FolderInput, FileDown, ArrowLeft, Check,
  Upload, FileJson,
} from 'lucide-react'
import { TopBar } from '../components/TopBar'
import { Modal } from '../components/Modal'
import { Button } from '../components/Button'
import { KeyAvatar } from '../components/KeyAvatar'
import { Select } from '../components/Select'
import { api, downloadBlob } from '../api/client'
import { ALL_KEYS, LANGUAGES, LANGUAGE_LABELS, type Song } from '../types'
import { SongEditorModal } from '../components/SongEditorModal'
import { ChangeKeyPanel, SongOverview } from '../components/SongModals'
import { ConfirmModal } from '../components/ConfirmModal'

export function ChordsPage() {
  const [songs, setSongs] = useState<Song[]>([])
  const [query, setQuery] = useState('')
  const [expanded, setExpanded] = useState<Record<string, boolean>>({ bisaya: true, tagalog: true, english: true })
  const [createOpen, setCreateOpen] = useState(false)
  const [editing, setEditing] = useState<Song | null | 'new-pending'>(null)
  const [pendingMeta, setPendingMeta] = useState<{ title: string; songKey: string; language: string } | null>(null)
  const [actionSong, setActionSong] = useState<Song | null>(null)
  const [overviewSong, setOverviewSong] = useState<Song | null>(null)
  const [deleteSong, setDeleteSong] = useState<Song | null>(null)
  const [exportMode, setExportMode] = useState<'json' | 'pdf' | null>(null)
  const [importing, setImporting] = useState(false)
  const [toast, setToast] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const refresh = () => api.songs.list().then(setSongs).catch(() => {})
  useEffect(() => { refresh() }, [])

  useEffect(() => {
    if (!toast) return
    const t = setTimeout(() => setToast(null), 4000)
    return () => clearTimeout(t)
  }, [toast])

  async function handleImportFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    e.target.value = '' // allow re-selecting the same file
    if (!file) return
    setImporting(true)
    try {
      const r = await api.songs.import(file)
      await refresh()
      const parts: string[] = []
      if (r.imported) parts.push(`${r.imported} added`)
      if (r.updated) parts.push(`${r.updated} updated`)
      if (r.skipped) parts.push(`${r.skipped} skipped`)
      setToast(parts.length ? `Import complete: ${parts.join(', ')}.` : 'No songs imported.')
    } catch (err) {
      setToast(err instanceof Error ? err.message : 'Import failed.')
    } finally {
      setImporting(false)
    }
  }

  const filtered = useMemo(() => {
    const q = query.toLowerCase()
    return songs.filter((s) => s.title.toLowerCase().includes(q) || s.songKey.toLowerCase().includes(q))
  }, [songs, query])

  return (
    <div>
      <TopBar
        title="Chords"
        action={
          <div className="flex items-center gap-2">
            <Button variant="secondary" icon={<Upload size={16} />} disabled={importing} onClick={() => fileInputRef.current?.click()}>
              <span className="hidden lg:inline">{importing ? 'Importing…' : 'Import'}</span>
            </Button>
            {songs.length > 0 && (
              <>
                <Button variant="secondary" icon={<FileJson size={16} />} onClick={() => setExportMode('json')}>
                  <span className="hidden lg:inline">Export </span>Songs
                </Button>
                <Button variant="secondary" icon={<FileDown size={16} />} onClick={() => setExportMode('pdf')}>
                  <span className="hidden lg:inline">Export </span>PDF
                </Button>
              </>
            )}
          </div>
        }
      />
      <input
        ref={fileInputRef}
        type="file"
        accept="application/json,.json"
        className="hidden"
        onChange={handleImportFile}
      />

      <div className={`p-5 md:p-8 ${songs.length > 0 ? 'max-w-3xl mx-auto' : ''}`}>
        {songs.length > 0 && (
          <div className="relative mb-6">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-muted" size={18} />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search songs..."
              className="w-full pl-11 pr-4 py-3 rounded-xl bg-surface border border-border text-text-primary placeholder:text-text-muted focus:outline-none focus:border-accent transition-colors"
            />
          </div>
        )}

        {songs.length === 0 ? (
          <div className="flex flex-col items-center justify-center text-center min-h-[70vh]">
            <FileText className="text-text-muted mb-4" size={56} />
            <h3 className="text-xl font-bold text-text-primary mb-2">No Songs Yet</h3>
            <p className="text-text-muted mb-6">Create your first chord chart to get started.</p>
            <Button onClick={() => setCreateOpen(true)} icon={<Plus size={16} />}>Create New Song</Button>
          </div>
        ) : (
          <div className="space-y-1">
            {LANGUAGES.map((lang) => {
              const langSongs = filtered.filter((s) => s.language === lang)
              const isOpen = query.trim() ? langSongs.length > 0 : expanded[lang]
              return (
                <div key={lang}>
                  <button
                    onClick={() => setExpanded((e) => ({ ...e, [lang]: !e[lang] }))}
                    className="w-full flex items-center gap-3 py-3.5 px-1 text-left"
                  >
                    {isOpen ? <FolderOpen className="text-accent" size={24} /> : <Folder className="text-accent" size={24} />}
                    <span className="font-bold text-text-primary text-lg">{LANGUAGE_LABELS[lang]}</span>
                    <span className="text-text-muted">{langSongs.length}</span>
                    <span className="flex-1" />
                    {isOpen ? <ChevronUp className="text-text-muted" size={20} /> : <ChevronDown className="text-text-muted" size={20} />}
                  </button>
                  {isOpen && (
                    <div className="space-y-1.5 pb-3">
                      {langSongs.length === 0 ? (
                        <p className="text-sm text-text-muted pl-8 pb-2">No songs</p>
                      ) : (
                        langSongs.map((song) => (
                          <div
                            key={song.id}
                            onClick={() => setActionSong(song)}
                            className="flex items-center gap-3 px-3 py-2 rounded-xl bg-surface border border-border hover:border-accent/40 cursor-pointer transition-colors"
                          >
                            <KeyAvatar songKey={song.songKey} size={36} />
                            <div className="flex-1 min-w-0">
                              <p className="font-bold text-sm text-text-primary truncate">{song.title}</p>
                              <p className="text-xs text-text-secondary">Key of {song.songKey}</p>
                            </div>
                            <button
                              onClick={(e) => { e.stopPropagation(); setDeleteSong(song) }}
                              className="p-1.5 text-danger/70 hover:text-danger"
                            >
                              <Trash2 size={16} />
                            </button>
                          </div>
                        ))
                      )}
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        )}
      </div>

      {songs.length > 0 && (
        <button
          onClick={() => setCreateOpen(true)}
          className="fixed bottom-20 md:bottom-8 right-6 w-14 h-14 rounded-full bg-accent text-on-accent shadow-lg flex items-center justify-center hover:opacity-90 transition-opacity z-20"
        >
          <Plus size={26} />
        </button>
      )}

      <CreateSongModal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onConfirm={(meta) => { setCreateOpen(false); setPendingMeta(meta); setEditing('new-pending') }}
      />

      {editing && (
        <SongEditorModal
          open={!!editing}
          song={editing === 'new-pending' ? null : editing}
          pendingMeta={editing === 'new-pending' ? pendingMeta : null}
          onClose={() => { setEditing(null); setPendingMeta(null) }}
          onSaved={() => { refresh(); setEditing(null); setPendingMeta(null) }}
        />
      )}

      {actionSong && (
        <SongActionModal
          song={actionSong}
          onClose={() => setActionSong(null)}
          onEdit={() => { setEditing(actionSong); setActionSong(null) }}
          onOverview={() => { setOverviewSong(actionSong); setActionSong(null) }}
          onChanged={refresh}
        />
      )}

      {overviewSong && (
        <SongOverview song={overviewSong} onBack={() => setOverviewSong(null)} onEdit={() => { setEditing(overviewSong); setOverviewSong(null) }} />
      )}

      <ConfirmModal
        open={!!deleteSong}
        title="Delete Song"
        message={deleteSong ? `Are you sure you want to delete "${deleteSong.title}"? This can't be undone.` : ''}
        onConfirm={() => { if (deleteSong) api.songs.remove(deleteSong.id).then(refresh) }}
        onClose={() => setDeleteSong(null)}
      />

      {exportMode && (
        <ExportSelectModal
          songs={songs}
          mode={exportMode}
          onClose={() => setExportMode(null)}
          onDone={(msg) => { setExportMode(null); if (msg) setToast(msg) }}
        />
      )}

      {toast && (
        <div className="fixed bottom-24 md:bottom-8 left-1/2 -translate-x-1/2 z-30 px-4 py-3 rounded-xl bg-surface border border-border shadow-lg text-sm text-text-primary max-w-[90vw]">
          {toast}
        </div>
      )}
    </div>
  )
}

function ExportSelectModal({
  songs,
  mode,
  onClose,
  onDone,
}: {
  songs: Song[]
  mode: 'json' | 'pdf'
  onClose: () => void
  onDone: (toast?: string) => void
}) {
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [busy, setBusy] = useState(false)
  const [query, setQuery] = useState('')

  const filtered = useMemo(() => {
    const q = query.toLowerCase()
    return songs.filter((s) => s.title.toLowerCase().includes(q) || s.songKey.toLowerCase().includes(q))
  }, [songs, query])

  const allSelected = filtered.length > 0 && filtered.every((s) => selected.has(s.id))

  function toggle(id: string) {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function toggleAll() {
    setSelected((prev) => {
      const next = new Set(prev)
      if (allSelected) filtered.forEach((s) => next.delete(s.id))
      else filtered.forEach((s) => next.add(s.id))
      return next
    })
  }

  async function doExport() {
    const ids = songs.filter((s) => selected.has(s.id)).map((s) => s.id)
    if (!ids.length) return
    setBusy(true)
    try {
      if (mode === 'json') {
        const blob = await api.songs.export(ids)
        downloadBlob(blob, `songs_export_${new Date().toISOString().slice(0, 10)}.json`)
        onDone(`Exported ${ids.length} song${ids.length > 1 ? 's' : ''} to JSON.`)
      } else {
        const blob = await api.exportPdf(ids)
        downloadBlob(blob, ids.length > 1 ? 'chord_charts.pdf' : `${songs.find((s) => s.id === ids[0])?.title || 'song'}.pdf`)
        onDone(`Exported ${ids.length} song${ids.length > 1 ? 's' : ''} to PDF.`)
      }
    } catch (err) {
      onDone(err instanceof Error ? err.message : 'Export failed.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <Modal open onClose={onClose} title={mode === 'json' ? 'Export Songs (JSON)' : 'Export as PDF'} maxWidth="max-w-md">
      <div className="space-y-3">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" size={16} />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search songs..."
            className="w-full pl-9 pr-3 py-2.5 rounded-xl bg-surface-dim border border-border text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-accent"
          />
        </div>

        <button onClick={toggleAll} className="flex items-center gap-2 text-sm font-semibold text-accent">
          <span className={`w-4 h-4 rounded flex items-center justify-center border ${allSelected ? 'bg-accent border-accent' : 'border-border'}`}>
            {allSelected && <Check size={12} className="text-on-accent" />}
          </span>
          {allSelected ? 'Deselect all' : 'Select all'}
        </button>

        <div className="max-h-[45vh] overflow-y-auto space-y-1.5 -mx-1 px-1">
          {filtered.length === 0 ? (
            <p className="text-sm text-text-muted text-center py-6">No songs match.</p>
          ) : (
            filtered.map((song) => {
              const on = selected.has(song.id)
              return (
                <button
                  key={song.id}
                  onClick={() => toggle(song.id)}
                  className={`w-full flex items-center gap-3 px-3 py-2 rounded-xl border text-left transition-colors ${on ? 'border-accent bg-accent-surface/10' : 'border-border bg-surface hover:border-accent/40'}`}
                >
                  <span className={`w-5 h-5 rounded flex items-center justify-center border shrink-0 ${on ? 'bg-accent border-accent' : 'border-border'}`}>
                    {on && <Check size={13} className="text-on-accent" />}
                  </span>
                  <KeyAvatar songKey={song.songKey} size={32} />
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-sm text-text-primary truncate">{song.title}</p>
                    <p className="text-xs text-text-secondary">Key of {song.songKey}</p>
                  </div>
                </button>
              )
            })
          )}
        </div>

        <div className="flex gap-3 pt-1">
          <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
          <Button className="flex-1" disabled={selected.size === 0 || busy} onClick={doExport}>
            {busy ? 'Exporting…' : `Export (${selected.size})`}
          </Button>
        </div>
      </div>
    </Modal>
  )
}

function CreateSongModal({
  open,
  onClose,
  onConfirm,
}: {
  open: boolean
  onClose: () => void
  onConfirm: (meta: { title: string; songKey: string; language: string }) => void
}) {
  const [title, setTitle] = useState('')
  const [songKey, setSongKey] = useState('')
  const [language, setLanguage] = useState('english')

  useEffect(() => {
    if (open) { setTitle(''); setSongKey(''); setLanguage('english') }
  }, [open])

  return (
    <Modal open={open} onClose={onClose} title="Create New Song">
      <div className="space-y-5">
        <div>
          <label className="block text-xs font-semibold text-text-secondary mb-2 uppercase tracking-wide">Title</label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g. Amazing Grace"
            className="w-full px-4 py-3 rounded-xl bg-surface-dim border border-border text-text-primary focus:outline-none focus:border-accent"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-text-secondary mb-2 uppercase tracking-wide">Key</label>
          <Select
            value={songKey}
            onChange={setSongKey}
            placeholder="Select a key"
            options={ALL_KEYS.map((k) => ({ value: k, label: `${k} Major` }))}
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-text-secondary mb-2 uppercase tracking-wide">Language</label>
          <Select
            value={language}
            onChange={setLanguage}
            options={LANGUAGES.map((l) => ({ value: l, label: LANGUAGE_LABELS[l] }))}
          />
        </div>
        <div className="flex gap-3 pt-2">
          <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
          <Button
            className="flex-1"
            disabled={!title.trim() || !songKey}
            onClick={() => onConfirm({ title: title.trim(), songKey, language })}
          >
            Confirm
          </Button>
        </div>
      </div>
    </Modal>
  )
}

type ActionView = 'menu' | 'changeKey' | 'rename' | 'move'

function SongActionModal({
  song,
  onClose,
  onEdit,
  onOverview,
  onChanged,
}: {
  song: Song
  onClose: () => void
  onEdit: () => void
  onOverview: () => void
  onChanged: () => void
}) {
  const [view, setView] = useState<ActionView>('menu')

  if (view === 'changeKey') {
    return <ChangeKeyPanel song={song} onBack={() => setView('menu')} onDone={() => { onChanged(); onClose() }} />
  }
  if (view === 'rename') {
    return <RenamePanel song={song} onBack={() => setView('menu')} onDone={() => { onChanged(); onClose() }} />
  }
  if (view === 'move') {
    return <MoveFolderPanel song={song} onBack={() => setView('menu')} onDone={() => { onChanged(); onClose() }} />
  }

  return (
    <Modal open onClose={onClose} maxWidth="max-w-sm">
      <div className="text-center">
        <div className="w-14 h-14 mx-auto rounded-full bg-accent-surface/20 flex items-center justify-center mb-3">
          <KeyAvatar songKey={song.songKey} size={40} />
        </div>
        <h3 className="font-bold text-lg text-text-primary">{song.title}</h3>
        <p className="text-sm text-text-secondary mb-6">Key of {song.songKey}</p>
        <div className="space-y-2">
          <ActionBtn icon={<Eye size={18} />} label="Overview" primary onClick={onOverview} />
          <ActionBtn icon={<Pencil size={18} />} label="Edit Song" onClick={onEdit} />
          <ActionBtn icon={<ArrowUpDown size={18} />} label="Change Key" onClick={() => setView('changeKey')} />
          <ActionBtn
            icon={<ListPlus size={18} />}
            label="Add to Line up"
            onClick={async () => { await api.lineup.add(song.id); onClose() }}
          />
          <ActionBtn icon={<Pencil size={18} />} label="Rename" onClick={() => setView('rename')} />
          <ActionBtn icon={<FolderInput size={18} />} label="Move to Folder" onClick={() => setView('move')} />
          <ActionBtn
            icon={<FileDown size={18} />}
            label="Export as PDF"
            onClick={async () => {
              const blob = await api.exportPdf([song.id])
              downloadBlob(blob, `${song.title}.pdf`)
              onClose()
            }}
          />
          <ActionBtn icon={<ArrowLeft size={18} />} label="Back" onClick={onClose} />
        </div>
      </div>
    </Modal>
  )
}

function RenamePanel({ song, onBack, onDone }: { song: Song; onBack: () => void; onDone: () => void }) {
  const [title, setTitle] = useState(song.title)
  const [saving, setSaving] = useState(false)

  async function save() {
    const next = title.trim()
    if (!next || next === song.title) return
    setSaving(true)
    try {
      await api.songs.update(song.id, { ...song, title: next })
      onDone()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal open onClose={onBack} title="Rename Song" maxWidth="max-w-sm">
      <div className="space-y-4">
        <input
          value={title}
          autoFocus
          onChange={(e) => setTitle(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter') save() }}
          placeholder="Song title"
          className="w-full px-4 py-3 rounded-xl bg-surface-dim border border-border text-text-primary focus:outline-none focus:border-accent"
        />
        <div className="flex gap-3 pt-2">
          <Button variant="secondary" className="flex-1" onClick={onBack}>Back</Button>
          <Button className="flex-1" disabled={!title.trim() || title.trim() === song.title || saving} onClick={save}>Save</Button>
        </div>
      </div>
    </Modal>
  )
}

function MoveFolderPanel({ song, onBack, onDone }: { song: Song; onBack: () => void; onDone: () => void }) {
  async function move(lang: string) {
    if (lang === song.language) return
    await api.songs.update(song.id, { ...song, language: lang })
    onDone()
  }

  return (
    <Modal open onClose={onBack} title="Move to Folder" maxWidth="max-w-sm">
      <div className="space-y-1">
        {LANGUAGES.map((lang) => {
          const isCurrent = song.language === lang
          return (
            <button
              key={lang}
              disabled={isCurrent}
              onClick={() => move(lang)}
              className={`w-full flex items-center gap-3 px-3 py-3 rounded-xl text-left transition-colors ${
                isCurrent ? 'bg-surface-dim cursor-default' : 'hover:bg-surface-dim'
              }`}
            >
              <Folder className={isCurrent ? 'text-accent' : 'text-text-muted'} size={20} />
              <span className={`flex-1 font-medium ${isCurrent ? 'text-accent' : 'text-text-primary'}`}>
                {LANGUAGE_LABELS[lang]}
              </span>
              {isCurrent && <Check className="text-accent" size={18} />}
            </button>
          )
        })}
      </div>
      <Button variant="secondary" className="w-full mt-4" onClick={onBack}>Back</Button>
    </Modal>
  )
}

function ActionBtn({ icon, label, onClick, primary, danger }: { icon?: React.ReactNode; label: string; onClick: () => void; primary?: boolean; danger?: boolean }) {
  return (
    <button
      onClick={onClick}
      className={`w-full flex items-center justify-center gap-2 py-3 rounded-xl font-semibold text-sm transition-colors ${
        primary
          ? 'bg-accent text-on-accent hover:opacity-90'
          : danger
            ? 'bg-danger/10 text-danger hover:bg-danger/20'
            : 'bg-surface-dim text-text-primary hover:bg-border/40'
      }`}
    >
      {icon}
      {label}
    </button>
  )
}

