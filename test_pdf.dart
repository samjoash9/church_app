import 'dart:io';
import 'package:worship_pads/services/pdf_export_service.dart';
import 'package:worship_pads/models/song.dart';

void main() async {
  final song = SongData(
    id: '1',
    title: 'Test',
    songKey: 'C',
    lines: [SongLineData(lyrics: 'Test', chords: ['C'])]
  );
  try {
    final pdf = await PdfExportService.generateChordChart(song);
    await PdfExportService.savePdf(pdf, 'test.pdf');
    print('SUCCESS');
  } catch (e, stack) {
    print('ERROR: $e');
    print(stack);
  }
}
