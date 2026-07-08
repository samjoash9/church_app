import type { Song, LineupItem, Ppt, SoundEntry } from '../types'

const BASE = '/api'

async function req<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: options?.body instanceof FormData ? undefined : { 'Content-Type': 'application/json' },
    ...options,
  })
  if (!res.ok) {
    const detail = await res.json().catch(() => ({}))
    throw new Error(detail.detail || `Request failed: ${res.status}`)
  }
  if (res.status === 204) return undefined as T
  return res.json()
}

export const api = {
  songs: {
    list: () => req<Song[]>('/songs'),
    create: (song: Song) => req<Song>('/songs', { method: 'POST', body: JSON.stringify(song) }),
    update: (id: string, song: Song) => req<Song>(`/songs/${id}`, { method: 'PUT', body: JSON.stringify(song) }),
    remove: (id: string) => req<void>(`/songs/${id}`, { method: 'DELETE' }),
  },
  lineup: {
    list: () => req<LineupItem[]>('/lineup'),
    add: (song_id: string) => req<LineupItem>('/lineup', { method: 'POST', body: JSON.stringify({ song_id }) }),
    reorder: (song_ids: string[]) => req<void>('/lineup/reorder', { method: 'PUT', body: JSON.stringify({ song_ids }) }),
    clear: () => req<void>('/lineup/clear', { method: 'DELETE' }),
    remove: (itemId: number) => req<void>(`/lineup/${itemId}`, { method: 'DELETE' }),
  },
  ppts: {
    list: () => req<Ppt[]>('/ppts'),
    create: (ppt: Ppt) => req<Ppt>('/ppts', { method: 'POST', body: JSON.stringify(ppt) }),
    update: (id: string, ppt: Ppt) => req<Ppt>(`/ppts/${id}`, { method: 'PUT', body: JSON.stringify(ppt) }),
    remove: (id: string) => req<void>(`/ppts/${id}`, { method: 'DELETE' }),
  },
  sounds: {
    list: () => req<SoundEntry[]>('/sounds'),
    upload: (mode: string, key: string, file: File) => {
      const form = new FormData()
      form.append('mode', mode)
      form.append('key', key)
      form.append('file', file)
      return req<SoundEntry>('/sounds/upload', { method: 'POST', body: form })
    },
    remove: (id: number) => req<void>(`/sounds/${id}`, { method: 'DELETE' }),
    activate: (id: number) => req<SoundEntry>(`/sounds/${id}/activate`, { method: 'PUT' }),
    clearActive: (mode: string, key: string) => req<void>(`/sounds/${mode}/${encodeURIComponent(key)}/clear-active`, { method: 'PUT' }),
  },
  exportPdf: async (songIds: string[]): Promise<Blob> => {
    const res = await fetch(`${BASE}/export/pdf`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ song_ids: songIds }),
    })
    if (!res.ok) throw new Error('PDF export failed')
    return res.blob()
  },
  pptThemes: () => req<{ id: string; displayName: string; preview: string }[]>('/ppt-themes'),
  exportPpt: async (songIds: string[], theme: string): Promise<Blob> => {
    const res = await fetch(`${BASE}/export/ppt`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ song_ids: songIds, theme }),
    })
    if (!res.ok) throw new Error('PPT export failed')
    return res.blob()
  },
}

export function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  URL.revokeObjectURL(url)
}
