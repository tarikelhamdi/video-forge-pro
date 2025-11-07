import 'video_clip.dart';
import 'outro_clip.dart';
import 'music_track.dart';
import 'app_settings.dart';

/// Represents a video processing job
class ProcessingJob {
  final String id;
  final List<VideoClip> inputClips;
  final OutroClip? outro;
  final MusicTrack? music;
  final ExportSettings exportSettings;
  final ProcessingStatus status;
  final double progress; // 0.0 to 1.0
  final String? currentStep;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String outputPath;
  
  ProcessingJob({
    required this.id,
    required this.inputClips,
    this.outro,
    this.music,
    required this.exportSettings,
    this.status = ProcessingStatus.pending,
    this.progress = 0.0,
    this.currentStep,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    required this.outputPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inputClips': inputClips.map((c) => c.toJson()).toList(),
      'outro': outro?.toJson(),
      'music': music?.toJson(),
      'exportSettings': exportSettings.toJson(),
      'status': status.name,
      'progress': progress,
      'currentStep': currentStep,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'outputPath': outputPath,
    };
  }

  factory ProcessingJob.fromJson(Map<String, dynamic> json) {
    return ProcessingJob(
      id: json['id'],
      inputClips: (json['inputClips'] as List)
          .map((c) => VideoClip.fromJson(c))
          .toList(),
      outro: json['outro'] != null ? OutroClip.fromJson(json['outro']) : null,
      music: json['music'] != null ? MusicTrack.fromJson(json['music']) : null,
      exportSettings: ExportSettings.fromJson(json['exportSettings']),
      status: ProcessingStatus.values.byName(json['status']),
      progress: json['progress'],
      currentStep: json['currentStep'],
      errorMessage: json['errorMessage'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      outputPath: json['outputPath'],
    );
  }

  ProcessingJob copyWith({
    String? id,
    List<VideoClip>? inputClips,
    OutroClip? outro,
    MusicTrack? music,
    ExportSettings? exportSettings,
    ProcessingStatus? status,
    double? progress,
    String? currentStep,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
    String? outputPath,
  }) {
    return ProcessingJob(
      id: id ?? this.id,
      inputClips: inputClips ?? this.inputClips,
      outro: outro ?? this.outro,
      music: music ?? this.music,
      exportSettings: exportSettings ?? this.exportSettings,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      outputPath: outputPath ?? this.outputPath,
    );
  }

  Duration get totalDuration {
    var total = inputClips.fold<Duration>(
      Duration.zero,
      (sum, clip) => sum + clip.duration,
    );
    if (outro != null) total += outro!.duration;
    return total;
  }
}

enum ProcessingStatus {
  pending,
  splitting,
  addingOutro,
  addingMusic,
  encoding,
  completed,
  failed,
  cancelled,
}
