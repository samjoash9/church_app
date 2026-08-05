import type { ReactNode } from 'react'

export function TopBar({ title, action }: { title: string; action?: ReactNode }) {
  return (
    <header className="flex items-center justify-between gap-3 min-h-20 py-3 px-5 md:px-8 border-b border-border bg-scaffold/80 backdrop-blur sticky top-0 z-10">
      <h1 className="text-xl sm:text-2xl font-extrabold text-text-primary tracking-tight shrink-0">{title}</h1>
      <div className="flex items-center flex-wrap justify-end gap-2">{action}</div>
    </header>
  )
}
