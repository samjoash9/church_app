import { useState, useRef } from 'react';
import './SongLibrary.css';
import { ALL_KEYS } from '../transposer';
import { exportPdf, downloadBlob } from '../api';

const LANGUAGES = [
  { value: 'bisaya', label: 'Bisaya' },
  { value: 'tagalog', label: 'Tagalog' },
  { value: 'english', label: 'English' },
];

export default function SongLibrary({ songs, onCreateSong, onDeleteSong, onEditSong, onAddToLineup, onTransposeSong, onRenameSong, onMoveSong, onViewSong, onImportSongs }) {
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedFolders, setExpandedFolders] = useState({ bisaya: true, tagalog: true, english: true });
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showActionModal, setShowActionModal] = useState(null);
  const [showRenameModal, setShowRenameModal] = useState(null);
  const [showKeyModal, setShowKeyModal] = useState(null);
  const [showMoveModal, setShowMoveModal] = useState(null);
  const [showMenu, setShowMenu] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newKey, setNewKey] = useState('');
  const [newLanguage, setNewLanguage] = useState('english');
  const [renameTitle, setRenameTitle] = useState('');
  const [transposeKey, setTransposeKey] = useState('');
  const fileInputRef = useRef(null);

  const handleExportJson = () => {
    setShowMenu(false);
    const payload = JSON.stringify(songs, null, 2);
    const blob = new Blob([payload], { type: 'application/json' });
    const ts = new Date().toISOString().replace(/[:.]/g, '-');
    downloadBlob(blob, `songs_export_${ts}.json`);
  };

  const handleExportPdf = async () => {
    setShowMenu(false);
    if (!songs.length) return;
    try {
      const blob = await exportPdf(songs.map(s => s.id));
      downloadBlob(blob, 'chord_charts.pdf');
    } catch (e) {
      alert('PDF export failed: ' + e.message);
    }
  };

  const handleSongPdf = async (song) => {
    setShowActionModal(null);
    try {
      const blob = await exportPdf([song.id]);
      downloadBlob(blob, `${song.title}.pdf`);
    } catch (e) {
      alert('PDF export failed: ' + e.message);
    }
  };

  const handleImportFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = ''; // allow re-importing same file
    if (!file) return;
    try {
      const text = await file.text();
      const decoded = JSON.parse(text);
      const raw = Array.isArray(decoded) ? decoded : [decoded];
      const valid = raw.filter(s => s && typeof s === 'object' && s.id && s.title);
      if (!valid.length) { alert('No valid songs found in that JSON file.'); return; }
      await onImportSongs(valid);
    } catch {
      alert('Import failed. Please choose a valid JSON file.');
    }
  };

  const filtered = songs.filter(s =>
    s.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.songKey.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const toggleFolder = (lang) => {
    setExpandedFolders(prev => ({ ...prev, [lang]: !prev[lang] }));
  };

  const handleCreate = () => {
    if (!newTitle.trim() || !newKey) return;
    onCreateSong({ title: newTitle.trim(), songKey: newKey, language: newLanguage });
    setShowCreateModal(false);
    setNewTitle('');
    setNewKey('');
    setNewLanguage('english');
  };

  const handleRename = () => {
    if (!renameTitle.trim() || renameTitle === showRenameModal.title) return;
    onRenameSong(showRenameModal.id, renameTitle.trim());
    setShowRenameModal(null);
  };

  const handleTranspose = () => {
    if (!transposeKey || transposeKey === showKeyModal.songKey) return;
    onTransposeSong(showKeyModal.id, transposeKey);
    setShowKeyModal(null);
  };

  return (
    <div className="song-library">
      {/* Top Bar */}
      <div className="lib-header">
        <h3>Chords</h3>
        <div className="lib-header-actions">
          <button className="btn btn-primary" onClick={() => setShowCreateModal(true)}>
            + New Song
          </button>
          <div className="menu-wrap">
            <button className="btn-icon" onClick={() => setShowMenu(m => !m)} title="More">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="5" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="12" cy="19" r="2"/></svg>
            </button>
            {showMenu && (
              <div className="menu-dropdown glass-panel" onMouseLeave={() => setShowMenu(false)}>
                <button onClick={() => { setShowMenu(false); fileInputRef.current?.click(); }}>Import Songs</button>
                <button disabled={!songs.length} onClick={handleExportJson}>Export Songs (JSON)</button>
                <button disabled={!songs.length} onClick={handleExportPdf}>Export PDFs</button>
              </div>
            )}
          </div>
        </div>
        <input ref={fileInputRef} type="file" accept=".json,application/json" style={{ display: 'none' }} onChange={handleImportFile} />
      </div>

      {/* Search */}
      {songs.length > 0 && (
        <div className="search-bar">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input
            type="text"
            placeholder="Search songs..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
          />
        </div>
      )}

      {/* Song Folders */}
      {songs.length === 0 ? (
        <div className="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" strokeWidth="1.5"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>
          <h3>No Songs Yet</h3>
          <p>Create your first chord chart to get started.</p>
          <button className="btn btn-primary" onClick={() => setShowCreateModal(true)}>Create New Song</button>
        </div>
      ) : (
        <div className="folders-list">
          {LANGUAGES.map(lang => {
            const langSongs = filtered.filter(s => s.language === lang.value);
            const isExpanded = expandedFolders[lang.value];
            return (
              <div key={lang.value} className="folder">
                <div className="folder-header" onClick={() => toggleFolder(lang.value)}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="var(--primary-color)" stroke="none">
                    {isExpanded
                      ? <path d="M20 19H4a2 2 0 01-2-2V7a2 2 0 012-2h5l2 2h9a2 2 0 012 2v8a2 2 0 01-2 2z"/>
                      : <path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/>
                    }
                  </svg>
                  <span className="folder-name">{lang.label}</span>
                  <span className="folder-count">{langSongs.length}</span>
                  <svg className={`chevron ${isExpanded ? 'open' : ''}`} width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9l6 6 6-6"/></svg>
                </div>
                {isExpanded && (
                  <div className="folder-songs animate-fade-in">
                    {langSongs.length === 0 ? (
                      <p className="no-songs">No songs</p>
                    ) : (
                      langSongs.map(song => (
                        <div key={song.id} className="song-tile" onClick={() => setShowActionModal(song)}>
                          <div className="key-badge">{song.songKey}</div>
                          <div className="song-info">
                            <span className="song-title">{song.title}</span>
                            <span className="song-key">Key of {song.songKey}</span>
                          </div>
                          <button className="btn-icon delete-btn" onClick={(e) => { e.stopPropagation(); onDeleteSong(song.id); }}>
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--danger-color)" strokeWidth="2"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>
                          </button>
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Create Song Modal */}
      {showCreateModal && (
        <div className="modal-overlay" onClick={() => setShowCreateModal(false)}>
          <div className="modal glass-panel animate-fade-in" onClick={e => e.stopPropagation()}>
            <h3>Create New Song</h3>
            <label>Title</label>
            <input type="text" placeholder="e.g. Amazing Grace" value={newTitle} onChange={e => setNewTitle(e.target.value)} autoFocus />
            <label>Key</label>
            <select value={newKey} onChange={e => setNewKey(e.target.value)}>
              <option value="">Select a key</option>
              {ALL_KEYS.map(k => <option key={k} value={k}>{k} Major</option>)}
            </select>
            <label>Language</label>
            <select value={newLanguage} onChange={e => setNewLanguage(e.target.value)}>
              {LANGUAGES.map(l => <option key={l.value} value={l.value}>{l.label}</option>)}
            </select>
            <div className="modal-actions">
              <button className="btn btn-secondary" onClick={() => setShowCreateModal(false)}>Cancel</button>
              <button className="btn btn-primary" onClick={handleCreate} disabled={!newTitle.trim() || !newKey}>Create</button>
            </div>
          </div>
        </div>
      )}

      {/* Song Action Modal */}
      {showActionModal && (
        <div className="modal-overlay" onClick={() => setShowActionModal(null)}>
          <div className="modal glass-panel animate-fade-in" onClick={e => e.stopPropagation()}>
            <div className="modal-song-header">
              <div className="key-badge large">{showActionModal.songKey}</div>
              <h3>{showActionModal.title}</h3>
              <p>Key of {showActionModal.songKey}</p>
            </div>
            <div className="action-list">
              <button className="action-btn primary" onClick={() => { setShowActionModal(null); onViewSong(showActionModal); }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                Overview
              </button>
              <button className="action-btn" onClick={() => { setShowActionModal(null); onEditSong(showActionModal); }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                Edit Song
              </button>
              <button className="action-btn" onClick={() => { setShowActionModal(null); setTransposeKey(showActionModal.songKey); setShowKeyModal(showActionModal); }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M7 16V4m0 0L3 8m4-4l4 4M17 8v12m0 0l4-4m-4 4l-4-4"/></svg>
                Change Key
              </button>
              <button className="action-btn" onClick={() => { onAddToLineup(showActionModal.id); setShowActionModal(null); }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 5v14M5 12h14"/></svg>
                Add to Lineup
              </button>
              <button className="action-btn" onClick={() => { setShowActionModal(null); setRenameTitle(showActionModal.title); setShowRenameModal(showActionModal); }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 3a2.828 2.828 0 114 4L7.5 20.5 2 22l1.5-5.5L17 3z"/></svg>
                Rename
              </button>
              <button className="action-btn" onClick={() => { setShowActionModal(null); setShowMoveModal(showActionModal); }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>
                Move to Folder
              </button>
              <button className="action-btn" onClick={() => handleSongPdf(showActionModal)}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><path d="M14 2v6h6"/></svg>
                Export as PDF
              </button>
            </div>
            <button className="btn btn-secondary full-width" onClick={() => setShowActionModal(null)}>Back</button>
          </div>
        </div>
      )}

      {/* Rename Modal */}
      {showRenameModal && (
        <div className="modal-overlay" onClick={() => setShowRenameModal(null)}>
          <div className="modal glass-panel animate-fade-in" onClick={e => e.stopPropagation()}>
            <h3>Rename Song</h3>
            <input type="text" value={renameTitle} onChange={e => setRenameTitle(e.target.value)} autoFocus />
            <div className="modal-actions">
              <button className="btn btn-secondary" onClick={() => setShowRenameModal(null)}>Cancel</button>
              <button className="btn btn-primary" onClick={handleRename}>Save</button>
            </div>
          </div>
        </div>
      )}

      {/* Change Key Modal */}
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
              <button className="btn btn-primary" onClick={handleTranspose} disabled={transposeKey === showKeyModal.songKey}>Save</button>
            </div>
          </div>
        </div>
      )}

      {/* Move to Folder Modal */}
      {showMoveModal && (
        <div className="modal-overlay" onClick={() => setShowMoveModal(null)}>
          <div className="modal glass-panel animate-fade-in" onClick={e => e.stopPropagation()}>
            <h3>Move to Folder</h3>
            <div className="action-list">
              {LANGUAGES.map(lang => (
                <button
                  key={lang.value}
                  className={`action-btn ${showMoveModal.language === lang.value ? 'active' : ''}`}
                  onClick={() => { onMoveSong(showMoveModal.id, lang.value); setShowMoveModal(null); }}
                  disabled={showMoveModal.language === lang.value}
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>
                  {lang.label}
                  {showMoveModal.language === lang.value && <span className="check-icon">✓</span>}
                </button>
              ))}
            </div>
            <button className="btn btn-secondary full-width" onClick={() => setShowMoveModal(null)}>Cancel</button>
          </div>
        </div>
      )}
    </div>
  );
}
