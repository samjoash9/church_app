import 'package:hive_flutter/hive_flutter.dart';
import '../models/ppt.dart';
import 'seed_loader.dart';

class PptRepository {
  static final PptRepository _instance = PptRepository._internal();
  factory PptRepository() => _instance;
  PptRepository._internal();

  List<PptData> _ppts = [];
  late Box<String> _box;

  List<PptData> get ppts => List.unmodifiable(_ppts);

  Future<void> init() async {
    // Idempotent — safe even if another repository already initialized Hive.
    await Hive.initFlutter();
    _box = await Hive.openBox<String>('pptsBox');
    await seedBoxIfEmpty(_box, 'assets/seed/ppts.json');
    _loadFromHive();
  }

  void _loadFromHive() {
    // Skip any corrupted/malformed entries instead of crashing the whole load.
    _ppts = [];
    for (final jsonStr in _box.values) {
      try {
        _ppts.add(PptData.fromJson(jsonStr));
      } catch (_) {
        // Ignore unparseable presentation; keep loading the rest.
      }
    }
  }

  Future<void> savePpt(PptData ppt) async {
    final index = _ppts.indexWhere((p) => p.id == ppt.id);
    if (index != -1) {
      _ppts[index] = ppt;
    } else {
      _ppts.add(ppt);
    }
    await _box.put(ppt.id, ppt.toJson());
  }

  Future<void> deletePpt(String id) async {
    _ppts.removeWhere((p) => p.id == id);
    await _box.delete(id);
  }
}
