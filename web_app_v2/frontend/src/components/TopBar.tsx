import type { ReactNode } from 'react'

export function TopBar({ title, action }: { title: string; action?: ReactNode }) {
  return (
    <header className="flex items-center justify-between h-20 px-5 md:px-8 border-b border-border bg-scaffold/80 backdrop-blur sticky top-0 z-10">
      <h1 className="text-2xl font-extrabold text-text-primary tracking-tight">{title}</h1>
      <div className="flex items-center gap-2">{action}</div>
    </header>
  )
}
