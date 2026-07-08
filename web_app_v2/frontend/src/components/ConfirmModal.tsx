import { AlertTriangle } from 'lucide-react'
import { Modal } from './Modal'
import { Button } from './Button'

interface ConfirmModalProps {
  open: boolean
  title: string
  message: string
  confirmLabel?: string
  cancelLabel?: string
  danger?: boolean
  onConfirm: () => void
  onClose: () => void
}

/** Themed confirmation dialog — replaces the browser's native confirm(). */
export function ConfirmModal({
  open,
  title,
  message,
  confirmLabel = 'Delete',
  cancelLabel = 'Cancel',
  danger = true,
  onConfirm,
  onClose,
}: ConfirmModalProps) {
  return (
    <Modal open={open} onClose={onClose} maxWidth="max-w-sm">
      <div className="text-center">
        <div
          className={`w-14 h-14 mx-auto rounded-full flex items-center justify-center mb-4 ${
            danger ? 'bg-danger/15' : 'bg-accent-surface/20'
          }`}
        >
          <AlertTriangle className={danger ? 'text-danger' : 'text-accent'} size={26} />
        </div>
        <h3 className="font-bold text-lg text-text-primary mb-2">{title}</h3>
        <p className="text-sm text-text-secondary mb-6">{message}</p>
        <div className="flex gap-3">
          <Button variant="secondary" className="flex-1" onClick={onClose}>{cancelLabel}</Button>
          <Button
            variant={danger ? 'danger' : 'primary'}
            className="flex-1"
            onClick={() => { onConfirm(); onClose() }}
          >
            {confirmLabel}
          </Button>
        </div>
      </div>
    </Modal>
  )
}
