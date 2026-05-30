import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';
import 'seed_loader.dart';

class SongRepository {
  static final SongRepository _instance = SongRepository._internal();
  factory SongRepository() => _instance;
  SongRepository._internal();

  List<SongData> _songs = [];
  late Box<String> _box;

  List<SongData> get songs => List.unmodifiable(_songs);

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>('songsBox');
    await seedBoxIfEmpty(_box, 'assets/seed/songs.json');
    _loadFromHive();
  }

  void _loadFromHive() {
    // Skip any corrupted/malformed entries instead of crashing the whole load.
    _songs = [];
    for (final jsonStr in _box.values) {
      try {
        _songs.add(SongData.fromJson(jsonStr));
      } catch (_) {
        // Ignore unparseable song; keep loading the rest.
      }
    }
  }

  Future<void> saveSong(SongData song) async {
    final index = _songs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      _songs[index] = song;
    } else {
      _songs.add(song);
    }
    await _box.put(song.id, song.toJson());
  }

  Future<void> deleteSong(String id) async {
    _songs.removeWhere((s) => s.id == id);
    await _box.delete(id);
  }
}
