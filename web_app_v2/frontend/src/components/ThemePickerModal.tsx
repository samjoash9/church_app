import { useEffect, useState } from 'react'
import { Check } from 'lucide-react'
import { Modal } from './Modal'
import { Button } from './Button'
import { api } from '../api/client'

interface PptThemeInfo {
  id: string
  displayName: string
  preview: string
}

/**
 * Theme picker shown before a PPT export — the web twin of the mobile app's
 * theme chooser. Thumbnails come from the shared assets/ppt_backgrounds
 * folder served by the backend.
 */
export function ThemePickerModal({
  open,
  onClose,
  onConfirm,
}: {
  open: boolean
  onClose: () => void
  onConfirm: (themeId: string) => void
}) {
  const [themes, setThemes] = useState<PptThemeInfo[]>([])
  const [selected, setSelected] = useState('cloud')
  const [exporting, setExporting] = useState(false)

  useEffect(() => {
    if (open) {
      setExporting(false)
      api.pptThemes().then(setThemes).catch(() => setThemes([]))
    }
  }, [open])

  async function confirm() {
    setExporting(true)
    try {
      await onConfirm(selected)
      onClose()
    } finally {
      setExporting(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title="Choose a theme" maxWidth="max-w-2xl">
      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 max-h-[55vh] overflow-y-auto pr-1">
        {themes.map((theme) => {
          const isSelected = selected === theme.id
          return (
            <button
              key={theme.id}
              onClick={() => setSelected(theme.id)}
              className={`relative rounded-xl overflow-hidden border-2 transition-colors text-left ${
                isSelected ? 'border-accent' : 'border-border hover:border-accent/40'
              }`}
            >
              <img src={theme.preview} alt={theme.displayName} className="w-full aspect-video object-cover" />
              <div className="px-2.5 py-2 bg-surface-dim flex items-center gap-1.5">
                <span className="flex-1 text-xs font-semibold text-text-primary truncate">{theme.displayName}</span>
                {isSelected && <Check className="text-accent shrink-0" size={14} />}
              </div>
            </button>
          )
        })}
        {themes.length === 0 && (
          <p className="col-span-full text-center text-sm text-text-muted py-8">
            No themes available. Is the server running?
          </p>
        )}
      </div>
      <div className="flex gap-3 mt-5">
        <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
        <Button className="flex-1" disabled={exporting || themes.length === 0} onClick={confirm}>
          {exporting ? 'Exporting…' : 'Export PPT'}
        </Button>
      </div>
    </Modal>
  )
}
