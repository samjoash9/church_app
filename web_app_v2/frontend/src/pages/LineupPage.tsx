import { useEffect, useMemo, useState } from 'react'
import {
  Plus, GripVertical, ChevronRight, Play, FileDown,
  Presentation, Trash2, Eye, ArrowUpDown, ArrowLeft,
} from 'lucide-react'
import { TopBar } from '../components/TopBar'
import { Modal } from '../components/Modal'
import { Button } from '../components/Button'
import { KeyAvatar } from '../components/KeyAvatar'
import { api, downloadBlob } from '../api/client'
import type { LineupItem, Song } from '../types'
import { PerformOverlay } from '../components/PerformOverlay'
import { ChangeKeyPanel, SongOverview } from '../components/SongModals'
import { ConfirmModal } from '../components/ConfirmModal'
import { ThemePickerModal } from '../components/ThemePickerModal'

export function LineupPage() {
  const [lineup, setLineup] = useState<LineupItem[]>([])
  const [songs, setSongs] = useState<Song[]>([])
  const [addOpen, setAddOpen] = useState(false)
  const [clearOpen, setClearOpen] = useState(false)
  const [pptPickerOpen, setPptPickerOpen] = useState(false)
  const [performing, setPerforming] = useState(false)
  const [dragIdx, setDragIdx] = useState<number | null>(null)
  const [actionItem, setActionItem] = useState<{ item: LineupItem; song: Song } | null>(null)

  const refresh = () => {
    api.lineup.list().then(setLineup).catch(() => {})
    api.songs.list().then(setSongs).catch(() => {})
  }
  useEffect(() => { refresh() }, [])

  const lineupSongs = useMemo(
    () =>
      lineup
        .slice()
        .sort((a, b) => a.order_index - b.order_index)
        .map((item) => ({ item, song: songs.find((s) => s.id === item.song_id) }))
        .filter((x): x is { item: LineupItem; song: Song } => !!x.song),
    [lineup, songs]
  )

  async function handleReorder(from: number, to: number) {
    const ids = lineupSongs.map((x) => x.item.song_id)
    const [moved] = ids.splice(from, 1)
    ids.splice(to, 0, moved)
    await api.lineup.reorder(ids)
    refresh()
  }

  async function exportPdf() {
    const blob = await api.exportPdf(lineupSongs.map((x) => x.song.id))
    downloadBlob(blob, 'Lineup.pdf')
  }

  async function exportPpt(themeId: string) {
    const blob = await api.exportPpt(lineupSongs.map((x) => x.song.id), themeId)
    downloadBlob(blob, 'Lineup.pptx')
  }

  return (
    <div>
      <TopBar
        title="Line up"
        action={
          lineupSongs.length > 0 ? (
            <div className="flex items-center gap-2">
              <Button variant="primary" icon={<Play size={16} />} onClick={() => setPerforming(true)}>Perform</Button>
              <Button variant="secondary" icon={<FileDown size={16} />} onClick={exportPdf}>
                <span className="hidden lg:inline">Export </span>PDF
              </Button>
              <Button variant="secondary" icon={<Presentation size={16} />} onClick={() => setPptPickerOpen(true)}>
                <span className="hidden lg:inline">Export </span>PPT
              </Button>
              <button
                onClick={() => setClearOpen(true)}
                className="inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold text-danger border border-danger/30 bg-danger/10 hover:bg-danger/20 transition-colors"
              >
                <Trash2 size={16} />
                Clear
              </button>
            </div>
          ) : undefined
        }
      />

      <div className={`p-5 md:p-8 ${lineupSongs.length > 0 ? 'max-w-2xl mx-auto' : ''}`}>
        {lineupSongs.length === 0 ? (
          <div className="flex flex-col items-center justify-center text-center min-h-[70vh]">
            <ChevronRight className="text-text-muted mb-4 rotate-90" size={56} />
            <h3 className="text-xl font-bold text-text-primary mb-2">Empty Line up</h3>
            <p className="text-text-muted">Tap + to add songs to your lineup.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {lineupSongs.map(({ item, song }, idx) => (
              <div
                key={item.id}
                draggable
                onDragStart={() => setDragIdx(idx)}
                onDragOver={(e) => e.preventDefault()}
                onDrop={() => { if (dragIdx !== null && dragIdx !== idx) handleReorder(dragIdx, idx); setDragIdx(null) }}
                className="flex items-center gap-3 px-4 py-3 rounded-xl bg-surface border border-border hover:border-accent/40 transition-colors"
              >
                <button
                  onClick={() => setActionItem({ item, song })}
                  className="flex items-center gap-3 flex-1 min-w-0 text-left cursor-pointer"
                >
                  <KeyAvatar songKey={song.songKey} size={40} />
                  <span className="flex-1 font-bold text-text-primary truncate">{song.title}</span>
                </button>
                <GripVertical className="text-text-muted cursor-grab shrink-0" size={20} />
              </div>
            ))}
          </div>
        )}
      </div>

      <button
        onClick={() => setAddOpen(true)}
        className="fixed bottom-20 md:bottom-8 right-6 flex items-center gap-2 pl-5 pr-6 h-14 rounded-full bg-accent text-on-accent shadow-lg font-semibold hover:opacity-90 transition-opacity z-20"
      >
        <Plus size={22} />
        Add Song
      </button>

      <AddSongsModal
        open={addOpen}
        onClose={() => setAddOpen(false)}
        allSongs={songs}
        currentIds={new Set(lineup.map((l) => l.song_id))}
        onDone={refresh}
      />

      {actionItem && (
        <LineupSongModal
          item={actionItem.item}
          song={actionItem.song}
          onClose={() => setActionItem(null)}
          onChanged={refresh}
        />
      )}

      <ThemePickerModal
        open={pptPickerOpen}
        onClose={() => setPptPickerOpen(false)}
        onConfirm={exportPpt}
      />

      <ConfirmModal
        open={clearOpen}
        title="Clear Line up"
        message="Remove all songs from the lineup? This can't be undone."
        confirmLabel="Clear"
        onConfirm={() => api.lineup.clear().then(refresh)}
        onClose={() => setClearOpen(false)}
      />

      {performing && <PerformOverlay songs={lineupSongs.map((x) => x.song)} onClose={() => setPerforming(false)} />}
    </div>
  )
}

