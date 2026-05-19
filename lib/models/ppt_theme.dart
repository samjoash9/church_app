import 'package:flutter/material.dart';

/// Describes the visual design of a PowerPoint export.
/// Add new themes by creating instances of this class.
class PptTheme {
  const PptTheme({
    required this.id,
    required this.displayName,
    required this.previewAsset,
    required this.backgroundAssets,
    required this.titleTextColor,
    required this.lyricsTextColor,
    required this.sectionTextColor,
    this.titleBackgroundAsset,
    this.fontFamily = 'The Seasons',
    this.titleFontSize = 90.0,
    this.sectionFontSize = 80.0,
    this.lyricsTitleFontSize = 36.0,
    this.lyricsFontSize = 56.0,
    this.mainTitlePart1 = 'B L E S S E D',
    this.mainTitlePart2 = 'SUNDAY',
    this.randomizeBackground = false,
    this.showTitleOverlay = true,
  });

  /// Unique identifier for this theme (used for storage/lookup).
  final String id;

  /// Human-readable name shown in the theme picker UI.
  final String displayName;

  /// Asset path for the small preview thumbnail in the picker.
  final String previewAsset;

  /// List of background image asset paths.
  ///
  /// - For single-background themes, provide a list with one entry.
  /// - For randomized themes (see [randomizeBackground]), add as many
  ///   images as you like — one will be picked at random per slide.
  final List<String> backgroundAssets;

  /// Optional dedicated background for the main title slide only.
  /// When null, the title slide uses [defaultBackground] instead.
  final String? titleBackgroundAsset;

  /// Whether to randomize the background per slide.
  final bool randomizeBackground;

  // ── Colors ──────────────────────────────────────────────────
  final Color titleTextColor;
  final Color lyricsTextColor;
  final Color sectionTextColor;

  // ── Typography ───────────────────────────────────────────────
  final String fontFamily;

  /// Font size for the large song title slide.
  final double titleFontSize;

  /// Font size for standalone section slides (e.g. "PRAISE & WORSHIP").
  final double sectionFontSize;

  /// Font size for the small section label on lyrics slides.
  final double lyricsTitleFontSize;

  /// Font size for the actual lyric lines.
  final double lyricsFontSize;

  // ── Main title slide content ──────────────────────────────────
  final String mainTitlePart1;
  final String mainTitlePart2;

  /// When false, the title slide renders only the background image with
  /// no text, date, or icon overlays (use when the image itself has the text).
  final bool showTitleOverlay;

  // ── Convenience ──────────────────────────────────────────────

  /// Returns the single background asset path (used for themes with one
  /// background, or when [randomizeBackground] is false).
  String get defaultBackground => backgroundAssets.first;

  /// Background to use specifically on the main title slide.
  /// Falls back to [defaultBackground] if [titleBackgroundAsset] is not set.
  String get resolvedTitleBackground => titleBackgroundAsset ?? defaultBackground;
}
