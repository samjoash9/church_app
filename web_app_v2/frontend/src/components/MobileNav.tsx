import { NavLink } from 'react-router-dom'
import { Music2, ListMusic, FileText, Settings } from 'lucide-react'

const NAV_ITEMS = [
  { to: '/chords', label: 'Chords', icon: Music2 },
  { to: '/lineup', label: 'Line up', icon: ListMusic },
  { to: '/ppt', label: 'PPT', icon: FileText },
  { to: '/settings', label: 'Settings', icon: Settings },
]

export function MobileNav() {
  return (
    <nav className="md:hidden fixed bottom-0 inset-x-0 z-30 bg-drawer-bg border-t border-border flex items-stretch pb-[env(safe-area-inset-bottom)]">
      {NAV_ITEMS.map(({ to, label, icon: Icon }) => (
        <NavLink
          key={to}
          to={to}
          className={({ isActive }) =>
            `flex-1 flex flex-col items-center justify-center gap-1 py-2.5 text-[11px] font-medium transition-colors ${
              isActive ? 'text-accent' : 'text-text-muted'
            }`
          }
        >
          <Icon size={20} />
          {label}
        </NavLink>
      ))}
    </nav>
  )
}
