import 'dart:convert';

class SongData {
  final String id;
  final String title;
  final String songKey;
  final List<SongLineData> lines;

  SongData({
    required this.id,
    required this.title,
    required this.songKey,
    required this.lines,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'songKey': songKey,
      'lines': lines.map((x) => x.toMap()).toList(),
    };
  }

  factory SongData.fromMap(Map<String, dynamic> map) {
    return SongData(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      songKey: map['songKey'] ?? '',
      lines: List<SongLineData>.from(map['lines']?.map((x) => SongLineData.fromMap(x)) ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory SongData.fromJson(String source) => SongData.fromMap(json.decode(source));
}

class SongLineData {
  final String lyrics;
  final List<String> chords;

  SongLineData({
    required this.lyrics,
    required this.chords,
  });

  Map<String, dynamic> toMap() {
    return {
      'lyrics': lyrics,
      'chords': chords,
    };
  }

  factory SongLineData.fromMap(Map<String, dynamic> map) {
    return SongLineData(
      lyrics: map['lyrics'] ?? '',
      chords: List<String>.from(map['chords'] ?? []),
    );
  }
}
