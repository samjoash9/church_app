import { useState, type FormEvent } from 'react'
import { Button } from '../components/Button'
import { useAuth } from '../auth/AuthContext'

export function LoginPage() {
  const { login } = useAuth()
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    setSubmitting(true)
    try {
      await login(password)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-scaffold px-4">
      <form onSubmit={handleSubmit} className="w-full max-w-sm rounded-2xl border border-border bg-surface p-8">
        <h1 className="mb-1 text-xl font-semibold text-text-primary">Worship Pads</h1>
        <p className="mb-6 text-sm text-text-secondary">Enter the team password to continue.</p>

        <input
          type="password"
          autoFocus
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="Password"
          className="mb-4 w-full rounded-xl border border-border bg-surface-dim px-4 py-2.5 text-sm text-text-primary outline-none focus:border-accent"
        />

        {error && <p className="mb-4 text-sm text-danger">{error}</p>}

        <Button type="submit" disabled={submitting || !password} className="w-full">
          {submitting ? 'Signing in…' : 'Sign in'}
        </Button>
      </form>
    </div>
  )
}
