// One-off tool: read the live Hive boxes copied into tool/hive_seed/ and dump
// each box's key/value pairs to assets/seed/*.json so the data can be bundled
// into the APK and seeded on first launch.
//
// Run from the project root with:
//   dart run tool/export_seed.dart
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';

Future<void> main() async {
  final boxDir = Directory('tool/hive_seed');
  if (!boxDir.existsSync()) {
    stderr.writeln(
      'Missing ${boxDir.path}. Copy the *.hive files there first.',
    );
    exit(1);
  }

  Hive.init(boxDir.path);

  final seedDir = Directory('assets/seed');
  if (!seedDir.existsSync()) seedDir.createSync(recursive: true);

  // Hive lowercases box names on disk: 'songsBox' -> 'songsbox.hive'.
  final boxes = <String, String>{
    'songsBox': 'songs.json',
    'pptsBox': 'ppts.json',
    'lineupBox': 'lineup.json',
  };

  final encoder = const JsonEncoder.withIndent('  ');

  for (final entry in boxes.entries) {
    final box = await Hive.openBox<String>(entry.key);
    final map = <String, String>{};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null) map[key.toString()] = value;
    }
    final outFile = File('assets/seed/${entry.value}');
    outFile.writeAsStringSync(encoder.convert(map));
    stdout.writeln('Wrote ${outFile.path} (${map.length} entries)');
    await box.close();
  }

  stdout.writeln('Done.');
}
