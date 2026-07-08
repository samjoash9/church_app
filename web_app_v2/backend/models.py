from sqlalchemy import Column, Integer, String, JSON, Boolean
from database import Base

class Song(Base):
    __tablename__ = "songs"

    id = Column(String, primary_key=True, index=True)
    title = Column(String, index=True)
    songKey = Column(String)
    lines = Column(JSON)
    language = Column(String, default="english")

class LineupEntry(Base):
    __tablename__ = "lineup"

    id = Column(Integer, primary_key=True, autoincrement=True)
    order_index = Column(Integer, index=True)
    song_id = Column(String, index=True)

class PptPresentation(Base):
    __tablename__ = "ppts"

    id = Column(String, primary_key=True, index=True)
    title = Column(String, index=True)
    song_ids = Column(JSON)  # List[str]

class SoundEntry(Base):
    __tablename__ = "sounds"

    id = Column(Integer, primary_key=True, autoincrement=True)
    mode = Column(String, index=True)   # "Major" | "Minor"
    key = Column(String, index=True)    # "E", "F#m", ...
    name = Column(String)
    path = Column(String)               # /media/... URL or asset id
    size_in_bytes = Column(Integer, default=0)
    is_asset = Column(Boolean, default=False)
    is_active = Column(Boolean, default=False)
