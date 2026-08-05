from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

import os

# Prefer a full DATABASE_URL (e.g. Supabase Postgres). Fall back to a local
# SQLite file for dev when DATABASE_URL is unset.
#   Supabase: postgresql://postgres:<pw>@db.<ref>.supabase.co:5432/postgres
DATABASE_URL = os.environ.get("DATABASE_URL")

if DATABASE_URL:
    # SQLAlchemy needs the psycopg2 driver spelled out; Supabase hands you a
    # bare "postg://" or "postgresql://" URL, so normalize both.
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+psycopg2://", 1)
    elif DATABASE_URL.startswith("postgresql://"):
        DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg2://", 1)

    # pool_pre_ping: Supabase drops idle connections; ping before reuse so a
    # stale connection is transparently recycled instead of erroring.
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)
else:
    db_dir = os.environ.get("DB_DIR", ".")
    os.makedirs(db_dir, exist_ok=True)
    engine = create_engine(
        f"sqlite:///{db_dir}/church_app.db",
        connect_args={"check_same_thread": False},
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
