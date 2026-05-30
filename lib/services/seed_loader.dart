import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

/// Seeds a Hive [box] from a bundled JSON asset the first time the app runs.
///
/// The asset is a JSON object of `{ boxKey: jsonValueString }`, produced by
/// `tool/export_seed.dart`. Seeding only happens when the box is empty, so any
/// data the user adds or edits on-device is never overwritten on app updates.
Future<void> seedBoxIfEmpty(Box<String> box, String assetPath) async {
  if (box.isNotEmpty) return;

  final raw = await rootBundle.loadString(assetPath);
  final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;

  final entries = <String, String>{
    for (final e in data.entries)
      if (e.value is String) e.key: e.value as String,
  };
  await box.putAll(entries);
}
