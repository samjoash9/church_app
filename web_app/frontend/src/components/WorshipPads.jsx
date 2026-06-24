import { useState, useRef, useEffect, useCallback } from 'react';
import './WorshipPads.css';

const API_BASE = import.meta.env.VITE_API_URL || '';

const MAJOR_KEYS = ['E', 'F', 'G', 'A', 'B', 'C', 'D'];
const MINOR_KEYS = ['C#m', 'D#m', 'Em', 'F#m', 'G#m', 'Am', 'Bm'];

const FADE_OUT_MS = 7000;
const FADE_IN_MS = 1500;
const FADE_STEP_MS = 50;

export default function WorshipPads() {
  const [showMajor, setShowMajor] = useState(true);
  const [activeKey, setActiveKey] = useState(null);
  // Every live audio element + its fade interval id, so a fading-out pad
  // can finish its tail while a new pad fades in (mirrors the mobile app).
  const playersRef = useRef([]);

  const clearFade = (player) => {
    if (player._fadeId) {
      clearInterval(player._fadeId);
      player._fadeId = null;
    }
  };

  const fadeOutAndStop = useCallback((player) => {
    if (!player) return;
    clearFade(player);
    const startVol = player.volume;
    const steps = Math.max(1, Math.floor(FADE_OUT_MS / FADE_STEP_MS));
    let step = 0;
    player._fadeId = setInterval(() => {
      step++;
      const v = startVol * (1 - step / steps);
      player.volume = Math.max(0, v);
      if (step >= steps) {
        clearFade(player);
        player.pause();
        player.src = '';
        playersRef.current = playersRef.current.filter(p => p !== player);
      }
    }, FADE_STEP_MS);
  }, []);

  const fadeIn = (player) => {
    clearFade(player);
    player.volume = 0;
    const steps = Math.max(1, Math.floor(FADE_IN_MS / FADE_STEP_MS));
    let step = 0;
    player._fadeId = setInterval(() => {
      step++;
      player.volume = Math.min(1, step / steps);
      if (step >= steps) clearFade(player);
    }, FADE_STEP_MS);
  };

  const stopAll = useCallback(() => {
    playersRef.current.forEach(fadeOutAndStop);
    setActiveKey(null);
  }, [fadeOutAndStop]);

  // Cleanup on unmount: hard-stop every player.
  useEffect(() => () => {
    playersRef.current.forEach(p => { clearFade(p); p.pause(); p.src = ''; });
    playersRef.current = [];
  }, []);

  const togglePad = (key) => {
    // Tapping the active pad stops it.
    if (activeKey === key) {
      stopAll();
      return;
    }

    // Minor pads have no bundled audio (only Major pads ship in assets).
    if (!showMajor) {
      alert('Minor pads have no audio bundled. Add minor pad files to assets/audio to enable them.');
      return;
    }

    // Fade out the current pad (keeps its tail), fade the new one in.
    playersRef.current.forEach(fadeOutAndStop);

    const audio = new Audio();
    audio.src = `${API_BASE}/media/audio/${key}_Major_Pad.mp3`;
    audio.loop = true;
    audio.volume = 0;
    playersRef.current.push(audio);
    audio.play()
      .then(() => fadeIn(audio))
      .catch(err => {
        console.error('Audio playback failed:', err);
        playersRef.current = playersRef.current.filter(p => p !== audio);
      });

    setActiveKey(key);
  };

  const keys = showMajor ? MAJOR_KEYS : MINOR_KEYS;

  return (
    <div className="pads-container">
      <div className="pad-mode-toggle">
        <button className={`mode-tab ${showMajor ? 'active' : ''}`} onClick={() => { stopAll(); setShowMajor(true); }}>
          Major
        </button>
        <button className={`mode-tab ${!showMajor ? 'active' : ''}`} onClick={() => { stopAll(); setShowMajor(false); }}>
          Minor
        </button>
      </div>

      <div className="pad-grid">
        {keys.map(key => (
          <button
            key={key}
            className={`pad-btn glass-panel ${activeKey === key ? 'active' : ''}`}
            onClick={() => togglePad(key)}
          >
            {key}
          </button>
        ))}
      </div>

      {activeKey && (
        <div className="now-playing glass-panel animate-fade-in">
          <div className="playing-indicator">
            <span className="dot pulse" />
            Now Playing: {activeKey} Pad
          </div>
          <button className="btn btn-danger" onClick={stopAll}>Stop</button>
        </div>
      )}
    </div>
  );
}
