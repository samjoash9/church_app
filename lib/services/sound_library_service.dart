import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/sound_entry.dart';
import 'sound_repository.dart';

class SoundLibraryService extends ChangeNotifier {
  static final SoundLibraryService _instance = SoundLibraryService._internal();
  factory SoundLibraryService() => _instance;
  SoundLibraryService._internal();

  final _repository = SoundRepository();

  Map<String, List<SoundEntry>> _librarySounds = {};
  Map<String, String> _activeSoundPaths = {};

  /// Initializes the library from bundled defaults, then overlays anything the
  /// user persisted in a previous session so imports and active selections
  /// survive an app restart.
  ///
  /// [initialLibrarySounds] / [initialActiveSoundPaths] are the immutable
  /// bundled pads. Persisted user state takes precedence per folder; the
  /// bundled default entries are always re-injected (deduped by path) so they
  /// can never be lost across app updates.
  void init({
    required Map<String, List<SoundEntry>> initialLibrarySounds,
    required Map<String, String> initialActiveSoundPaths,
  }) {
    _librarySounds = {
      for (final entry in initialLibrarySounds.entries)
        entry.key: List<SoundEntry>.from(entry.value),
    };
    _activeSoundPaths = Map<String, String>.from(initialActiveSoundPaths);

    final persisted = _repository.load();

    // Overlay persisted folders, keeping bundled default entries present.
    persisted.sounds.forEach((folderId, savedEntries) {
      final defaults = _librarySounds[folderId] ?? const <SoundEntry>[];
      final merged = <SoundEntry>[...savedEntries];
      for (final def in defaults) {
        if (!merged.any((e) => e.path == def.path)) merged.add(def);
      }
      _librarySounds[folderId] = merged;
    });

    // Persisted active selection wins over the bundled default.
    _activeSoundPaths.addAll(persisted.active);
  }

  Future<void> _persist() => _repository.save(
        sounds: _librarySounds,
        active: _activeSoundPaths,
      );

  List<SoundEntry> soundsFor(String mode, String key) {
    return List.unmodifiable(_librarySounds['$mode::$key'] ?? const []);
  }

  String? activeSoundPathFor(String mode, String key) {
    return _activeSoundPaths['$mode::$key'];
  }

  SoundEntry? activeSoundFor(String mode, String key) {
    final activePath = activeSoundPathFor(mode, key);
    if (activePath == null) return null;
    for (final sound in soundsFor(mode, key)) {
      if (sound.path == activePath) return sound;
    }
    return null;
  }

  void setActiveSoundForFolder(String mode, String key, SoundEntry sound) {
    _activeSoundPaths['$mode::$key'] = sound.path;
    notifyListeners();
    _persist();
  }

  void clearActiveSoundForFolder(String mode, String key) {
    _activeSoundPaths.remove('$mode::$key');
    notifyListeners();
    _persist();
  }

  void removeSoundFromFolder(String mode, String key, SoundEntry sound) {
    final folderId = '$mode::$key';
    final sounds = _librarySounds[folderId];
    if (sounds == null) return;

    final deletedIndex = sounds.indexWhere((entry) => entry.path == sound.path);
    final wasActive = _activeSoundPaths[folderId] == sound.path;

    sounds.removeWhere((entry) => entry.path == sound.path);
    if (sounds.isEmpty) {
      _librarySounds.remove(folderId);
      _activeSoundPaths.remove(folderId);
    } else if (wasActive) {
      final fallbackIndex = deletedIndex.clamp(0, sounds.length - 1);
      _activeSoundPaths[folderId] = sounds[fallbackIndex].path;
    }
    notifyListeners();
    _persist();
  }

  Future<void> addSoundToFolder(BuildContext context, String mode, String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      allowMultiple: false,
      dialogTitle: 'Select a sound for $mode - $key',
    );

    if (result == null || result.files.isEmpty) return;

    final selectedFile = result.files.single;
    final filePath = selectedFile.path;
    if (filePath == null || filePath.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That file could not be imported.')),
        );
      }
      return;
    }

    int fileSizeInBytes = 0;
    try { fileSizeInBytes = await File(filePath).length(); }
    on FileSystemException { fileSizeInBytes = 0; }

    final folderId = '$mode::$key';
    final sounds = _librarySounds.putIfAbsent(folderId, () => []);
    sounds.add(SoundEntry(name: selectedFile.name, path: filePath, sizeInBytes: fileSizeInBytes));
    _activeSoundPaths.putIfAbsent(folderId, () => filePath);

    notifyListeners();
    _persist();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedFile.name} added to $mode - $key')),
      );
    }
  }
}
