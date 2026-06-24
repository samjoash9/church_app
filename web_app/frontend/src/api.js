const API_BASE = import.meta.env.VITE_API_URL || '';

export async function fetchSongs() {
  const res = await fetch(`${API_BASE}/api/songs`);
  if (!res.ok) throw new Error('Failed to fetch songs');
  return res.json();
}

export async function createSong(song) {
  const res = await fetch(`${API_BASE}/api/songs`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(song),
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.detail || 'Failed to create song');
  }
  return res.json();
}

export async function updateSong(songId, song) {
  const res = await fetch(`${API_BASE}/api/songs/${songId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(song),
  });
  if (!res.ok) throw new Error('Failed to update song');
  return res.json();
}

export async function deleteSong(songId) {
  const res = await fetch(`${API_BASE}/api/songs/${songId}`, { method: 'DELETE' });
  if (!res.ok) throw new Error('Failed to delete song');
  return res.json();
}

export async function fetchLineup() {
  const res = await fetch(`${API_BASE}/api/lineup`);
  if (!res.ok) throw new Error('Failed to fetch lineup');
  return res.json();
}

export async function addToLineup(songId) {
  const res = await fetch(`${API_BASE}/api/lineup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ song_id: songId }),
  });
  if (!res.ok) throw new Error('Failed to add to lineup');
  return res.json();
}

export async function reorderLineup(songIds) {
  const res = await fetch(`${API_BASE}/api/lineup/reorder`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ song_ids: songIds }),
  });
  if (!res.ok) throw new Error('Failed to reorder lineup');
  return res.json();
}

export async function removeFromLineup(itemId) {
  const res = await fetch(`${API_BASE}/api/lineup/${itemId}`, { method: 'DELETE' });
  if (!res.ok) throw new Error('Failed to remove from lineup');
  return res.json();
}

export async function clearLineup() {
  const res = await fetch(`${API_BASE}/api/lineup/clear`, { method: 'DELETE' });
  if (!res.ok) throw new Error('Failed to clear lineup');
  return res.json();
}

// PPT Presentations
export async function fetchPpts() {
  const res = await fetch(`${API_BASE}/api/ppts`);
  if (!res.ok) throw new Error('Failed to fetch PPTs');
  return res.json();
}

export async function createPpt(ppt) {
  const res = await fetch(`${API_BASE}/api/ppts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(ppt),
  });
  if (!res.ok) throw new Error('Failed to create PPT');
  return res.json();
}

export async function updatePpt(pptId, ppt) {
  const res = await fetch(`${API_BASE}/api/ppts/${pptId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(ppt),
  });
  if (!res.ok) throw new Error('Failed to update PPT');
  return res.json();
}

export async function deletePpt(pptId) {
  const res = await fetch(`${API_BASE}/api/ppts/${pptId}`, { method: 'DELETE' });
  if (!res.ok) throw new Error('Failed to delete PPT');
  return res.json();
}

export async function exportPdf(songIds) {
  const res = await fetch(`${API_BASE}/api/export/pdf`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ song_ids: songIds }),
  });
  if (!res.ok) throw new Error('Failed to export PDF');
  return res.blob();
}

export async function exportPpt(songIds, theme = 'dark') {
  const res = await fetch(`${API_BASE}/api/export/ppt`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ song_ids: songIds, theme }),
  });
  if (!res.ok) throw new Error('Failed to export PPT');
  return res.blob();
}

export function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
