import { useState, useEffect, useCallback } from 'react';
import './PerformMode.css';

const SECTIONS = ['Full', 'Verse', 'Second Verse', 'Pre-Chorus', 'Chorus', 'Second Chorus', 'Bridge'];

export default function PerformMode({ songs, initialIndex = 0, onClose }) {
  const [index, setIndex] = useState(Math.min(initialIndex, Math.max(0, songs.length - 1)));
  const [filter, setFilter] = useState('Full');

  const goTo = useCallback((i) => {
    if (i < 0 || i >= songs.length) return;
    setIndex(i);
    setFilter('Full');
  }, [songs.length]);

  useEffect(() => {
    const onKey = (e) => {
      if (e.key === 'ArrowRight' || e.key === 'PageDown') goTo(index + 1);
      else if (e.key === 'ArrowLeft' || e.key === 'PageUp') goTo(index - 1);
      else if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [index, goTo, onClose]);

  if (!songs.length) {
    return (
      <div className="perform-screen">
        <button className="perform-close" onClick={onClose}>✕</button>
        <div className="perform-empty">No songs to perform</div>
      </div>
    );
  }

  const song = songs[index];
  const lines = song.lines || [];

  // Which section labels actually exist in this song (for filter chips)
  const availableSections = SECTIONS.filter(sec => {
    if (sec === 'Full') return true;
    return lines.some(l => {
      const t = (l.lyrics || '').trim();
      return t.startsWith('[') && t.endsWith(']') &&
        t.slice(1, -1).trim().toLowerCase() === sec.toLowerCase();
    });
  });

  let displayed = [];
  if (filter === 'Full') {
    displayed = lines;
  } else {
    let inTarget = false;
    for (const line of lines) {
      const t = (line.lyrics || '').trim();
      if (t.startsWith('[') && t.endsWith(']')) {
        const name = t.slice(1, -1).trim();
        inTarget = name.toLowerCase() === filter.toLowerCase();
        if (inTarget) displayed.push(line);
      } else if (inTarget) {
        displayed.push(line);
      }
    }
  }

  return (
    <div className="perform-screen animate-fade-in">
      <div className="perform-topbar">
        <button className="perform-close" onClick={onClose} title="Exit (Esc)">✕</button>
        <div className="perform-title">
          <div className="perform-song-name">{song.title}</div>
          <div className="perform-counter">{index + 1} of {songs.length}</div>
        </div>
        <div style={{ width: 40 }} />
      </div>

      {songs.length > 1 && (
        <div className="perform-dots">
          {songs.map((_, i) => (
            <span key={i} className={`perform-dot ${i === index ? 'active' : ''}`} onClick={() => goTo(i)} />
          ))}
        </div>
      )}

      <div className="perform-keybar">Key of {song.songKey}</div>

      {availableSections.length > 1 && (
        <div className="perform-filters">
          {availableSections.map(sec => (
            <button
              key={sec}
              className={`perform-chip ${filter === sec ? 'active' : ''}`}
              onClick={() => setFilter(sec)}
            >
              {sec}
            </button>
          ))}
        </div>
      )}

      <div className="perform-body">
        {displayed.map((line, idx) => {
          const lyrics = line.lyrics || '';
          const chords = line.chords || [];
          if (!lyrics.trim() && chords.every(c => !c)) return <div key={idx} className="perform-spacer" />;
          const isSection = lyrics.trim().startsWith('[') && lyrics.trim().endsWith(']');
          if (isSection) return <div key={idx} className="perform-section">{lyrics.replace(/[[\]]/g, '')}</div>;
          const active = chords.filter(c => c);
          return (
            <div key={idx} className="perform-line">
              {active.length > 0 && (
                <div className="perform-chords">
                  {active.map((c, i) => <span key={i} className="perform-chord">{c}</span>)}
                </div>
              )}
              {lyrics.trim() && <div className="perform-lyric">{lyrics}</div>}
            </div>
          );
        })}
      </div>

      <button className="perform-nav prev" disabled={index === 0} onClick={() => goTo(index - 1)} title="Previous (←)">‹</button>
      <button className="perform-nav next" disabled={index === songs.length - 1} onClick={() => goTo(index + 1)} title="Next (→)">›</button>
    </div>
  );
}
