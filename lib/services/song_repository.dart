import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';

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
    _loadFromHive();
  }

  void _loadFromHive() {
    _songs = _box.values.map((jsonStr) => SongData.fromJson(jsonStr)).toList();
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
