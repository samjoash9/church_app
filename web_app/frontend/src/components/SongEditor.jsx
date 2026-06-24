import { useState, useEffect } from 'react';
import './SongEditor.css';
import { KEY_CHORDS, ALL_KEYS } from '../transposer';

const SECTIONS = ['Verse', 'Second Verse', 'Pre-Chorus', 'Chorus', 'Second Chorus', 'Bridge'];

export default function SongEditor({ song, onSave, onClose }) {
  const [currentMode, setCurrentMode] = useState('lyrics'); // 'lyrics' | 'chords' | 'view'
  const [currentKey, setCurrentKey] = useState(song?.songKey || 'C');
  const [title] = useState(song?.title || 'Untitled');
  const [sections, setSections] = useState(() => initSections(song));
  const [lines, setLines] = useState(() => song?.lines || []);
  const [picker, setPicker] = useState(null); // { lineIdx, slotIdx } | null

  function initSections(s) {
    const secs = SECTIONS.map(t => ({ title: t, text: '', expanded: false }));
    if (!s || !s.lines || s.lines.length === 0) {
      secs[0].expanded = true;
      return secs;
    }
    // Parse lines into sections
    let currentSection = null;
    let currentLines = [];

    function saveSection() {
      if (currentSection) {
        const existing = currentSection.text;
        const newText = currentLines.join('\n').trim();
        if (existing && newText) currentSection.text = `${existing}\n\n${newText}`;
        else if (newText) currentSection.text = newText;
        if (currentSection.text) currentSection.expanded = true;
      } else if (currentLines.length > 0) {
        const newText = currentLines.join('\n').trim();
        if (newText) { secs[0].text = newText; secs[0].expanded = true; }
      }
      currentLines = [];
    }

    for (const line of s.lines) {
      const text = line.lyrics.trim();
      const clean = text.replace(/\[|\]/g, '').trim().toLowerCase();
      const matched = secs.find(sec => sec.title.toLowerCase() === clean);
      if (matched) { saveSection(); currentSection = matched; }
      else { if (text || currentLines.length > 0) currentLines.push(line.lyrics); }
    }
    saveSection();
    if (secs.every(sec => !sec.text)) secs[0].expanded = true;
    return secs;
  }

  function syncTextToLines() {
    const newLines = [];
    for (const section of sections) {
      const text = section.text.trim();
      if (text) {
        newLines.push({ lyrics: `[${section.title}]`, chords: Array(24).fill('') });
        const lyricLines = text.split('\n');
        for (const lyric of lyricLines) {
          // Try to find matching chords from existing lines
          const existing = lines.find(l => l.lyrics === lyric);
          newLines.push({ lyrics: lyric, chords: existing?.chords || Array(24).fill('') });
        }
        newLines.push({ lyrics: '', chords: Array(24).fill('') });
      }
    }
    // Remove trailing blank lines
    while (newLines.length > 0 && newLines[newLines.length - 1].lyrics.trim() === '' && newLines[newLines.length - 1].chords.every(c => !c)) {
      newLines.pop();
    }
    setLines(newLines);
    return newLines;
  }

  function handleModeSwitch(mode) {
    if (mode === currentMode) return;
    if (mode !== 'lyrics' && currentMode === 'lyrics') {
      syncTextToLines();
    } else if (mode === 'lyrics') {
      // sync lines back to sections
      setSections(prev => {
        const secs = SECTIONS.map(t => ({ title: t, text: '', expanded: false }));
        let currentSection = null;
        let currentLines = [];
        function saveSection() {
          if (currentSection) {
            const newText = currentLines.join('\n').trim();
            if (newText) currentSection.text = newText;
            if (currentSection.text) currentSection.expanded = true;
          } else if (currentLines.length > 0) {
            const newText = currentLines.join('\n').trim();
            if (newText) { secs[0].text = newText; secs[0].expanded = true; }
          }
          currentLines = [];
        }
        for (const line of lines) {
          const text = line.lyrics.trim();
          const clean = text.replace(/\[|\]/g, '').trim().toLowerCase();
          const matched = secs.find(sec => sec.title.toLowerCase() === clean);
          if (matched) { saveSection(); currentSection = matched; }
          else { if (text || currentLines.length > 0) currentLines.push(line.lyrics); }
        }
        saveSection();
        if (secs.every(sec => !sec.text)) secs[0].expanded = true;
        return secs;
      });
    }
    setCurrentMode(mode);
  }

  function handleChordClick(lineIdx, slotIdx) {
    if (currentMode === 'view') return;
    setPicker({ lineIdx, slotIdx });
  }

  function setChord(lineIdx, slotIdx, value) {
    setLines(prev => {
      const updated = [...prev];
      const line = { ...updated[lineIdx] };
      const c = [...line.chords];
      c[slotIdx] = value;
      line.chords = c;
      updated[lineIdx] = line;
      return updated;
    });
  }

  function handleSave() {
    let finalLines = lines;
    if (currentMode === 'lyrics') {
      finalLines = syncTextToLines();
    }
    onSave({
      id: song?.id || Date.now().toString(),
      title,
      songKey: currentKey,
      lines: finalLines,
      language: song?.language || 'english',
    });
  }

  function handleKeyChange(newKey) {
    // Transpose chords
    const oldChords = KEY_CHORDS[currentKey];
    const newChords = KEY_CHORDS[newKey];
    if (oldChords && newChords) {
      setLines(prev => prev.map(line => ({
        ...line,
        chords: line.chords.map(c => {
          const idx = oldChords.indexOf(c);
          return idx !== -1 ? newChords[idx] : c;
        }),
      })));
    }
    setCurrentKey(newKey);
  }

  return (
    <div className="song-editor">
      {/* Top Config Bar */}
      <div className="editor-toolbar glass-panel">
        <div className="mode-toggle">
          {['chords', 'lyrics', 'view'].map(mode => (
            <button
              key={mode}
              className={`mode-btn ${currentMode === mode ? 'active' : ''}`}
              onClick={() => handleModeSwitch(mode)}
            >
              {mode.charAt(0).toUpperCase() + mode.slice(1)}
            </button>
          ))}
        </div>
        <select className="key-select" value={currentKey} onChange={e => handleKeyChange(e.target.value)}>
          {ALL_KEYS.map(k => <option key={k} value={k}>Key of {k}</option>)}
        </select>
        <button className="btn btn-primary" onClick={handleSave}>Save</button>
        <button className="btn btn-secondary" onClick={onClose}>Exit</button>
      </div>

      {/* Info Bar */}
      <div className="editor-info">
        {title} • Key of {currentKey}
      </div>

      {/* Editor Content */}
      <div className="editor-body">
        {currentMode === 'lyrics' ? (
          <div className="lyrics-editor">
            {sections.map((sec, i) => (
              <div key={sec.title} className="section-block">
                <div
                  className={`section-header ${sec.text ? 'filled' : ''}`}
                  onClick={() => setSections(prev => prev.map((s, idx) => idx === i ? { ...s, expanded: !s.expanded } : s))}
                >
                  <span>{sec.title}</span>
                  <svg className={`chevron ${sec.expanded ? 'open' : ''}`} width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9l6 6 6-6"/></svg>
                </div>
                {sec.expanded && (
                  <textarea
                    className="section-textarea"
                    placeholder="Paste or type lyrics here..."
                    value={sec.text}
                    onChange={e => setSections(prev => prev.map((s, idx) => idx === i ? { ...s, text: e.target.value } : s))}
                  />
                )}
              </div>
            ))}
          </div>
        ) : (
          <div className="chords-view">
            {lines.map((line, lineIdx) => {
              if (line.lyrics.trim() === '' && line.chords.every(c => !c)) {
                return <div key={lineIdx} className="spacer-line" />;
              }
              const isSectionHeader = line.lyrics.trim().startsWith('[') && line.lyrics.trim().endsWith(']');
              return (
                <div key={lineIdx} className={`chord-line ${isSectionHeader ? 'section-header-line' : ''}`}>
                  {!isSectionHeader && (
                    <div className="chord-slots">
                      {line.chords.slice(0, 24).map((chord, slotIdx) => (
                        <div
                          key={slotIdx}
                          className={`chord-slot ${chord ? 'has-chord' : ''} ${currentMode === 'view' && !chord ? 'hidden-slot' : ''}`}
                          onClick={() => handleChordClick(lineIdx, slotIdx)}
                        >
                          {chord || (currentMode !== 'view' ? '+' : '')}
                        </div>
                      ))}
                    </div>
                  )}
                  {line.lyrics.trim() && (
                    <div className={`lyric-text ${isSectionHeader ? 'section-label' : ''}`}>
                      {line.lyrics}
                    </div>
                  )}
                </div>
              );
            })}
            {lines.length === 0 && (
              <div className="empty-state">
                <p>Switch to Lyrics mode first to add lyrics, then come back here to add chords.</p>
              </div>
            )}
          </div>
        )}
      </div>

      {picker && (
        <ChordPicker
          currentKey={currentKey}
          value={lines[picker.lineIdx]?.chords[picker.slotIdx] || ''}
          onPick={(v) => { setChord(picker.lineIdx, picker.slotIdx, v); setPicker(null); }}
          onClose={() => setPicker(null)}
        />
      )}
    </div>
  );
}

function ChordPicker({ currentKey, value, onPick, onClose }) {
  const [custom, setCustom] = useState(value);
  const palette = KEY_CHORDS[currentKey] || KEY_CHORDS['C'];

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal glass-panel chord-picker animate-fade-in" onClick={e => e.stopPropagation()}>
        <h3>Select Chord</h3>
        <p className="modal-subtitle">Key of {currentKey}</p>
        <div className="chord-palette">
          {palette.map(ch => (
            <button key={ch} className={`chord-chip ${value === ch ? 'active' : ''}`} onClick={() => onPick(ch)}>
              {ch}
            </button>
          ))}
        </div>
        <label>Custom chord</label>
        <input
          type="text"
          value={custom}
          autoFocus
          placeholder="e.g. Asus4"
          onChange={e => setCustom(e.target.value)}
          onKeyDown={e => { if (e.key === 'Enter') onPick(custom.trim()); }}
        />
        <div className="modal-actions">
          <button className="btn btn-danger" onClick={() => onPick('')}>Clear</button>
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={() => onPick(custom.trim())}>Set</button>
        </div>
      </div>
    </div>
  );
}
