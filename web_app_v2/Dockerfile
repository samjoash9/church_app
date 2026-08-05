# All-in-one image: FastAPI serves BOTH the API and the built Vite SPA on one
# port (:8000). main.py mounts ../frontend/dist as the SPA with a fallback route.
# (DB via DATABASE_URL/Supabase or local SQLite.)
#
# Build context = REPO ROOT (church_app/) so assets/ + frontend/dist can be COPYd.
#   docker build -f web_app_v2/Dockerfile -t church-app .
#
# NOTE: build the frontend first — `cd web_app_v2/frontend && npm run build`.
#
# Only ppt_backgrounds/ + fonts/ + seed/ are needed at runtime (~33M). The
# 145M assets/audio/ pads are excluded via .dockerignore — the web app has no
# worship-pad feature.

FROM python:3.12-slim
WORKDIR /app/backend

COPY web_app_v2/backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY web_app_v2/backend/ ./

# PPT theme backgrounds + fonts, served at /media/assets. (audio/ is dockerignored.)
COPY assets/ /app/assets/

# Built Vite SPA — main.py serves it from ../frontend/dist (= /app/frontend/dist)
# with an /assets mount + SPA fallback. All-in-one: API + UI both on :8000.
COPY web_app_v2/frontend/dist/ /app/frontend/dist/

ENV ASSETS_PATH=/app/assets

# Run as non-root; own the data dir so a local SQLite fallback + uploads are
# writable. In prod, DATABASE_URL points at Supabase and uploads are unused.
RUN useradd --create-home --uid 10001 appuser \
    && mkdir -p /app/backend/data /app/backend/uploads \
    && chown -R appuser:appuser /app/backend
USER appuser

# Render sets $PORT; default 8000 for local docker.
ENV PORT=8000
EXPOSE 8000

# --proxy-headers so client.host is the real client IP (X-Forwarded-For) behind
# Render's TLS proxy — needed for correct per-IP login rate limiting.
# Shell form so $PORT expands.
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT} --proxy-headers --forwarded-allow-ips "*"
