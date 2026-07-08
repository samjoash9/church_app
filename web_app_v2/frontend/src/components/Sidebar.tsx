import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { Music2, ListMusic, FileText, Settings, Sparkles, PanelLeftClose, PanelLeftOpen } from 'lucide-react'

const NAV_ITEMS = [
  { to: '/chords', label: 'Chords', icon: Music2 },
  { to: '/lineup', label: 'Line up', icon: ListMusic },
  { to: '/ppt', label: 'PPT', icon: FileText },
  { to: '/settings', label: 'Settings', icon: Settings },
]

const STORAGE_KEY = 'sidebar-collapsed'

export function Sidebar() {
  const [collapsed, setCollapsed] = useState(() => localStorage.getItem(STORAGE_KEY) === '1')

  function toggle() {
    setCollapsed((c) => {
      localStorage.setItem(STORAGE_KEY, c ? '0' : '1')
      return !c
    })
  }

  return (
    <aside
      className={`hidden md:flex shrink-0 flex-col bg-drawer-bg border-r border-border h-screen sticky top-0 transition-[width] duration-200 ${
        collapsed ? 'w-20' : 'w-64'
      }`}
    >
      <div className={`flex items-center h-20 shrink-0 ${collapsed ? 'justify-center px-2' : 'justify-between px-6'}`}>
        {!collapsed && (
          <div className="flex items-center gap-2 min-w-0">
            <Sparkles className="text-accent shrink-0" size={22} />
            <span className="text-lg font-bold text-text-primary tracking-tight truncate">Worship Pads</span>
          </div>
        )}
        <button
          onClick={toggle}
          title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          className="p-2 rounded-lg text-text-secondary hover:bg-drawer-selected/60 hover:text-text-primary shrink-0"
        >
          {collapsed ? <PanelLeftOpen size={20} /> : <PanelLeftClose size={20} />}
        </button>
      </div>
      <nav className="flex-1 px-3 py-2 space-y-1">
        {NAV_ITEMS.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            title={collapsed ? label : undefined}
            className={({ isActive }) =>
              `flex items-center gap-3 py-3 rounded-xl text-sm font-medium transition-colors ${
                collapsed ? 'justify-center px-0' : 'px-4'
              } ${
                isActive
                  ? 'bg-drawer-selected text-text-primary'
                  : 'text-text-secondary hover:bg-drawer-selected/60 hover:text-text-primary'
              }`
            }
          >
            <Icon size={19} className="shrink-0" />
            {!collapsed && label}
          </NavLink>
        ))}
      </nav>
      {!collapsed && (
        <div className="px-6 py-5 text-xs text-text-muted border-t border-border">
          Worship Pads Web · v1.0
        </div>
      )}
    </aside>
  )
}
