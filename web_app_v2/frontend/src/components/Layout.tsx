import type { ReactNode } from 'react'
import { Sidebar } from './Sidebar'
import { MobileNav } from './MobileNav'

export function Layout({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen bg-scaffold">
      <Sidebar />
      <div className="flex-1 min-w-0 pb-16 md:pb-0">{children}</div>
      <MobileNav />
    </div>
  )
}
