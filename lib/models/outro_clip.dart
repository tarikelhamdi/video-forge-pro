/// Represents an outro clip that can be appended to videos
class OutroClip {
  final String id;
  final String filePath;
  final String fileName;
  final Duration duration;
  final String? thumbnailPath;
  final int orderIndex; // For tracking rotation order
  final DateTime addedAt;
  
  OutroClip({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.duration,
    this.thumbnailPath,
    required this.orderIndex,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'duration': duration.inMilliseconds,
      'thumbnailPath': thumbnailPath,
      'orderIndex': orderIndex,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory OutroClip.fromJson(Map<String, dynamic> json) {
    return OutroClip(
      id: json['id'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      duration: Duration(milliseconds: json['duration']),
      thumbnailPath: json['thumbnailPath'],
      orderIndex: json['orderIndex'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  OutroClip copyWith({
    String? id,
    String? filePath,
    String? fileName,
    Duration? duration,
    String? thumbnailPath,
    int? orderIndex,
    DateTime? addedAt,
  }) {
    return OutroClip(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      duration: duration ?? this.duration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      orderIndex: orderIndex ?? this.orderIndex,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
