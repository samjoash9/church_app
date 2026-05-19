import 'dart:io';
import 'package:flutter_pptx/flutter_pptx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/song.dart';
import '../models/ppt.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:dart_pptx/dart_pptx.dart';

class PptExportService {
  /// Generates a .pptx file for the given PPT and its songs.
  /// Returns the file path where the PPTX was saved, or null if cancelled.
  static Future<String?> exportPptx({
    required PptData ppt,
    required List<SongData> songs,
    void Function(String status, double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final pres = FlutterPowerPoint();

    Future<void> addJpegWidgetSlide(Widget Function(Size) builder) async {
      final size = const Size(1280, 720);
      final dynamic ctx = (pres as dynamic).context;
      final bytes = await ctx.screenshotController.captureFromWidget(
        builder(size),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 1.5,
        targetSize: size,
      );
      final decoded = img.decodeImage(bytes as Uint8List);
      final jpegBytes = img.encodeJpg(decoded!, quality: 65);
      pres.addSlide(SlideBlank()..background.image = ImageReference.fromBytes(jpegBytes, name: 'slide'));
    }

    Future<void> addSectionSlide(String title) async {
      await addJpegWidgetSlide(
        (size) => Directionality(
          textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/ppt_backgrounds/cloud.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'The Seasons',
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.0,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
    }
    
    // Pre-calculate slides
    int totalSlides = 1 + 3 + 3; // Title + 3 start sections + 3 end sections
    List<List<Map<String, dynamic>>> allSongsSlideGroups = [];
    for (final song in songs) {
      totalSlides += 1;
      List<Map<String, dynamic>> slideGroups = [];
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

    int currentSlide = 0;
    void reportProgress(String status) {
      if (onProgress != null) {
        // We allocate 90% to slide generation, 10% to saving.
        double progress = (currentSlide / totalSlides) * 0.9;
        onProgress(status, progress);
      }
    }

    reportProgress('Creating title slide...');

    // Title slide
    String titlePart1 = 'B L E S S E D';
    String titlePart2 = 'SUNDAY';
    final now = DateTime.now();
    final dateString = '${now.month}/${now.day}/${now.year % 100}';

    await addJpegWidgetSlide(
      (size) => Directionality(
        textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/ppt_backgrounds/cloud.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [

              // Top-right: Date
              Positioned(
                top: 48,
                right: 48,
                child: Text(
                  dateString,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontFamily: 'The Seasons',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Center text
              Align(
                alignment: const Alignment(0, -0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (titlePart1.isNotEmpty)
                      Text(
                        titlePart1,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontFamily: 'The Seasons',
                          fontSize: 56,
                          letterSpacing: 24.0,
                        ),
                      ),
                    Text(
                      titlePart2,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'The Seasons',
                        fontSize: 200,
                        fontWeight: FontWeight.bold,
                        height: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom: Church silhouette (using Icon)
              Positioned(
                bottom: -80,
                left: 0,
                right: 0,
                child: const Center(
                  child: Icon(
                    Icons.church,
                    color: Colors.black87,
                    size: 400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    currentSlide++;
    reportProgress('Adding intro slides...');
    if (isCancelled != null && isCancelled()) return null;

    await addSectionSlide('SUNDAY SCHOOL');
    currentSlide++;
    reportProgress('Adding intro slides...');
    if (isCancelled != null && isCancelled()) return null;
    
    await addSectionSlide('ANNOUNCEMENT');
    currentSlide++;
    reportProgress('Adding intro slides...');
    if (isCancelled != null && isCancelled()) return null;
    
    await addSectionSlide('PRAISE & WORSHIP');
    currentSlide++;
    reportProgress('Processing songs...');
    if (isCancelled != null && isCancelled()) return null;

    // Add a slide for each song's sections
    for (int i = 0; i < songs.length; i++) {
      if (isCancelled != null && isCancelled()) return null;
      final song = songs[i];
      final slideGroups = allSongsSlideGroups[i];
      
      reportProgress('Creating slides for "${song.title}"...');

      // ── Dedicated Song Title Slide ──
      await addJpegWidgetSlide(
        (size) => Directionality(
          textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/ppt_backgrounds/cloud.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64),
                    child: Text(
                      song.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'The Seasons',
                        fontSize: 90,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8.0,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));

      currentSlide++;
      reportProgress('Creating slides for "${song.title}"...');
      if (isCancelled != null && isCancelled()) return null;

      for (final group in slideGroups) {
        if (isCancelled != null && isCancelled()) return null;
        final title = group['title'] as String;
        final lyrics = group['lyrics'] as List<String>;

        await addJpegWidgetSlide(
          (size) => Directionality(
            textDirection: TextDirection.ltr,
          child: Material(
            child: Container(
              width: size.width,
              height: size.height,
              padding: const EdgeInsets.all(48),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/ppt_backgrounds/cloud.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'The Seasons',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...lyrics.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'The Seasons',
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ));
        
        currentSlide++;
        reportProgress('Creating slides for "${song.title}"...');
      }
    }

    reportProgress('Adding outro slides...');
    if (isCancelled != null && isCancelled()) return null;
    await addSectionSlide('WORD');
    currentSlide++;
    reportProgress('Adding outro slides...');
    if (isCancelled != null && isCancelled()) return null;
    
    await addSectionSlide('TITHES & OFFERING');
    currentSlide++;
    reportProgress('Adding outro slides...');
    if (isCancelled != null && isCancelled()) return null;
    
    await addSectionSlide('ANNOUNCEMENT');
    currentSlide++;
    
    if (isCancelled != null && isCancelled()) return null;
    if (onProgress != null) {
      onProgress('Saving PowerPoint file...', 0.9);
    }

    final bytes = await pres.save();
    if (bytes == null) return null;
    
    if (onProgress != null) {
      onProgress('File saved, finalizing...', 0.95);
    }

    final tempDir = await getTemporaryDirectory();
    final safeTitle = ppt.title.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    final fileName = '$safeTitle.pptx';
    final tempFilePath = '${tempDir.path}/$fileName';
    final tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(bytes);

    // Prompt user to save or share
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

      final finalPath = outputPath.endsWith('.pptx') ? outputPath : '$outputPath.pptx';
      final fileToSave = File(finalPath);
      
      // Save the generated PPTX to user's chosen location
      await fileToSave.writeAsBytes(bytes);
      return finalPath;
    }
  }
}
