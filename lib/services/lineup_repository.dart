import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'seed_loader.dart';

class LineupRepository {
  static final LineupRepository _instance = LineupRepository._internal();
  factory LineupRepository() => _instance;
  LineupRepository._internal();

  List<String> _songIds = [];
  late Box<String> _box;

  List<String> get songIds => List.unmodifiable(_songIds);

  Future<void> init() async {
    // Idempotent — safe even if another repository already initialized Hive.
    await Hive.initFlutter();
    _box = await Hive.openBox<String>('lineupBox');
    await seedBoxIfEmpty(_box, 'assets/seed/lineup.json');
    _loadFromHive();
  }

  void _loadFromHive() {
    final String? jsonStr = _box.get('currentLineup');
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = json.decode(jsonStr);
        _songIds = decoded.cast<String>();
      } catch (e) {
        _songIds = [];
      }
    } else {
      _songIds = [];
    }
  }

  Future<void> _saveToHive() async {
    await _box.put('currentLineup', json.encode(_songIds));
  }

  Future<void> addToLineup(String songId) async {
    if (!_songIds.contains(songId)) {
      _songIds.add(songId);
      await _saveToHive();
    }
  }

  Future<void> removeFromLineup(String songId) async {
    _songIds.remove(songId);
    await _saveToHive();
  }

  Future<void> clearLineup() async {
    _songIds.clear();
    await _saveToHive();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final String item = _songIds.removeAt(oldIndex);
    _songIds.insert(newIndex, item);
    await _saveToHive();
  }
}