function LineupSongModal({
  item,
  song,
  onClose,
  onChanged,
}: {
  item: LineupItem
  song: Song
  onClose: () => void
  onChanged: () => void
}) {
  const [view, setView] = useState<'menu' | 'overview' | 'changeKey'>('menu')

  if (view === 'overview') {
    return <SongOverview song={song} onBack={() => setView('menu')} />
  }
  if (view === 'changeKey') {
    return <ChangeKeyPanel song={song} onBack={() => setView('menu')} onDone={() => { onChanged(); onClose() }} />
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
          <LineupActionBtn icon={<Eye size={18} />} label="Overview" primary onClick={() => setView('overview')} />
          <LineupActionBtn icon={<ArrowUpDown size={18} />} label="Change Key" onClick={() => setView('changeKey')} />
          <LineupActionBtn
            icon={<Trash2 size={18} />}
            label="Remove from Line up"
            danger
            onClick={async () => { await api.lineup.remove(item.id); onChanged(); onClose() }}
          />
          <LineupActionBtn icon={<ArrowLeft size={18} />} label="Back" onClick={onClose} />
        </div>
      </div>
    </Modal>
  )
}

function LineupActionBtn({ icon, label, onClick, primary, danger }: { icon?: React.ReactNode; label: string; onClick: () => void; primary?: boolean; danger?: boolean }) {
  return (
    <button
      onClick={onClick}
      className={`w-full flex items-center justify-center gap-2 py-3 rounded-xl font-semibold text-sm transition-colors ${
        primary
          ? 'bg-accent text-on-accent hover:opacity-90'
          : danger
            ? 'bg-surface-dim text-danger hover:bg-danger/10'
            : 'bg-surface-dim text-text-primary hover:bg-border/40'
      }`}
    >
      {icon}
      {label}
    </button>
  )
}

function AddSongsModal({
  open,
  onClose,
  allSongs,
  currentIds,
  onDone,
}: {
  open: boolean
  onClose: () => void
  allSongs: Song[]
  currentIds: Set<string>
  onDone: () => void
}) {
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [query, setQuery] = useState('')

  useEffect(() => { if (open) setSelected(new Set(currentIds)) }, [open])

  const filtered = allSongs.filter((s) => s.title.toLowerCase().includes(query.toLowerCase()))

  async function handleConfirm() {
    for (const song of allSongs) {
      if (selected.has(song.id) && !currentIds.has(song.id)) await api.lineup.add(song.id)
    }
    onDone()
    onClose()
  }

  const newCount = [...selected].filter((id) => !currentIds.has(id)).length

  return (
    <Modal open={open} onClose={onClose} title="Add songs to Line up" maxWidth="max-w-lg">
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search songs..."
        className="w-full px-4 py-2.5 rounded-lg bg-surface-dim border border-border text-text-primary text-sm mb-4 focus:outline-none focus:border-accent"
      />
      <div className="space-y-1 max-h-96 overflow-y-auto -mx-2">
        {filtered.length === 0 ? (
          <p className="text-center text-text-muted py-8 text-sm">No songs found</p>
        ) : (
          filtered.map((song) => {
            const checked = selected.has(song.id)
            return (
              <label key={song.id} className="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-surface-dim cursor-pointer">
                <KeyAvatar songKey={song.songKey} size={32} />
                <span className="flex-1 text-sm font-medium text-text-primary">{song.title}</span>
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
      <Button className="w-full mt-4" onClick={handleConfirm}>
        Add {newCount} song{newCount === 1 ? '' : 's'} to Line up
      </Button>
    </Modal>
  )
}
