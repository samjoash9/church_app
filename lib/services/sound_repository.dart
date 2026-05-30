import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/sound_entry.dart';

/// Persists the worship-pad sound library (imported sounds + the active
/// selection per key) to Hive so user changes survive an app restart.
///
/// The whole library state is stored as a single JSON blob under one key. On
/// load the caller overlays this persisted state on top of the bundled default
/// pads, so deleting a default in a future session never resurrects a stale
/// user import and vice-versa.
class SoundRepository {
  static final SoundRepository _instance = SoundRepository._internal();
  factory SoundRepository() => _instance;
  SoundRepository._internal();

  static const _boxName = 'soundLibraryBox';
  static const _stateKey = 'state';

  late Box<String> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  /// The persisted library, or empty maps if nothing has been saved yet.
  ({Map<String, List<SoundEntry>> sounds, Map<String, String> active}) load() {
    final raw = _box.get(_stateKey);
    if (raw == null || raw.isEmpty) {
      return (sounds: {}, active: {});
    }
    try {
      final data = json.decode(raw) as Map<String, dynamic>;

      final foldersJson = data['folders'] as Map<String, dynamic>? ?? const {};
      final sounds = <String, List<SoundEntry>>{
        for (final entry in foldersJson.entries)
          entry.key: [
            for (final s in (entry.value as List<dynamic>? ?? const []))
              SoundEntry.fromMap(s as Map<String, dynamic>),
          ],
      };

      final activeJson = data['active'] as Map<String, dynamic>? ?? const {};
      final active = <String, String>{
        for (final entry in activeJson.entries)
          entry.key: entry.value as String,
      };

      return (sounds: sounds, active: active);
    } catch (_) {
      // Corrupted blob — fall back to empty so the app still boots.
      return (sounds: {}, active: {});
    }
  }

  Future<void> save({
    required Map<String, List<SoundEntry>> sounds,
    required Map<String, String> active,
  }) async {
    final data = {
      'folders': {
        for (final entry in sounds.entries)
          entry.key: [for (final s in entry.value) s.toMap()],
      },
      'active': active,
    };
    await _box.put(_stateKey, json.encode(data));
  }
}
