import 'package:flutter/material.dart';
import '../models/ppt_theme.dart';

/// Registry of all available PPT themes.
///
/// ── How to add a new theme ──────────────────────────────────────────────────
/// 1. Create the asset folder:
///      assets/ppt_backgrounds/<theme_id>/
///
/// 2. Drop images in that folder:
///      assets/ppt_backgrounds/<theme_id>/preview.png   ← picker thumbnail
///      assets/ppt_backgrounds/<theme_id>/bg_01.png     ← slide background(s)
///      assets/ppt_backgrounds/<theme_id>/bg_02.png     ← (add as many as you like)
///
/// 3. Register the folder in pubspec.yaml under flutter › assets:
///      - assets/ppt_backgrounds/<theme_id>/
///
/// 4. Add a [PptTheme] constant below and include it in [all].
/// ────────────────────────────────────────────────────────────────────────────
class PptThemes {
  PptThemes._();

  // ── Built-in themes ──────────────────────────────────────────

  static const PptTheme cloud = PptTheme(
    id: 'cloud',
    displayName: 'Cloud',
    previewAsset: 'assets/ppt_backgrounds/cloud/1.png',
    // 1.png is exclusively used for the main title slide.
    // The image already contains the title text, so no overlay is rendered.
    titleBackgroundAsset: 'assets/ppt_backgrounds/cloud/1.png',
    showTitleOverlay: false,
    // 2.png is used for all other slides.
    backgroundAssets: ['assets/ppt_backgrounds/cloud/2.png'],
    titleTextColor: Colors.black,
    lyricsTextColor: Colors.black,
    sectionTextColor: Colors.black,
    fontFamily: 'The Seasons',
    titleFontSize: 90,
    sectionFontSize: 80,
    lyricsTitleFontSize: 36,
    lyricsFontSize: 56,
    mainTitlePart1: 'B L E S S E D',
    mainTitlePart2: 'SUNDAY',
  );

  static const PptTheme blueCloud = PptTheme(
    id: 'blue_cloud',
    displayName: 'Blue Cloud',
    previewAsset: 'assets/ppt_backgrounds/blue_cloud/1.png',
    // 1.png is exclusively used for the main title slide.
    // The image already contains the title text, so no overlay is rendered.
    titleBackgroundAsset: 'assets/ppt_backgrounds/blue_cloud/1.png',
    showTitleOverlay: false,
    // 2–7.png are randomly assigned to all other slides.
    backgroundAssets: [
      'assets/ppt_backgrounds/blue_cloud/2.png',
      'assets/ppt_backgrounds/blue_cloud/3.png',
      'assets/ppt_backgrounds/blue_cloud/4.png',
      'assets/ppt_backgrounds/blue_cloud/5.png',
      'assets/ppt_backgrounds/blue_cloud/6.png',
      'assets/ppt_backgrounds/blue_cloud/7.png',
    ],
    randomizeBackground: true,
    titleTextColor: Colors.black,
    lyricsTextColor: Colors.black,
    sectionTextColor: Colors.black,
    fontFamily: 'The Seasons',
    titleFontSize: 90,
    sectionFontSize: 80,
    lyricsTitleFontSize: 36,
    lyricsFontSize: 56,
    mainTitlePart1: 'B L E S S E D',
    mainTitlePart2: 'SUNDAY',
  );

  // ── Add future themes here ────────────────────────────────────

  static const PptTheme beige = PptTheme(
    id: 'beige',
    displayName: 'Beige',
    previewAsset: 'assets/ppt_backgrounds/beige/1.png',
    // 1.png is exclusively used for the main title slide.
    // The image already contains the title text, so no overlay is rendered.
    titleBackgroundAsset: 'assets/ppt_backgrounds/beige/1.png',
    showTitleOverlay: false,
    // 2–5.png are randomly assigned to all other slides.
    backgroundAssets: [
      'assets/ppt_backgrounds/beige/2.png',
      'assets/ppt_backgrounds/beige/3.png',
      'assets/ppt_backgrounds/beige/4.png',
      'assets/ppt_backgrounds/beige/5.png',
    ],
    randomizeBackground: true,
    titleTextColor: Colors.black,
    lyricsTextColor: Colors.black,
    sectionTextColor: Colors.black,
    fontFamily: 'The Seasons',
    titleFontSize: 90,
    sectionFontSize: 80,
    lyricsTitleFontSize: 36,
    lyricsFontSize: 56,
    mainTitlePart1: 'B L E S S E D',
    mainTitlePart2: 'SUNDAY',
  );

  // static const PptTheme sunset = PptTheme(
  //   id: 'sunset',
  //   displayName: 'Sunset',
  //   previewAsset: 'assets/ppt_backgrounds/sunset/preview.png',
  //   backgroundAssets: [
  //     'assets/ppt_backgrounds/sunset/bg_01.png',
  //     'assets/ppt_backgrounds/sunset/bg_02.png',
  //   ],
  //   randomizeBackground: true,
  //   titleTextColor: Colors.white,
  //   lyricsTextColor: Colors.white,
  //   sectionTextColor: Colors.white,
  // );

  /// All currently active themes. This list drives the theme picker UI.
  static const List<PptTheme> all = [
    cloud,
    blueCloud,
    beige,
  ];

  /// Looks up a theme by its [id]. Falls back to [cloud] if not found.
  static PptTheme findById(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => cloud,
    );
  }
}
