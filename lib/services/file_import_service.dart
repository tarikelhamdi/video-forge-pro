import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/video_clip.dart';
import '../models/outro_clip.dart';
import '../models/music_track.dart';

/// Service for importing files (videos, outros, music)
class FileImportService {
  final _uuid = const Uuid();

  /// Import a single video file
  Future<VideoClip?> importVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'flv'],
        dialogTitle: 'Select Video File',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        return await _createVideoClipFromFile(filePath);
      }
      return null;
    } catch (e) {
      print('Error importing video: $e');
      return null;
    }
  }

  /// Import multiple video files
  Future<List<VideoClip>> importMultipleVideos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'flv'],
        allowMultiple: true,
        dialogTitle: 'Select Video Files',
      );

      if (result != null) {
        final clips = <VideoClip>[];
        for (final file in result.files) {
          if (file.path != null) {
            final clip = await _createVideoClipFromFile(file.path!);
            if (clip != null) {
              clips.add(clip);
            }
          }
        }
        return clips;
      }
      return [];
    } catch (e) {
      print('Error importing videos: $e');
      return [];
    }
  }

  /// Import videos from a folder
  Future<List<VideoClip>> importVideosFromFolder() async {
    try {
      String? folderPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Folder Containing Videos',
      );

      if (folderPath != null) {
        final directory = Directory(folderPath);
        final files = directory
            .listSync()
            .whereType<File>()
            .where((file) => _isVideoFile(file.path))
            .toList();

        final clips = <VideoClip>[];
        for (final file in files) {
          final clip = await _createVideoClipFromFile(file.path);
          if (clip != null) {
            clips.add(clip);
          }
        }
        return clips;
      }
      return [];
    } catch (e) {
      print('Error importing folder: $e');
      return [];
    }
  }

  /// Import outro clip
  Future<OutroClip?> importOutroClip() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov'],
        dialogTitle: 'Select Outro Clip',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        
        return OutroClip(
          id: _uuid.v4(),
          filePath: filePath,
          fileName: _getFileName(filePath),
          duration: const Duration(seconds: 5), // TODO: Get actual duration
          orderIndex: 0,
          addedAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Error importing outro: $e');
      return null;
    }
  }

  /// Import music track
  Future<MusicTrack?> importMusicTrack() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'flac'],
        dialogTitle: 'Select Music Track',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        
        return MusicTrack(
          id: _uuid.v4(),
          filePath: filePath,
          fileName: _getFileName(filePath),
          duration: const Duration(minutes: 3), // TODO: Get actual duration
          orderIndex: 0,
          addedAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Error importing music: $e');
      return null;
    }
  }

  /// Select output folder for export
  Future<String?> selectOutputFolder() async {
    try {
      String? folderPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Output Folder',
      );
      return folderPath;
    } catch (e) {
      print('Error selecting output folder: $e');
      return null;
    }
  }

  /// Create VideoClip from file path
  Future<VideoClip?> _createVideoClipFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final fileSize = await file.length();
      
      // TODO: Get actual video info using FFmpeg
      // For now, using placeholder values
      return VideoClip(
        id: _uuid.v4(),
        filePath: filePath,
        fileName: _getFileName(filePath),
        duration: const Duration(seconds: 30), // Placeholder
        createdAt: DateTime.now(),
        fileSize: fileSize,
        resolution: VideoResolution(width: 1920, height: 1080), // Placeholder
        isPortrait: false, // Placeholder
      );
    } catch (e) {
      print('Error creating video clip: $e');
      return null;
    }
  }

  /// Check if file is a video
  bool _isVideoFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv', 'webm'].contains(extension);
  }

  /// Get file name from path
  String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }
}
