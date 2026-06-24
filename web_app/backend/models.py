from sqlalchemy import Column, Integer, String, JSON
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
