import { Navigate, Route, Routes } from 'react-router-dom'
import { Layout } from './components/Layout'
import { ChordsPage } from './pages/ChordsPage'
import { LineupPage } from './pages/LineupPage'
import { PptPage } from './pages/PptPage'
import { SettingsPage } from './pages/SettingsPage'

export default function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Navigate to="/chords" replace />} />
        <Route path="/chords" element={<ChordsPage />} />
        <Route path="/lineup" element={<LineupPage />} />
        <Route path="/ppt" element={<PptPage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="*" element={<Navigate to="/chords" replace />} />
      </Routes>
    </Layout>
  )
}
