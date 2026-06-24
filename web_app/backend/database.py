from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

import os

db_dir = os.environ.get("DB_DIR", ".")
os.makedirs(db_dir, exist_ok=True)
SQLALCHEMY_DATABASE_URL = f"sqlite:///{db_dir}/church_app.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
