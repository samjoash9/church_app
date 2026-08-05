# Deploying the Church Web App (web_app_v2) — split, all free tiers

```
  Vercel                 Render                  Supabase
  (React SPA)  ── /api ──▶ (FastAPI, Docker) ──▶ (Postgres)
               ◀ /media ──   serves ppt bg + fonts
```

- **Frontend** → Vercel (static React build)
- **Backend API** → Render (Docker, free web service)
- **Database** → Supabase Postgres (free)

All three have free tiers. Caveats: Render free **sleeps after 15 min idle**
(first request cold-starts ~30–50s); Supabase free **pauses after 7 days
inactivity** (unpause from the dashboard).

The 145 MB `assets/audio/` worship pads are **excluded from the image** (no
web feature uses them) — see `.dockerignore`. Only `ppt_backgrounds/` + `fonts/`
(~33 MB) are baked in and served at `/media/assets`.

---

## 1. Supabase (database)

1. Create a project at supabase.com → note the DB password.
2. Project Settings → Database → **Connection string** (URI). Copy it:
   `postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres`
3. That's it — tables auto-create on the API's first boot
   (`models.Base.metadata.create_all`, [main.py:14](backend/main.py#L14)).

## 2. Render (backend API)

The repo ships a [render.yaml](../render.yaml) blueprint.

1. Render Dashboard → **New → Blueprint** → connect this repo.
2. It reads `render.yaml` (Docker, build context = repo root,
   `dockerfilePath: web_app_v2/Dockerfile`).
3. Set these env vars (Dashboard → the service → Environment) — all secret:

   | Var | Value |
   |-----|-------|
   | `DATABASE_URL` | Supabase connection string from step 1 |
   | `SECRET_KEY` | `python -c "import secrets; print(secrets.token_hex(32))"` |
   | `APP_PASSWORD_HASH` | `python -c "import hashlib; print(hashlib.sha256(b'yourpassword').hexdigest())"` |
   | `ALLOWED_ORIGINS` | your Vercel URL, e.g. `https://church-app.vercel.app` |
   | `PUBLIC_MEDIA_BASE` | this service's URL, e.g. `https://church-api.onrender.com` |

   `COOKIE_SAMESITE=none` and `COOKIE_SECURE=true` are preset in the blueprint.

4. Deploy. Health check: `GET /api/health`. Note the service URL.

> **Chicken-and-egg:** you need the Vercel URL for `ALLOWED_ORIGINS` and the
> Render URL for Vercel's `VITE_API_BASE`. Deploy Render first with a
> placeholder origin, deploy Vercel, then come back and set the real
> `ALLOWED_ORIGINS` + `PUBLIC_MEDIA_BASE` and redeploy Render.

## 3. Vercel (frontend)

1. Vercel → **New Project** → import this repo.
2. **Root Directory**: `web_app_v2/frontend`.
3. Framework preset: **Vite** (auto). Build/output come from
   [vercel.json](frontend/vercel.json) (SPA rewrites included).
4. Environment Variable:
   `VITE_API_BASE = https://church-api.onrender.com` (your Render URL).
5. Deploy → note the `*.vercel.app` URL → put it in Render's `ALLOWED_ORIGINS`
   and `PUBLIC_MEDIA_BASE` uses the **Render** URL (not Vercel) → redeploy Render.

## 4. Verify

- Open the Vercel URL, log in (the password you hashed).
- DevTools → Network: `/api/*` calls hit the Render origin, return 200, and the
  `church_session` cookie is set (`SameSite=None; Secure`).
- PPT export → theme previews load (images come from Render `/media/assets`).

---

## Local development

Backend (Docker, SQLite, same-origin cookies):
```bash
# web_app_v2/.env needs SECRET_KEY + APP_PASSWORD_HASH (see .env.example)
cd web_app_v2
docker compose up --build          # API on http://localhost:8000
```
Frontend (Vite dev server, proxies /api + /media to :8000):
```bash
cd web_app_v2/frontend
npm install && npm run dev          # http://localhost:5173
```
Leave `VITE_API_BASE` unset locally — the Vite proxy handles it.

---

## Gotchas

- **Cross-site cookies**: split origins require `SameSite=None; Secure` (set via
  `COOKIE_SAMESITE`/`COOKIE_SECURE`) **and** CORS `allow_credentials=True` with
  an exact origin (never `*`). Already wired in [main.py](backend/main.py).
- **Render cold starts**: free tier sleeps; first hit after idle is slow. Bump
  to a paid instance or add an external uptime pinger to keep warm.
- **Supabase pause**: weekly church use likely keeps it active; if paused,
  unpause in the dashboard.
- **psycopg2**: `psycopg2-binary` is in requirements for the Postgres driver.
- **No worship-pad audio on web**: the feature/pages don't exist in the web
  app, so `assets/audio/` is dockerignored. If you add the feature later,
  move uploads to Supabase Storage (Render's FS is ephemeral).
