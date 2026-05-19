import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/song.dart';

class PdfExportService {
  // ── Layout constants ─────────────────────────────────────────────────────
  // In the app: chord slot minWidth=22, spacing=4 → 26 px per slot, lyric font=18.
  // We scale everything to PDF lyric font=13: ratio = 13/18 ≈ 0.722
  // PDF slot width ≈ 26 × 0.722 ≈ 18.8 → round to 19.
  static const double _slotWidth = 19.0;
  static const double _chordRowHeight = 18.0;
  static const double _lyricFontSize = 12.0;
  static const double _chordFontSize = 10.0;

  // ── Colour palette (mirrors app dark theme) ───────────────────────────────
  static const _pageBg        = PdfColor.fromInt(0xFF1E212B);
  static const _chordBadgeBg  = PdfColor.fromInt(0xFF2A2D39);
  static const _chordTextCol  = PdfColor.fromInt(0xFFAEC4FF);
  static const _lyricTextCol  = PdfColor.fromInt(0xFFFFFFFF);
  static const _subtitleCol   = PdfColor.fromInt(0xFFCCD4E8);

  // ─────────────────────────────────────────────────────────────────────────
  static Future<pw.Document> generateChordChart(SongData song) async {
    final pdf = pw.Document();

    return generateChordCharts([song]);
  }

  static Future<pw.Document> generateChordCharts(List<SongData> songs) async {
    final pdf = pw.Document();

    final titleStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: _subtitleCol,
    );
    final chordStyle = pw.TextStyle(
      fontSize: _chordFontSize,
      fontWeight: pw.FontWeight.bold,
      color: _chordTextCol,
    );
    final lyricStyle = pw.TextStyle(
      fontSize: _lyricFontSize,
      color: _lyricTextCol,
    );

    for (final song in songs) {
      int splitIndex = (song.lines.length / 2).ceil();
      for (int i = 0; i < 5; i++) {
        final forward = splitIndex + i;
        if (forward < song.lines.length) {
          final text = song.lines[forward].lyrics.trim();
          if (text.isEmpty || (text.startsWith('[') && text.endsWith(']'))) {
            splitIndex = forward;
            break;
          }
        }
        final backward = splitIndex - i;
        if (backward > 0 && backward < song.lines.length) {
          final text = song.lines[backward].lyrics.trim();
          if (text.isEmpty || (text.startsWith('[') && text.endsWith(']'))) {
            splitIndex = backward;
            break;
          }
        }
      }

      final leftLines = song.lines.take(splitIndex).toList();
      final rightLines = song.lines.skip(splitIndex).toList();

      final content = <pw.Widget>[
        pw.Text(
          song.title,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _lyricTextCol,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Key of ${song.songKey}',
          style: titleStyle,
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: leftLines.map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: _buildLine(
                      line: line,
                      lyricStyle: lyricStyle,
                      chordStyle: chordStyle,
                    ),
                  ),
                ).toList(),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: rightLines.map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: _buildLine(
                      line: line,
                      lyricStyle: lyricStyle,
                      chordStyle: chordStyle,
                    ),
                  ),
                ).toList(),
              ),
            ),
          ],
        ),
      ];

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            buildBackground: (_) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: _pageBg),
            ),
          ),
          build: (_) => content,
        ),
      );
    }

    return pdf;
  }

  /// Builds a single lyrics line with chords using flow-based layout to match the app.
  static pw.Widget _buildLine({
    required SongLineData line,
    required pw.TextStyle lyricStyle,
    required pw.TextStyle chordStyle,
  }) {
    final chords = line.chords;
    final isSectionHeader = line.lyrics.trim().startsWith('[') && line.lyrics.trim().endsWith(']');

    // Build chord widgets using flow-based layout (similar to Wrap)
    final chordWidgets = <pw.Widget>[];
    for (final chord in chords) {
      if (chord.isEmpty) {
        chordWidgets.add(pw.SizedBox(width: 20));
      } else {
        chordWidgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              color: _chordBadgeBg,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(chord, style: chordStyle),
          ),
        );
        chordWidgets.add(pw.SizedBox(width: 4));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Chord row (only if not section header and has chords) ──
        if (!isSectionHeader && chords.any((c) => c.isNotEmpty))
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6.0),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: chordWidgets,
            ),
          ),
        // ── Lyric text ──
        if (line.lyrics.trim().isNotEmpty)
          pw.Text(
            line.lyrics,
            style: isSectionHeader
                ? pw.TextStyle(
                    fontSize: _lyricFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: _chordTextCol,
                    letterSpacing: 0.5,
                  )
                : lyricStyle,
          ),
      ],
    );
  }

  /// Writes the PDF bytes to [filePath].
  static Future<void> savePdf(pw.Document pdf, String filePath) async {
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
  }

  /// Cross-platform PDF export.
  /// On desktop (Windows/macOS/Linux): uses FilePicker save dialog.
  /// On mobile (Android/iOS): saves to temp dir and opens share sheet.
  /// Returns the path the file was saved to, or null if cancelled.
  static Future<String?> exportPdf({
    required pw.Document pdf,
    required String songTitle,
  }) async {
    final safeTitle = songTitle.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    final fileName = '$safeTitle.pdf';

    if (Platform.isAndroid || Platform.isIOS) {
      // ── Mobile: save to temp dir and share ──
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      await savePdf(pdf, filePath);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/pdf')],
          title: 'Export: $songTitle',
        ),
      );

      return filePath;
    } else {
      // ── Desktop: use save-file dialog ──
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Chord Chart as PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputPath == null) return null;

      final finalPath =
          outputPath.endsWith('.pdf') ? outputPath : '$outputPath.pdf';
      await savePdf(pdf, finalPath);
      return finalPath;
    }
  }
}
