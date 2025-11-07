/// Represents a single video clip in the project
class VideoClip {
  final String id;
  final String filePath;
  final String fileName;
  final Duration duration;
  final String? thumbnailPath;
  final DateTime createdAt;
  final int fileSize; // in bytes
  final VideoResolution resolution;
  final bool isPortrait;
  
  VideoClip({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.duration,
    this.thumbnailPath,
    required this.createdAt,
    required this.fileSize,
    required this.resolution,
    required this.isPortrait,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'duration': duration.inMilliseconds,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'fileSize': fileSize,
      'width': resolution.width,
      'height': resolution.height,
      'isPortrait': isPortrait,
    };
  }

  factory VideoClip.fromJson(Map<String, dynamic> json) {
    return VideoClip(
      id: json['id'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      duration: Duration(milliseconds: json['duration']),
      thumbnailPath: json['thumbnailPath'],
      createdAt: DateTime.parse(json['createdAt']),
      fileSize: json['fileSize'],
      resolution: VideoResolution(
        width: json['width'],
        height: json['height'],
      ),
      isPortrait: json['isPortrait'],
    );
  }

  VideoClip copyWith({
    String? id,
    String? filePath,
    String? fileName,
    Duration? duration,
    String? thumbnailPath,
    DateTime? createdAt,
    int? fileSize,
    VideoResolution? resolution,
    bool? isPortrait,
  }) {
    return VideoClip(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      duration: duration ?? this.duration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      resolution: resolution ?? this.resolution,
      isPortrait: isPortrait ?? this.isPortrait,
    );
  }
}

class VideoResolution {
  final int width;
  final int height;

  VideoResolution({required this.width, required this.height});

  double get aspectRatio => width / height;
  
  bool get isPortrait => height > width;
  
  @override
  String toString() => '${width}x$height';
}
