import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { auth as authApi, setUnauthorizedHandler } from '../api/client'

interface AuthContextValue {
  authenticated: boolean
  loading: boolean
  login: (password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [authenticated, setAuthenticated] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setUnauthorizedHandler(() => setAuthenticated(false))
    authApi
      .status()
      .then((res) => setAuthenticated(res.authenticated))
      .finally(() => setLoading(false))
  }, [])

  const login = async (password: string) => {
    await authApi.login(password)
    setAuthenticated(true)
  }

  const logout = async () => {
    await authApi.logout().catch(() => {})
    setAuthenticated(false)
  }

  return (
    <AuthContext.Provider value={{ authenticated, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
