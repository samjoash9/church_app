/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        scaffold: 'var(--c-scaffold)',
        surface: 'var(--c-surface)',
        'surface-dim': 'var(--c-surface-dim)',
        border: 'var(--c-border)',
        accent: 'var(--c-accent)',
        'accent-surface': 'var(--c-accent-surface)',
        'on-accent': 'var(--c-on-accent)',
        'text-primary': 'var(--c-text-primary)',
        'text-secondary': 'var(--c-text-secondary)',
        'text-muted': 'var(--c-text-muted)',
        'drawer-bg': 'var(--c-drawer-bg)',
        'drawer-selected': 'var(--c-drawer-selected)',
        'playing-surface': 'var(--c-playing-surface)',
        danger: 'var(--c-danger)',
      },
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        glow: '0 0 0 1px var(--c-border), 0 8px 24px -8px rgba(0,0,0,0.4)',
      },
    },
  },
  plugins: [],
}
