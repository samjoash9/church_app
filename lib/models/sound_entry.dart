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
}
