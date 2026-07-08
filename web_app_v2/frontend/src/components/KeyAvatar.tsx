const PALETTE = [
  ['#AEC4FF', '#1A1D2B'],
  ['#FFB6C1', '#3B0D1A'],
  ['#B9F6CA', '#0D3B1E'],
  ['#FFE082', '#3B2E0D'],
  ['#D1B3FF', '#2A0D3B'],
  ['#80DEEA', '#0D2E3B'],
  ['#FFAB91', '#3B190D'],
]

function hashKey(key: string) {
  let h = 0
  for (let i = 0; i < key.length; i++) h = (h * 31 + key.charCodeAt(i)) >>> 0
  return h
}

export function KeyAvatar({ songKey, size = 44 }: { songKey: string; size?: number }) {
  const [bg, fg] = PALETTE[hashKey(songKey) % PALETTE.length]
  return (
    <div
      className="flex items-center justify-center rounded-full font-bold shrink-0"
      style={{ width: size, height: size, background: bg, color: fg, fontSize: size * 0.38 }}
    >
      {songKey.slice(0, 2)}
    </div>
  )
}
