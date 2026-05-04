import 'dart:convert';

class PptData {
  final String id;
  final String title;
  final List<String> songIds;

  PptData({
    required this.id,
    required this.title,
    required this.songIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'songIds': songIds,
    };
  }

  factory PptData.fromMap(Map<String, dynamic> map) {
    return PptData(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      songIds: List<String>.from(map['songIds'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory PptData.fromJson(String source) => PptData.fromMap(json.decode(source));
}
