import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter_pptx/flutter_pptx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/song.dart';
import '../models/ppt.dart';
import '../models/ppt_theme.dart';
import 'ppt_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:dart_pptx/dart_pptx.dart';

class PptExportService {
  /// Generates a .pptx file for the given PPT and its songs.
  /// Returns the file path where the PPTX was saved, or null if cancelled.
  ///
  /// Pass a [theme] to control the visual design of the slides.
  /// Defaults to [PptThemes.cloud] if not specified.
  static Future<String?> exportPptx({
    required PptData ppt,
    required List<SongData> songs,
    PptTheme theme = PptThemes.cloud,
    void Function(String status, double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final pres = FlutterPowerPoint();

    // ── Core slide renderer ─────────────────────────────────────────────────
    // Captures a Flutter widget at 1080p and encodes it as a JPEG for a small
    // file footprint while maintaining high visual quality.
    Future<void> addJpegWidgetSlide(Widget Function(Size) builder) async {
      const size = Size(1280, 720);
      final dynamic ctx = (pres as dynamic).context;
      // Wrap with DefaultAssetBundle so that AssetImage can resolve asset
      // files inside the isolated widget tree that captureFromWidget creates.
      // Without this wrapper AssetImage silently fails → white/black slide.
      final bytes = await ctx.screenshotController.captureFromWidget(
        DefaultAssetBundle(
          bundle: rootBundle,
          child: builder(size),
        ),
        // With pre-decoded dart:ui.Image objects, RawImage paints
        // synchronously so the delay is only a safety margin.
        delay: const Duration(milliseconds: 150),
        pixelRatio: 1.5,
        targetSize: size,
      );
      final decoded = img.decodeImage(bytes as Uint8List);
      final jpegBytes = img.encodeJpg(decoded!, quality: 65);
      pres.addSlide(
        SlideBlank()
          ..background.image =
              ImageReference.fromBytes(jpegBytes, name: 'slide'),
      );
    }

    // ── Pre-decode all background images ────────────────────────────────────
    // Decode every background image into a dart:ui.Image BEFORE building any
    // slide. Unlike MemoryImage (which still decodes asynchronously in the
    // image pipeline), a dart:ui.Image is an already-decoded bitmap that
    // RawImage paints synchronously — no race with captureFromWidget's delay.
    final allAssetPaths = {
      ...theme.backgroundAssets,
      theme.resolvedTitleBackground,
    };
    final Map<String, ui.Image> decodedImages = {};
    for (final path in allAssetPaths) {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      decodedImages[path] = frame.image;
    }

    // ── Background image picker ──────────────────────────────────────────────
    // For randomized themes, each call returns a different image from the pool.
    // For single-background themes, always returns the same image.
    final _random = Random();
    String _pickBackground() {
      if (!theme.randomizeBackground || theme.backgroundAssets.length == 1) {
        return theme.defaultBackground;
      }
      return theme.backgroundAssets[_random.nextInt(theme.backgroundAssets.length)];
    }

    /// Builds a background widget from a pre-decoded dart:ui.Image.
    /// Paints synchronously — no async decode needed during screenshot capture.
    Widget backgroundWidget(String assetPath, Size size) {
      return SizedBox(
        width: size.width,
        height: size.height,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: RawImage(
            image: decodedImages[assetPath]!,
          ),
        ),
      );
    }

    // ── Slide builders ──────────────────────────────────────────────────────

    /// Full-width section slide (e.g. "PRAISE & WORSHIP", "ANNOUNCEMENT").
    Future<void> addSectionSlide(String title) async {
      await addJpegWidgetSlide(
        (size) => Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  Positioned.fill(child: backgroundWidget(_pickBackground(), size)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.sectionTextColor,
                          fontFamily: theme.fontFamily,
                          fontSize: theme.sectionFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8.0,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    /// Song title slide (large centered song name).
    Future<void> addSongTitleSlide(SongData song) async {
      await addJpegWidgetSlide(
        (size) => Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  Positioned.fill(child: backgroundWidget(_pickBackground(), size)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64),
                      child: Text(
                        song.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.titleTextColor,
                          fontFamily: theme.fontFamily,
                          fontSize: theme.titleFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8.0,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    /// Lyrics slide (section label + up to 4 lyric lines).
    Future<void> addLyricsSlide(String sectionTitle, List<String> lyrics) async {
      await addJpegWidgetSlide(
        (size) => Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  Positioned.fill(child: backgroundWidget(_pickBackground(), size)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            sectionTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.titleTextColor,
                              fontFamily: theme.fontFamily,
                              fontSize: theme.lyricsTitleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...lyrics.map(
                            (l) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                l,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.lyricsTextColor,
                                  fontFamily: theme.fontFamily,
                                  fontSize: theme.lyricsFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Pre-calculate slide groups ──────────────────────────────────────────
    int totalSlides = 1 + 3 + 3; // Title + 3 intro sections + 3 outro sections
    final List<List<Map<String, dynamic>>> allSongsSlideGroups = [];

    for (final song in songs) {
      totalSlides += 1; // Song title slide
      final List<Map<String, dynamic>> slideGroups = [];
      String currentTitle = '[${song.title}]';
      List<String> currentLyrics = [];

      for (final line in song.lines) {
        final text = line.lyrics.trim();
        if (text.isEmpty) continue;

        if (text.startsWith('[') && text.endsWith(']')) {
          if (currentLyrics.isNotEmpty) {
            slideGroups.add({
              'title': currentTitle,
              'lyrics': List<String>.from(currentLyrics),
            });
            currentLyrics.clear();
          }
          final sectionName = text.substring(1, text.length - 1);
          currentTitle = '[${song.title} - $sectionName]';
        } else {
          currentLyrics.add(text);
          if (currentLyrics.length >= 4) {
            slideGroups.add({
              'title': currentTitle,
              'lyrics': List<String>.from(currentLyrics),
            });
            currentLyrics.clear();
            if (!currentTitle.endsWith('(cont.)]')) {
              currentTitle = currentTitle.replaceAll(']', ' (cont.)]');
            }
          }
        }
      }
      if (currentLyrics.isNotEmpty) {
        slideGroups.add({
          'title': currentTitle,
          'lyrics': List<String>.from(currentLyrics),
        });
      }

      allSongsSlideGroups.add(slideGroups);
      totalSlides += slideGroups.length;
    }

    // ── Progress reporting helper ───────────────────────────────────────────
    int currentSlide = 0;
    void reportProgress(String status) {
      if (onProgress != null) {
        // Allocate 90% to slide generation, 10% to file saving.
        final progress = (currentSlide / totalSlides) * 0.9;
        onProgress(status, progress);
      }
    }

    // ── Main title slide ────────────────────────────────────────────────────
    reportProgress('Creating title slide...');

    final now = DateTime.now();
    final dateString = '${now.month}/${now.day}/${now.year % 100}';

    await addJpegWidgetSlide(
      (size) => Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              children: [
                // Title slide background — uses the pre-decoded dart:ui.Image
                // so it paints synchronously (no white-flash).
                Positioned.fill(
                  child: backgroundWidget(theme.resolvedTitleBackground, size),
                ),
                // When showTitleOverlay is false the image already contains all
                // title text, so we render nothing on top of it.
                if (theme.showTitleOverlay) ...[
                  // Top-right: Date
                  Positioned(
                    top: 48,
                    right: 48,
                    child: Text(
                      dateString,
                      style: TextStyle(
                        color: theme.titleTextColor.withOpacity(0.75),
                        fontFamily: theme.fontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Center: "BLESSED SUNDAY"
                  Align(
                    alignment: const Alignment(0, -0.45),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (theme.mainTitlePart1.isNotEmpty)
                          Text(
                            theme.mainTitlePart1,
                            style: TextStyle(
                              color: theme.titleTextColor.withOpacity(0.85),
                              fontFamily: theme.fontFamily,
                              fontSize: 56,
                              letterSpacing: 24.0,
                            ),
                          ),
                        Text(
                          theme.mainTitlePart2,
                          style: TextStyle(
                            color: theme.titleTextColor,
                            fontFamily: theme.fontFamily,
                            fontSize: 200,
                            fontWeight: FontWeight.bold,
                            height: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom: Church icon
                  Positioned(
                    bottom: -80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Icon(
                        Icons.church,
                        color: theme.titleTextColor.withOpacity(0.85),
                        size: 400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    currentSlide++;

    // ── Intro section slides ────────────────────────────────────────────────
    reportProgress('Adding intro slides...');
    if (isCancelled != null && isCancelled()) return null;
    await addSectionSlide('SUNDAY SCHOOL');
    currentSlide++;

    if (isCancelled != null && isCancelled()) return null;
    await addSectionSlide('ANNOUNCEMENT');
    currentSlide++;

    if (isCancelled != null && isCancelled()) return null;
    await addSectionSlide('PRAISE & WORSHIP');
    currentSlide++;

    // ── Song slides ─────────────────────────────────────────────────────────
    for (int i = 0; i < songs.length; i++) {
      if (isCancelled != null && isCancelled()) return null;
      final song = songs[i];
      final slideGroups = allSongsSlideGroups[i];

      reportProgress('Creating slides for "${song.title}"...');

      await addSongTitleSlide(song);
      currentSlide++;

      if (isCancelled != null && isCancelled()) return null;

      for (final group in slideGroups) {
        if (isCancelled != null && isCancelled()) return null;
        await addLyricsSlide(
          group['title'] as String,
          group['lyrics'] as List<String>,
        );
        currentSlide++;
        reportProgress('Creating slides for "${song.title}"...');
      }
    }

    // ── Outro section slides ────────────────────────────────────────────────
    reportProgress('Adding outro slides...');
    if (isCancelled != null && isCancelled()) return null;
    await addSectionSlide('WORD');
    currentSlide++;

    if (isCancelled != null && isCancelled()) return null;
    await addSectionSlide('TITHES & OFFERING');
    currentSlide++;

    if (isCancelled != null && isCancelled()) return null;
    await addSectionSlide('ANNOUNCEMENT');
    currentSlide++;

    // ── Save & export ───────────────────────────────────────────────────────
    if (isCancelled != null && isCancelled()) return null;
    if (onProgress != null) onProgress('Saving PowerPoint file...', 0.9);

    final bytes = await pres.save();
    if (bytes == null) return null;

    if (onProgress != null) onProgress('File saved, finalizing...', 0.95);

    final tempDir = await getTemporaryDirectory();
    final safeTitle = ppt.title.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    final fileName = '$safeTitle.pptx';
    final tempFilePath = '${tempDir.path}/$fileName';
    await File(tempFilePath).writeAsBytes(bytes);

    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles(
        [XFile(tempFilePath)],
        text: 'Export: ${ppt.title}',
      );
      return tempFilePath;
    } else {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export PPT as PPTX',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pptx'],
      );

      if (outputPath == null) return null;

      final finalPath =
          outputPath.endsWith('.pptx') ? outputPath : '$outputPath.pptx';
      await File(finalPath).writeAsBytes(bytes);
      return finalPath;
    }
  }
}
