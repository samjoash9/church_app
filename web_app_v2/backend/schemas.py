from pydantic import BaseModel, ConfigDict
from typing import List, Optional

class LoginRequest(BaseModel):
    password: str

class SongLineData(BaseModel):
    lyrics: str
    chords: List[str]

class SongDataBase(BaseModel):
    title: str
    songKey: str
    lines: List[SongLineData]
    language: Optional[str] = "english"

class SongDataCreate(SongDataBase):
    id: str

class SongData(SongDataCreate):
    model_config = ConfigDict(from_attributes=True)

class LineupItemCreate(BaseModel):
    song_id: str

class LineupItem(BaseModel):
    id: int
    order_index: int
    song_id: str

    model_config = ConfigDict(from_attributes=True)

class LineupReorder(BaseModel):
    song_ids: List[str]

class PptCreate(BaseModel):
    id: str
    title: str
    song_ids: List[str]

class PptData(PptCreate):
    model_config = ConfigDict(from_attributes=True)

class ExportSongsRequest(BaseModel):
    song_ids: List[str]

class ImportSongsResult(BaseModel):
    imported: int
    updated: int
    skipped: int

class ExportPdfRequest(BaseModel):
    song_ids: List[str]

class ExportPptRequest(BaseModel):
    song_ids: List[str]
    theme: Optional[str] = "cloud"

class SoundEntryCreate(BaseModel):
    mode: str
    key: str
    name: str
    path: str
    size_in_bytes: Optional[int] = 0
    is_asset: Optional[bool] = False

class SoundEntryData(SoundEntryCreate):
    id: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)

class SetActiveSoundRequest(BaseModel):
    sound_id: int
