/// Represents a single audio file in the sound library.
class SoundEntry {
  const SoundEntry({
    required this.name,
    required this.path,
    required this.sizeInBytes,
    this.isAsset = false,
  });

  final String name;
  final String path;
  final int sizeInBytes;

  /// True when this sound is bundled with the app (not user-imported).
  final bool isAsset;

  Map<String, dynamic> toMap() => {
        'name': name,
        'path': path,
        'sizeInBytes': sizeInBytes,
        'isAsset': isAsset,
      };

  factory SoundEntry.fromMap(Map<String, dynamic> map) => SoundEntry(
        name: map['name'] as String? ?? '',
        path: map['path'] as String? ?? '',
        sizeInBytes: (map['sizeInBytes'] as num?)?.toInt() ?? 0,
        isAsset: map['isAsset'] as bool? ?? false,
      );
}
