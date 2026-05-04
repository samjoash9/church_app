import 'dart:io';
import 'package:flutter_pptx/flutter_pptx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/song.dart';
import '../models/ppt.dart';
import 'package:flutter/material.dart';

class PptExportService {
  /// Generates a .pptx file for the given PPT and its songs.
  /// Returns the file path where the PPTX was saved, or null if cancelled.
  static Future<String?> exportPptx({
    required PptData ppt,
    required List<SongData> songs,
  }) async {
    final pres = FlutterPowerPoint();

    Future<void> addSectionSlide(String title) async {
      await pres.addWidgetSlide((size) => Directionality(
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
                    fontSize: 100,
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
    
    // Title slide
    String titlePart1 = 'B L E S S E D';
    String titlePart2 = 'SUNDAY';
    final now = DateTime.now();
    final dateString = '${now.month}/${now.day}/${now.year % 100}';

    await pres.addWidgetSlide((size) => Directionality(
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
                alignment: Alignment.center,
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
                        fontSize: 220,
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

    await addSectionSlide('SUNDAY SCHOOL');
    await addSectionSlide('ANNOUNCEMENT');
    await addSectionSlide('PRAISE & WORSHIP');

    // Add a slide for each song's sections
    for (final song in songs) {
      // ── Dedicated Song Title Slide ──
      await pres.addWidgetSlide((size) => Directionality(
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
          if (currentLyrics.length >= 5) {
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

      for (final group in slideGroups) {
        final title = group['title'] as String;
        final lyrics = group['lyrics'] as List<String>;

        await pres.addWidgetSlide((size) => Directionality(
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
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: lyrics.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        l,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'The Seasons',
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    }

    await addSectionSlide('WORD');
    await addSectionSlide('TITHES & OFFERING');
    await addSectionSlide('ANNOUNCEMENT');

    final bytes = await pres.save();
    if (bytes == null) return null;

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
