"""Registry of PPT export themes.

Mirrors the mobile app's lib/services/ppt_themes.dart so both platforms
produce identical decks. Background images live in the repo's shared
assets/ppt_backgrounds/<theme_id>/ folder (the same files the Flutter app
bundles), resolved at runtime relative to ASSETS_PATH.

How to add a new theme:
1. Drop images into assets/ppt_backgrounds/<theme_id>/
   (1.png = title slide, 2.png.. = content slide backgrounds)
2. Add a PptTheme entry below and include it in ALL_THEMES.
"""

from dataclasses import dataclass, field
from typing import List, Optional


@dataclass(frozen=True)
class PptTheme:
    id: str
    display_name: str
    preview_asset: str                 # picker thumbnail, relative to assets dir
    background_assets: List[str]       # content slide backgrounds
    title_text_color: str              # hex RRGGBB
    lyrics_text_color: str
    section_text_color: str
    title_background_asset: Optional[str] = None  # title slide only
    randomize_background: bool = False
    show_title_overlay: bool = True
    font_family: str = "The Seasons"
    # TTF file (relative to assets dir) used to rasterize text server-side.
    # PPTX text runs only *reference* a font by name — if the machine opening
    # the file doesn't have "The Seasons" / "Space Grotesk" installed, it
    # silently substitutes a fallback (often a symbol font), producing
    # garbled slides. Rendering text to an image with the exact bundled TTF
    # (same files the mobile app ships) sidesteps that entirely.
    font_file: str = "fonts/TheSeasons.ttf"
    # Sizes are the mobile theme's logical px on a 1280x720 canvas; the
    # exporter scales them to PowerPoint points (x 540/720 = 0.75).
    title_font_size: float = 104.0
    section_font_size: float = 92.0
    lyrics_title_font_size: float = 42.0
    lyrics_font_size: float = 64.0
    main_title_part1: str = "B L E S S E D"
    main_title_part2: str = "SUNDAY"

    @property
    def default_background(self) -> str:
        return self.background_assets[0]

    @property
    def resolved_title_background(self) -> str:
        return self.title_background_asset or self.default_background


CLOUD = PptTheme(
    id="cloud",
    display_name="Cloud",
    preview_asset="ppt_backgrounds/cloud/1.png",
    # 1.png is exclusively the main title slide; the image already contains
    # the title text, so no overlay is rendered.
    title_background_asset="ppt_backgrounds/cloud/1.png",
    show_title_overlay=False,
    background_assets=["ppt_backgrounds/cloud/2.png"],
    title_text_color="000000",
    lyrics_text_color="000000",
    section_text_color="000000",
)

BLUE_CLOUD = PptTheme(
    id="blue_cloud",
    display_name="Blue Cloud",
    preview_asset="ppt_backgrounds/blue_cloud/1.png",
    title_background_asset="ppt_backgrounds/blue_cloud/1.png",
    show_title_overlay=False,
    background_assets=[f"ppt_backgrounds/blue_cloud/{i}.png" for i in range(2, 8)],
    randomize_background=True,
    title_text_color="000000",
    lyrics_text_color="000000",
    section_text_color="000000",
)

BEIGE = PptTheme(
    id="beige",
    display_name="Beige",
    preview_asset="ppt_backgrounds/beige/1.png",
    title_background_asset="ppt_backgrounds/beige/1.png",
    show_title_overlay=False,
    background_assets=[f"ppt_backgrounds/beige/{i}.png" for i in range(2, 6)],
    randomize_background=True,
    title_text_color="000000",
    lyrics_text_color="000000",
    section_text_color="000000",
)

BLUE_FIELD = PptTheme(
    id="blue_field",
    display_name="Blue Field",
    preview_asset="ppt_backgrounds/blue_field/1.png",
    title_background_asset="ppt_backgrounds/blue_field/1.png",
    show_title_overlay=False,
    background_assets=["ppt_backgrounds/blue_field/2.png"],
    title_text_color="FFFFFF",
    lyrics_text_color="FFFFFF",
    section_text_color="FFFFFF",
)

CYAN_LIGHT = PptTheme(
    id="cyan_light",
    display_name="Cyan Light",
    preview_asset="ppt_backgrounds/cyan_light/1.png",
    title_background_asset="ppt_backgrounds/cyan_light/1.png",
    show_title_overlay=False,
    background_assets=[f"ppt_backgrounds/cyan_light/{i}.png" for i in range(2, 8)],
    randomize_background=True,
    title_text_color="FFFFFF",
    lyrics_text_color="FFFFFF",
    section_text_color="FFFFFF",
)

ORANGE = PptTheme(
    id="orange",
    display_name="Orange",
    preview_asset="ppt_backgrounds/orange/1.png",
    title_background_asset="ppt_backgrounds/orange/1.png",
    show_title_overlay=False,
    background_assets=[f"ppt_backgrounds/orange/{i}.png" for i in range(2, 5)],
    randomize_background=True,
    title_text_color="FFFFFF",
    lyrics_text_color="FFFFFF",
    section_text_color="FFFFFF",
    # Space Grotesk stands in for Neue Montreal (commercial), same as mobile.
    font_family="Space Grotesk",
    font_file="fonts/SpaceGrotesk-VariableFont_wght.ttf",
)

ALL_THEMES: List[PptTheme] = [CLOUD, BLUE_CLOUD, BEIGE, BLUE_FIELD, CYAN_LIGHT, ORANGE]

# Fixed section slides that wrap every presentation (same as mobile).
INTRO_SECTIONS = ["SUNDAY SCHOOL", "ANNOUNCEMENT", "PRAISE & WORSHIP"]
OUTRO_SECTIONS = ["WORD", "TITHES & OFFERING", "ANNOUNCEMENT"]


def find_theme(theme_id: str) -> PptTheme:
    """Looks up a theme by id, falling back to Cloud (same as mobile)."""
    for theme in ALL_THEMES:
        if theme.id == theme_id:
            return theme
    return CLOUD


def build_song_slides(title: str, lines) -> List[dict]:
    """Splits a song's lines into lyric slides exactly as the mobile exporter
    does: a [Section] line starts a new slide group, lyric lines pack
    4-per-slide with a (cont.) marker once a group overflows.

    Each returned dict: {"title": "[Song - Section]", "lyrics": [up to 4 lines]}
    """
    slides: List[dict] = []
    current_title = f"[{title}]"
    current_lyrics: List[str] = []

    def flush():
        nonlocal current_lyrics
        if current_lyrics:
            slides.append({"title": current_title, "lyrics": list(current_lyrics)})
            current_lyrics = []

    for line in lines:
        text = (line.get("lyrics", "") if isinstance(line, dict) else line.lyrics).strip()
        if not text:
            continue
        if text.startswith("[") and text.endswith("]"):
            flush()
            section_name = text[1:-1]
            current_title = f"[{title} - {section_name}]"
        else:
            current_lyrics.append(text)
            if len(current_lyrics) >= 4:
                flush()
                if not current_title.endswith("(cont.)]"):
                    current_title = current_title.replace("]", " (cont.)]")

    flush()
    return slides
