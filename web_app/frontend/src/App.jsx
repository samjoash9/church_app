import { useState, useEffect, useCallback } from 'react';
import './App.css';
import WorshipPads from './components/WorshipPads';
import SongLibrary from './components/SongLibrary';
import SongEditor from './components/SongEditor';
import SongOverview from './components/SongOverview';
import Lineup from './components/Lineup';
import PptScreen from './components/PptScreen';
import PerformMode from './components/PerformMode';
import * as api from './api';
import { semitonesBetween, prefersFlats, transposeChord } from './transposer';

const TABS = [
  { id: 'pads', label: 'Pads' },
  { id: 'songs', label: 'Chords' },
  { id: 'lineup', label: 'Lineup' },
  { id: 'ppt', label: 'PPT' },
];

function App() {
  const [activeTab, setActiveTab] = useState('pads');
  const [songs, setSongs] = useState([]);
  const [lineup, setLineup] = useState([]); // [{id, order_index, song_id}]
  const [ppts, setPpts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Overlay screens (full-screen, sit above the tab content)
  const [editing, setEditing] = useState(null);   // song object or {} for new
  const [viewing, setViewing] = useState(null);    // song object (overview)
  const [performing, setPerforming] = useState(null); // array of songs

  const loadAll = useCallback(async () => {
    setLoading(true);
    try {
      const [s, l, p] = await Promise.all([api.fetchSongs(), api.fetchLineup(), api.fetchPpts()]);
      setSongs(s);
      setLineup(l);
      setPpts(p);
      setError(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadAll(); }, [loadAll]);

  // ── Song operations ───────────────────────────────────────────────
  const saveSong = async (song) => {
    const exists = songs.some(s => s.id === song.id);
    try {
      if (exists) await api.updateSong(song.id, song);
      else await api.createSong(song);
      const fresh = await api.fetchSongs();
      setSongs(fresh);
    } catch (e) {
      alert('Save failed: ' + e.message);
    }
  };

  const createSong = (data) => {
    // Opens the editor on a brand-new blank song (saved when user hits Save).
    setEditing({
      id: Date.now().toString(),
      title: data.title,
      songKey: data.songKey,
      language: data.language || 'english',
      lines: [],
    });
  };

  const deleteSong = async (id) => {
    if (!confirm('Delete this song?')) return;
    await api.deleteSong(id);
    setSongs(prev => prev.filter(s => s.id !== id));
    setLineup(prev => prev.filter(l => l.song_id !== id));
  };

  const renameSong = async (id, title) => {
    const song = songs.find(s => s.id === id);
    if (!song) return;
    await saveSong({ ...song, title });
  };

  const moveSong = async (id, language) => {
    const song = songs.find(s => s.id === id);
    if (!song) return;
    await saveSong({ ...song, language });
  };

  const transposeSong = async (id, targetKey) => {
    const song = songs.find(s => s.id === id);
    if (!song) return;
    const semis = semitonesBetween(song.songKey, targetKey);
    const flats = prefersFlats(targetKey);
    const transposed = {
      ...song,
      songKey: targetKey,
      lines: song.lines.map(line => ({
        lyrics: line.lyrics,
        chords: line.chords.map(c => transposeChord(c, semis, flats)),
      })),
    };
    await saveSong(transposed);
  };

  const importSongs = async (incoming) => {
    let count = 0;
    for (const raw of incoming) {
      try {
        await saveSong({
          id: String(raw.id),
          title: raw.title,
          songKey: raw.songKey || 'C',
          language: raw.language || 'english',
          lines: raw.lines || [],
        });
        count++;
      } catch { /* skip bad row */ }
    }
    const fresh = await api.fetchSongs();
    setSongs(fresh);
    alert(`${count} song${count === 1 ? '' : 's'} imported.`);
  };

  // ── Lineup operations ─────────────────────────────────────────────
  const lineupSongs = lineup
    .map(l => songs.find(s => s.id === l.song_id))
    .filter(Boolean);

  const addToLineup = async (songId) => {
    await api.addToLineup(songId);
    setLineup(await api.fetchLineup());
  };

  const setLineupSongs = async (songIds) => {
    // Diff against current lineup: add new, remove dropped.
    const current = lineup;
    const currentIds = new Set(current.map(l => l.song_id));
    const wanted = new Set(songIds);
    for (const id of songIds) {
      if (!currentIds.has(id)) await api.addToLineup(id);
    }
    for (const l of current) {
      if (!wanted.has(l.song_id)) await api.removeFromLineup(l.id);
    }
    // Apply explicit order
    await api.reorderLineup(songIds);
    setLineup(await api.fetchLineup());
  };

  const reorderLineup = async (songIds) => {
    // Optimistic: reflect new order immediately, then persist.
    setLineup(prev => songIds.map((sid, idx) => {
      const entry = prev.find(l => l.song_id === sid);
      return { ...entry, order_index: idx };
    }));
    await api.reorderLineup(songIds);
  };

  const removeFromLineup = async (songId) => {
    const entry = lineup.find(l => l.song_id === songId);
    if (!entry) return;
    await api.removeFromLineup(entry.id);
    setLineup(prev => prev.filter(l => l.id !== entry.id));
  };

  const clearLineup = async () => {
    if (!confirm('Clear the entire lineup?')) return;
    await api.clearLineup();
    setLineup([]);
  };

  // ── PPT operations ────────────────────────────────────────────────
  const createPpt = async (data) => {
    await api.createPpt(data);
    setPpts(await api.fetchPpts());
  };
  const updatePpt = async (id, data) => {
    await api.updatePpt(id, data);
    setPpts(await api.fetchPpts());
  };
  const deletePpt = async (id) => {
    if (!confirm('Delete this presentation?')) return;
    await api.deletePpt(id);
    setPpts(prev => prev.filter(p => p.id !== id));
  };

  // ── Full-screen overlays ──────────────────────────────────────────
  if (performing) {
    return <PerformMode songs={performing} onClose={() => setPerforming(null)} />;
  }

  return (
    <div className="app-container">
      <header className="glass-panel app-header">
        <div className="logo">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M9 18V5l12-2v13"></path>
            <circle cx="6" cy="18" r="3"></circle>
            <circle cx="18" cy="16" r="3"></circle>
          </svg>
          <h2>Worship Pads</h2>
        </div>
        <nav className="nav-tabs">
          {TABS.map(t => (
            <button
              key={t.id}
              className={`tab-btn ${activeTab === t.id ? 'active' : ''}`}
              onClick={() => setActiveTab(t.id)}
            >
              {t.label}
            </button>
          ))}
        </nav>
      </header>

      <main className="main-content animate-fade-in">
        {loading && <div className="app-status">Loading…</div>}
        {error && <div className="app-status error">Failed to connect to server: {error}</div>}

        {!loading && (
          <>
            {/* Editor / Overview overlays render in place of tab content */}
            {editing ? (
              <SongEditor
                song={editing}
                onSave={async (s) => { await saveSong(s); setEditing(null); }}
                onClose={() => setEditing(null)}
              />
            ) : viewing ? (
              <SongOverview
                song={viewing}
                onClose={() => setViewing(null)}
                onEdit={(s) => { setViewing(null); setEditing(s); }}
              />
            ) : (
              <>
                {activeTab === 'pads' && <WorshipPads />}

                {activeTab === 'songs' && (
                  <SongLibrary
                    songs={songs}
                    onCreateSong={createSong}
                    onDeleteSong={deleteSong}
                    onEditSong={(s) => setEditing(s)}
                    onViewSong={(s) => setViewing(s)}
                    onAddToLineup={addToLineup}
                    onTransposeSong={transposeSong}
                    onRenameSong={renameSong}
                    onMoveSong={moveSong}
                    onImportSongs={importSongs}
                  />
                )}

                {activeTab === 'lineup' && (
                  <Lineup
                    lineupSongs={lineupSongs}
                    allSongs={songs}
                    onReorder={reorderLineup}
                    onRemove={removeFromLineup}
                    onClear={clearLineup}
                    onSetLineup={setLineupSongs}
                    onTransposeSong={transposeSong}
                    onPerform={(list) => setPerforming(list)}
                  />
                )}

                {activeTab === 'ppt' && (
                  <PptScreen
                    ppts={ppts}
                    songs={songs}
                    onCreatePpt={createPpt}
                    onUpdatePpt={updatePpt}
                    onDeletePpt={deletePpt}
                  />
                )}
              </>
            )}
          </>
        )}
      </main>
    </div>
  );
}

export default App;
