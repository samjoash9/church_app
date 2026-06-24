import { useState } from 'react';
import './PptScreen.css';
import { exportPpt, downloadBlob } from '../api';

const THEMES = [
  { id: 'dark', label: 'Dark' },
  { id: 'light', label: 'Light' },
];

export default function PptScreen({ ppts, songs, onCreatePpt, onUpdatePpt, onDeletePpt }) {
  const [searchQuery, setSearchQuery] = useState('');
  const [showEditor, setShowEditor] = useState(null); // null | {} (new) | ppt (edit)
  const [showThemePicker, setShowThemePicker] = useState(null); // ppt to export
  const [exporting, setExporting] = useState(false);

  const songById = (id) => songs.find(s => s.id === id);

  const filtered = ppts.filter(p => p.title.toLowerCase().includes(searchQuery.toLowerCase()));

  const handleExport = async (ppt, theme) => {
    setExporting(true);
    try {
      const blob = await exportPpt(ppt.song_ids, theme);
      downloadBlob(blob, `${ppt.title}.pptx`);
    } catch (e) {
      alert('Export failed: ' + e.message);
    } finally {
      setExporting(false);
      setShowThemePicker(null);
    }
  };

  return (
    <div className="ppt-screen">
      <div className="lib-header">
        <h3>Presentations</h3>
        <button className="btn btn-primary" onClick={() => setShowEditor({ title: '', song_ids: [] })}>
          + New PPT
        </button>
      </div>

      {ppts.length > 0 && (
        <div className="search-bar">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input type="text" placeholder="Search presentations..." value={searchQuery} onChange={e => setSearchQuery(e.target.value)} />
        </div>
      )}

      {ppts.length === 0 ? (
        <div className="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" strokeWidth="1.5"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>
          <h3>No Presentations</h3>
          <p>Create a presentation from your songs and export to PowerPoint.</p>
          <button className="btn btn-primary" onClick={() => setShowEditor({ title: '', song_ids: [] })}>Create Presentation</button>
        </div>
      ) : (
        <div className="ppt-list">
          {filtered.map(ppt => (
            <div key={ppt.id} className="ppt-card glass-panel">
              <div className="ppt-card-info">
                <span className="ppt-card-title">{ppt.title}</span>
                <span className="ppt-card-meta">{ppt.song_ids.length} song{ppt.song_ids.length === 1 ? '' : 's'}</span>
              </div>
              <div className="ppt-card-actions">
                <button className="btn btn-secondary" onClick={() => setShowThemePicker(ppt)} disabled={!ppt.song_ids.length}>Export</button>
                <button className="btn-icon" onClick={() => setShowEditor(ppt)} title="Edit">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
                <button className="btn-icon" onClick={() => onDeletePpt(ppt.id)} title="Delete">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--danger-color)" strokeWidth="2"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6"/></svg>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showEditor && (
        <PptEditor
          ppt={showEditor}
          songs={songs}
          onClose={() => setShowEditor(null)}
          onSave={(data) => {
            if (showEditor.id) onUpdatePpt(showEditor.id, data);
            else onCreatePpt(data);
            setShowEditor(null);
          }}
        />
      )}

      {showThemePicker && (
        <div className="modal-overlay" onClick={() => !exporting && setShowThemePicker(null)}>
          <div className="modal glass-panel animate-fade-in" onClick={e => e.stopPropagation()}>
            <h3>Choose a Theme</h3>
            <p className="modal-subtitle">Select the design for your slides.</p>
            <div className="theme-grid">
              {THEMES.map(t => (
                <button key={t.id} className="theme-card" disabled={exporting} onClick={() => handleExport(showThemePicker, t.id)}>
                  <div className={`theme-preview theme-${t.id}`}>Aa</div>
                  <span>{t.label}</span>
                </button>
              ))}
            </div>
            <button className="btn btn-secondary full-width" disabled={exporting} onClick={() => setShowThemePicker(null)}>
              {exporting ? 'Exporting…' : 'Cancel'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function PptEditor({ ppt, songs, onClose, onSave }) {
  const [title, setTitle] = useState(ppt.title || '');
  const [selected, setSelected] = useState(new Set(ppt.song_ids || []));
  const [query, setQuery] = useState('');

  const filtered = songs.filter(s =>
    s.title.toLowerCase().includes(query.toLowerCase()) ||
    s.songKey.toLowerCase().includes(query.toLowerCase())
  );

  const toggle = (id) => {
    setSelected(prev => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const handleSave = () => {
    if (!title.trim()) return;
    // Preserve original order where possible, append new selections.
    const ordered = (ppt.song_ids || []).filter(id => selected.has(id));
    songs.forEach(s => { if (selected.has(s.id) && !ordered.includes(s.id)) ordered.push(s.id); });
    onSave({ id: ppt.id || Date.now().toString(), title: title.trim(), song_ids: ordered });
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal glass-panel ppt-editor-modal animate-fade-in" onClick={e => e.stopPropagation()}>
        <h3>{ppt.id ? 'Edit Presentation' : 'New Presentation'}</h3>
        <label>Title</label>
        <input type="text" placeholder="e.g. Sunday Service" value={title} onChange={e => setTitle(e.target.value)} autoFocus />

        <label>Songs ({selected.size} selected)</label>
        <div className="search-bar">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input type="text" placeholder="Search songs..." value={query} onChange={e => setQuery(e.target.value)} />
        </div>

        <div className="ppt-song-picker">
          {filtered.length === 0 ? (
            <p className="no-songs">No songs found</p>
          ) : filtered.map(song => (
            <div key={song.id} className={`ppt-pick-row ${selected.has(song.id) ? 'checked' : ''}`} onClick={() => toggle(song.id)}>
              <div className="key-badge">{song.songKey}</div>
              <div className="song-info">
                <span className="song-title">{song.title}</span>
                <span className="song-key">Key of {song.songKey}</span>
              </div>
              <input type="checkbox" readOnly checked={selected.has(song.id)} />
            </div>
          ))}
        </div>

        <div className="modal-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={handleSave} disabled={!title.trim()}>Save</button>
        </div>
      </div>
    </div>
  );
}
