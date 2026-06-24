import './SongOverview.css';

export default function SongOverview({ song, onClose, onEdit }) {
  if (!song) return null;

  const lines = song.lines || [];

  return (
    <div className="overview-screen animate-fade-in">
      <div className="overview-header glass-panel">
        <button className="btn-icon" onClick={onClose} title="Back">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M19 12H5M12 19l-7-7 7-7"/></svg>
        </button>
        <h3>{song.title}</h3>
        <div className="overview-key">Key of {song.songKey}</div>
      </div>

      <div className="overview-body">
        {lines.map((line, idx) => {
          const lyrics = line.lyrics || '';
          const chords = line.chords || [];
          const isBlank = !lyrics.trim() && chords.every(c => !c);
          if (isBlank) return <div key={idx} className="ov-spacer" />;

          const isSection = lyrics.trim().startsWith('[') && lyrics.trim().endsWith(']');
          const activeChords = chords.filter(c => c);

          if (isSection) {
            return <div key={idx} className="ov-section">{lyrics.replace(/[[\]]/g, '')}</div>;
          }

          return (
            <div key={idx} className="ov-line">
              {activeChords.length > 0 && (
                <div className="ov-chords">
                  {activeChords.map((c, i) => <span key={i} className="ov-chord">{c}</span>)}
                </div>
              )}
              {lyrics.trim() && <div className="ov-lyric">{lyrics}</div>}
            </div>
          );
        })}
      </div>

      <div className="overview-footer glass-panel">
        <button className="btn btn-secondary" onClick={onClose}>Back</button>
        {onEdit && <button className="btn btn-primary" onClick={() => onEdit(song)}>Edit</button>}
      </div>
    </div>
  );
}
