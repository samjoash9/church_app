import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { ChevronDown, Check } from 'lucide-react'

export interface SelectOption {
  value: string
  label: string
}

interface SelectProps {
  value: string
  onChange: (value: string) => void
  options: SelectOption[]
  placeholder?: string
  className?: string
  /** 'accent' = compact pill styled like the editor's key selector. */
  variant?: 'default' | 'accent'
}

/**
 * Theme-styled dropdown replacing the native <select>, whose open option list
 * can't be styled cross-browser (renders as an OS-blue popup). Closes on
 * outside click or Escape.
 */
export function Select({ value, onChange, options, placeholder = 'Select…', className = '', variant = 'default' }: SelectProps) {
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const btnRef = useRef<HTMLButtonElement>(null)
  const menuRef = useRef<HTMLDivElement>(null)
  const [pos, setPos] = useState<{ left: number; top: number; width: number; dropUp: boolean }>({ left: 0, top: 0, width: 0, dropUp: false })
  const selected = options.find((o) => o.value === value)
  const isAccent = variant === 'accent'

  // Position the portalled menu against the trigger's viewport rect, flipping
  // above the trigger when there isn't room below.
  useLayoutEffect(() => {
    if (!open || !btnRef.current) return
    const update = () => {
      const rect = btnRef.current!.getBoundingClientRect()
      const menuH = Math.min(240, options.length * 42 + 12)
      const spaceBelow = window.innerHeight - rect.bottom
      const dropUp = spaceBelow < menuH + 12 && rect.top > spaceBelow
      setPos({
        left: rect.left,
        top: dropUp ? rect.top - menuH - 8 : rect.bottom + 8,
        width: rect.width,
        dropUp,
      })
    }
    update()
    window.addEventListener('scroll', update, true)
    window.addEventListener('resize', update)
    return () => {
      window.removeEventListener('scroll', update, true)
      window.removeEventListener('resize', update)
    }
  }, [open, options.length])

  useEffect(() => {
    if (!open) return
    const onClick = (e: MouseEvent) => {
      const t = e.target as Node
      if (ref.current?.contains(t) || menuRef.current?.contains(t)) return
      setOpen(false)
    }
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setOpen(false)
    document.addEventListener('mousedown', onClick)
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onClick)
      document.removeEventListener('keydown', onKey)
    }
  }, [open])

  return (
    <div ref={ref} className={`relative ${className}`}>
      <button
        ref={btnRef}
        type="button"
        onClick={() => setOpen((v) => !v)}
        className={
          isAccent
            ? 'w-full flex items-center justify-between gap-1.5 px-3 py-2 rounded-lg bg-accent-surface/20 border border-accent/40 text-accent font-bold text-sm focus:outline-none'
            : 'w-full flex items-center justify-between gap-2 px-4 py-3 rounded-xl bg-surface-dim border border-border text-left text-text-primary focus:outline-none focus:border-accent transition-colors'
        }
      >
        <span className={selected ? '' : 'text-text-muted'}>{selected?.label ?? placeholder}</span>
        <ChevronDown size={isAccent ? 15 : 18} className={`${isAccent ? 'text-accent' : 'text-text-muted'} transition-transform ${open ? 'rotate-180' : ''}`} />
      </button>
      {open && createPortal(
        <div
          ref={menuRef}
          style={{ position: 'fixed', left: pos.left, top: pos.top, width: pos.width }}
          className="z-[60] max-h-60 overflow-y-auto rounded-xl bg-surface border border-border shadow-2xl py-1.5 animate-fade-in"
        >
          {options.map((opt) => {
            const isSel = opt.value === value
            return (
              <button
                key={opt.value}
                type="button"
                onClick={() => { onChange(opt.value); setOpen(false) }}
                className={`w-full flex items-center justify-between px-4 py-2.5 text-sm text-left transition-colors ${
                  isSel ? 'text-accent font-semibold bg-accent-surface/10' : 'text-text-primary hover:bg-surface-dim'
                }`}
              >
                {opt.label}
                {isSel && <Check size={16} />}
              </button>
            )
          })}
        </div>,
        document.body
      )}
    </div>
  )
}
