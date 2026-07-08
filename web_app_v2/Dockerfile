# Stage 1: Build React frontend
FROM node:22-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Stage 2: Python backend + serve built frontend
FROM python:3.12-slim
WORKDIR /app/backend

COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ ./

COPY --from=frontend-build /app/frontend/dist /app/frontend/dist

ENV ASSETS_PATH=/app/assets

# Run as non-root; own the data dir so SQLite + uploads are writable.
RUN useradd --create-home --uid 10001 appuser \
    && mkdir -p /app/backend/data /app/backend/uploads \
    && chown -R appuser:appuser /app/backend
USER appuser

EXPOSE 8000

# --proxy-headers + trusted forwarded IPs so client.host is the real
# client (via X-Forwarded-For) when behind a TLS reverse proxy, not the
# proxy's IP — required for correct per-IP login rate limiting.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", \
     "--proxy-headers", "--forwarded-allow-ips", "*"]
