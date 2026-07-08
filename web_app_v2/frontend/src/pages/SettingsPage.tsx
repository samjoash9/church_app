import { Moon, Sun, Info, LogOut } from 'lucide-react'
import { TopBar } from '../components/TopBar'
import { useTheme } from '../theme/ThemeContext'
import { useAuth } from '../auth/AuthContext'

export function SettingsPage() {
  const { mode, setMode } = useTheme()
  const { logout } = useAuth()

  return (
    <div>
      <TopBar title="Settings" />
      <div className="p-5 md:p-8 max-w-2xl mx-auto space-y-3">
        <div className="rounded-xl bg-surface border-l-4 border-border px-5 py-5">
          <p className="font-bold text-text-primary mb-1">Theme</p>
          <p className="text-xs text-text-muted mb-4">Customize app appearance</p>
          <div className="flex gap-2">
            <button
              onClick={() => setMode('dark')}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-lg text-sm font-semibold transition-colors ${
                mode === 'dark' ? 'bg-accent text-on-accent' : 'bg-surface-dim text-text-secondary'
              }`}
            >
              <Moon size={16} /> Dark
            </button>
            <button
              onClick={() => setMode('light')}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-lg text-sm font-semibold transition-colors ${
                mode === 'light' ? 'bg-accent text-on-accent' : 'bg-surface-dim text-text-secondary'
              }`}
            >
              <Sun size={16} /> Light
            </button>
          </div>
        </div>

        <div className="rounded-xl bg-surface border-l-4 border-border px-5 py-5 flex items-center gap-3">
          <Info className="text-text-muted shrink-0" size={20} />
          <div>
            <p className="font-bold text-text-primary">About</p>
            <p className="text-xs text-text-muted">Worship Pads Web · v1.0.0</p>
          </div>
        </div>

        <button
          onClick={logout}
          className="w-full flex items-center gap-3 rounded-xl bg-surface border-l-4 border-danger/50 px-5 py-5 text-danger font-bold hover:bg-danger/5 transition-colors"
        >
          <LogOut size={20} />
          Sign out
        </button>
      </div>
    </div>
  )
}
