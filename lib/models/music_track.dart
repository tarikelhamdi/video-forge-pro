/// Represents a background music track
class MusicTrack {
  final String id;
  final String filePath;
  final String fileName;
  final Duration duration;
  final int orderIndex; // For tracking rotation order
  final DateTime addedAt;
  final String? artist;
  final String? title;
  
  MusicTrack({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.duration,
    required this.orderIndex,
    required this.addedAt,
    this.artist,
    this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'duration': duration.inMilliseconds,
      'orderIndex': orderIndex,
      'addedAt': addedAt.toIso8601String(),
      'artist': artist,
      'title': title,
    };
  }

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      duration: Duration(milliseconds: json['duration']),
      orderIndex: json['orderIndex'],
      addedAt: DateTime.parse(json['addedAt']),
      artist: json['artist'],
      title: json['title'],
    );
  }

  String get displayName => title ?? fileName;

  MusicTrack copyWith({
    String? id,
    String? filePath,
    String? fileName,
    Duration? duration,
    int? orderIndex,
    DateTime? addedAt,
    String? artist,
    String? title,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      duration: duration ?? this.duration,
      orderIndex: orderIndex ?? this.orderIndex,
      addedAt: addedAt ?? this.addedAt,
      artist: artist ?? this.artist,
      title: title ?? this.title,
    );
  }
}
