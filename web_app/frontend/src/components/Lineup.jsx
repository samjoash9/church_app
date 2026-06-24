import { useState, useRef } from 'react';
import './Lineup.css';
import { ALL_KEYS } from '../transposer';
import { exportPdf, exportPpt, downloadBlob } from '../api';

export default function Lineup({
  lineupSongs, allSongs,
  onReorder, onRemove, onClear, onSetLineup, onTransposeSong, onPerform,
}) {
  const [showAddSheet, setShowAddSheet] = useState(false);
  const [showActionModal, setShowActionModal] = useState(null);
  const [showKeyModal, setShowKeyModal] = useState(null);
  const [transposeKey, setTransposeKey] = useState('');
  const [showMenu, setShowMenu] = useState(false);
  const [busy, setBusy] = useState(false);
  const dragIndex = useRef(null);

  const handleDrop = (targetIdx) => {
    const from = dragIndex.current;
    dragIndex.current = null;
    if (from === null || from === targetIdx) return;
    const ids = lineupSongs.map(s => s.id);
    const [moved] = ids.splice(from, 1);
    ids.splice(targetIdx, 0, moved);
    onReorder(ids);
  };

  const doExport = async (kind) => {
    setShowMenu(false);
    if (!lineupSongs.length) return;
    setBusy(true);
    try {
      const ids = lineupSongs.map(s => s.id);
      if (kind === 'pdf' || kind === 'setlist') {
        const blob = await exportPdf(ids);
        downloadBlob(blob, 'Lineup.pdf');
      }
      if (kind === 'ppt' || kind === 'setlist') {
        const blob = await exportPpt(ids, 'dark');
        downloadBlob(blob, 'Lineup.pptx');
      }
    } catch (e) {
      alert('Export failed: ' + e.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="lineup-screen">
      <div className="lib-header">
        <h3>Line up</h3>
        <div className="lineup-header-actions">
          <button className="btn btn-primary" onClick={() => setShowAddSheet(true)}>+ Add Songs</button>
          <div className="menu-wrap">
            <button className="btn-icon" onClick={() => setShowMenu(m => !m)} title="More">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="5" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="12" cy="19" r="2"/></svg>
            </button>
            {showMenu && (
              <div className="menu-dropdown glass-panel" onMouseLeave={() => setShowMenu(false)}>
                <button disabled={!lineupSongs.length} onClick={() => { setShowMenu(false); onPerform(lineupSongs); }}>Perform</button>
                <button disabled={!lineupSongs.length} onClick={() => doExport('pdf')}>Export as PDF</button>
                <button disabled={!lineupSongs.length} onClick={() => doExport('ppt')}>Export as PPT</button>
                <button disabled={!lineupSongs.length} onClick={() => doExport('setlist')}>Export Setlist (PDF + PPT)</button>
                <button className="danger" disabled={!lineupSongs.length} onClick={() => { setShowMenu(false); onClear(); }}>Clear Line up</button>
              </div>
            )}
          </div>
        </div>
      </div>

      {busy && <div className="lineup-busy">Exporting…</div>}

      {lineupSongs.length === 0 ? (
        <div className="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" strokeWidth="1.5"><path d="M3 6h13M3 12h9M3 18h9M17 12l4 2-4 2v-4z"/></svg>
          <h3>Empty Line up</h3>
          <p>Tap "Add Songs" to build your lineup.</p>
        </div>
      ) : (
        <div className="lineup-list">
          {lineupSongs.map((song, idx) => (
            <div
              key={song.id}
              className="lineup-row glass-panel"
              draggable
              onDragStart={() => { dragIndex.current = idx; }}
              onDragOver={e => e.preventDefault()}
              onDrop={() => handleDrop(idx)}
              onClick={() => setShowActionModal(song)}
            >
              <div className="key-badge large">{song.songKey}</div>
              <div className="song-info">
                <span className="song-title">{song.title}</span>
                <span className="song-key">Key of {song.songKey}</span>
              </div>
              <span className="drag-handle" onClick={e => e.stopPropagation()} title="Drag to reorder">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M8 6h.01M8 12h.01M8 18h.01M16 6h.01M16 12h.01M16 18h.01"/></svg>
              </span>
            </div>
          ))}
        </div>
      )}

      {/* Song action modal */}
      {showActionModal && (
        <div className="modal-overlay" onClick={() => setShowActionModal(null)}>
          <div className="modal glass-panel animate-fade-in" onClick={e => e.stopPropagation()}>
            <div className="modal-song-header">
              <div className="key-badge large">{showActionModal.songKey}</div>
              <h3>{showActionModal.title}</h3>
              <p>Key of {showActionModal.songKey}</p>
            </div>
            <div className="action-list">
              <button className="action-btn" onClick={() => { setShowActionModal(null); setTransposeKey(showActionModal.songKey); setShowKeyModal(showActionModal); }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M7 16V4m0 0L3 8m4-4l4 4M17 8v12m0 0l4-4m-4 4l-4-4"/></svg>
                Change Key
              </button>
              <button className="action-btn danger-btn" onClick={() => { onRemove(showActionModal.id); setShowActionModal(null); }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--danger-color)" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12"/></svg>
                Remove from Line up
              </button>
            </div>
            <button className="btn btn-secondary full-width" onClick={() => setShowActionModal(null)}>Back</button>
          </div>
        </div>
      )}

      {/* Change key modal */}
      {showKeyModal && (
        <div className="modal-overlay" onClick={() => setShowKeyModal(null)}>
          <div className="modal glass-panel animate-fade-in" onClick={e => e.stopPropagation()}>
            <h3>Change Key</h3>
            <p className="modal-subtitle">Current key: {showKeyModal.songKey}</p>
            <label>New key</label>
            <select value={transposeKey} onChange={e => setTransposeKey(e.target.value)}>
              {ALL_KEYS.map(k => <option key={k} value={k}>Key of {k}</option>)}
            </select>
            <div className="modal-actions">
              <button className="btn btn-secondary" onClick={() => setShowKeyModal(null)}>Cancel</button>
              <button className="btn btn-primary" disabled={transposeKey === showKeyModal.songKey} onClick={() => { onTransposeSong(showKeyModal.id, transposeKey); setShowKeyModal(null); }}>Save</button>
            </div>
          </div>
        </div>
      )}

      {/* Add songs sheet */}
      {showAddSheet && (
        <AddSongsSheet
          allSongs={allSongs}
          currentIds={lineupSongs.map(s => s.id)}
          onClose={() => setShowAddSheet(false)}
          onConfirm={(ids) => { onSetLineup(ids); setShowAddSheet(false); }}
        />
      )}
    </div>
  );
}

function AddSongsSheet({ allSongs, currentIds, onClose, onConfirm }) {
  const [selected, setSelected] = useState(new Set(currentIds));
  const [query, setQuery] = useState('');

  const filtered = allSongs.filter(s =>
    s.title.toLowerCase().includes(query.toLowerCase()) ||
    s.songKey.toLowerCase().includes(query.toLowerCase())
  );
  const allChecked = filtered.length > 0 && filtered.every(s => selected.has(s.id));

  const toggle = (id) => setSelected(prev => {
    const n = new Set(prev);
    n.has(id) ? n.delete(id) : n.add(id);
    return n;
  });

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal glass-panel add-sheet animate-fade-in" onClick={e => e.stopPropagation()}>
        <h3>Add songs to Line up</h3>
        <div className="search-bar">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input type="text" placeholder="Search songs..." value={query} onChange={e => setQuery(e.target.value)} />
        </div>
        <div className="add-sheet-tools">
          <button className="btn-text" disabled={!filtered.length} onClick={() => setSelected(prev => {
            const n = new Set(prev);
            if (allChecked) filtered.forEach(s => n.delete(s.id));
            else filtered.forEach(s => n.add(s.id));
            return n;
          })}>{allChecked ? 'Uncheck All' : 'Check All'}</button>
          <button className="btn-text" disabled={!selected.size} onClick={() => setSelected(new Set())}>Clear All</button>
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
          <button className="btn btn-primary" onClick={() => onConfirm([...selected])}>Save Line up ({selected.size})</button>
        </div>
      </div>
    </div>
  );
}
