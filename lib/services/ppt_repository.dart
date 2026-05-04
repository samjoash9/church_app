import 'package:hive_flutter/hive_flutter.dart';
import '../models/ppt.dart';

class PptRepository {
  static final PptRepository _instance = PptRepository._internal();
  factory PptRepository() => _instance;
  PptRepository._internal();

  List<PptData> _ppts = [];
  late Box<String> _box;

  List<PptData> get ppts => List.unmodifiable(_ppts);

  Future<void> init() async {
    _box = await Hive.openBox<String>('pptsBox');
    _loadFromHive();
  }

  void _loadFromHive() {
    _ppts = _box.values.map((jsonStr) => PptData.fromJson(jsonStr)).toList();
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
