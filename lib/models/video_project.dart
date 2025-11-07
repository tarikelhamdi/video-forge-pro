import 'video_clip.dart';
import 'processing_job.dart';

/// Represents a complete video editing project
class VideoProject {
  final String id;
  final String name;
  final List<VideoClip> clips;
  final List<ProcessingJob> jobs;
  final DateTime createdAt;
  final DateTime lastModified;
  final ProjectMode mode;
  
  VideoProject({
    required this.id,
    required this.name,
    required this.clips,
    this.jobs = const [],
    required this.createdAt,
    required this.lastModified,
    this.mode = ProjectMode.multiVideo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'clips': clips.map((c) => c.toJson()).toList(),
      'jobs': jobs.map((j) => j.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'mode': mode.name,
    };
  }

  factory VideoProject.fromJson(Map<String, dynamic> json) {
    return VideoProject(
      id: json['id'],
      name: json['name'],
      clips: (json['clips'] as List).map((c) => VideoClip.fromJson(c)).toList(),
      jobs: (json['jobs'] as List).map((j) => ProcessingJob.fromJson(j)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      mode: ProjectMode.values.byName(json['mode']),
    );
  }

  VideoProject copyWith({
    String? id,
    String? name,
    List<VideoClip>? clips,
    List<ProcessingJob>? jobs,
    DateTime? createdAt,
    DateTime? lastModified,
    ProjectMode? mode,
  }) {
    return VideoProject(
      id: id ?? this.id,
      name: name ?? this.name,
      clips: clips ?? this.clips,
      jobs: jobs ?? this.jobs,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      mode: mode ?? this.mode,
    );
  }

  Duration get totalDuration => clips.fold<Duration>(
        Duration.zero,
        (sum, clip) => sum + clip.duration,
      );
}

enum ProjectMode {
  singleLongVideo,
  multiVideo,
}
