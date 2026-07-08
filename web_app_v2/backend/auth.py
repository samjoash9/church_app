import hashlib
import hmac
import os
import time

from fastapi import Cookie, HTTPException, Request
import jwt

SECRET_KEY = os.environ.get("SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError(
        "SECRET_KEY environment variable is not set. "
        "Generate one with: python -c \"import secrets; print(secrets.token_hex(32))\""
    )

APP_PASSWORD_HASH = os.environ.get("APP_PASSWORD_HASH")
if not APP_PASSWORD_HASH:
    raise RuntimeError(
        "APP_PASSWORD_HASH environment variable is not set. "
        "Generate one with: python -c \"import hashlib; print(hashlib.sha256(b'yourpassword').hexdigest())\""
    )

COOKIE_NAME = "church_session"
TOKEN_TTL_SECONDS = 60 * 60 * 24 * 14  # 14 days

# --- login rate limiting (per-process, in-memory) -----------------------
_LOGIN_ATTEMPTS: dict[str, list[float]] = {}
MAX_ATTEMPTS = 5
WINDOW_SECONDS = 60 * 15


def check_rate_limit(client_ip: str):
    now = time.time()
    attempts = [t for t in _LOGIN_ATTEMPTS.get(client_ip, []) if now - t < WINDOW_SECONDS]
    if len(attempts) >= MAX_ATTEMPTS:
        raise HTTPException(status_code=429, detail="Too many login attempts. Try again later.")
    _LOGIN_ATTEMPTS[client_ip] = attempts


def record_failed_attempt(client_ip: str):
    _LOGIN_ATTEMPTS.setdefault(client_ip, []).append(time.time())


def clear_attempts(client_ip: str):
    _LOGIN_ATTEMPTS.pop(client_ip, None)


def verify_password(password: str) -> bool:
    candidate = hashlib.sha256(password.encode()).hexdigest()
    return hmac.compare_digest(candidate, APP_PASSWORD_HASH)


def create_token() -> str:
    payload = {"iat": int(time.time()), "exp": int(time.time()) + TOKEN_TTL_SECONDS}
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")


def is_valid_token(token: str | None) -> bool:
    if not token:
        return False
    try:
        jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return True
    except jwt.PyJWTError:
        return False


def require_auth(church_session: str | None = Cookie(default=None)):
    if not is_valid_token(church_session):
        raise HTTPException(status_code=401, detail="Not authenticated")
