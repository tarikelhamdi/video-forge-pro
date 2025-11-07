import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import '../models/video_clip.dart';
import '../models/processing_job.dart';
import '../models/app_settings.dart';
import 'ffi/video_processing_ffi.dart';

/// High-level video processing service
class VideoProcessingService {
  final _processingController = StreamController<ProcessingUpdate>.broadcast();
  
  Stream<ProcessingUpdate> get processingUpdates => _processingController.stream;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      VideoProcessingFFI.initialize();
      final result = VideoProcessingFFI.initProcessor();
      if (result != 0) {
        throw Exception('Failed to initialize video processor: $result');
      }
      _isInitialized = true;
      print('✓ Video processor initialized');
    } catch (e) {
      print('Warning: Native video processor not available: $e');
      rethrow;
    }
  }

  /// Split a video into multiple clips
  Future<List<String>> splitVideo({
    required String inputPath,
    required String outputDir,
    required int clipDurationSeconds,
  }) async {
    _ensureInitialized();
    
    _updateProgress(ProcessingStatus.splitting, 0, 'Splitting video...');
    
    final inputPathPtr = inputPath.toNativeUtf8();
    final outputDirPtr = outputDir.toNativeUtf8();
    
    // Ensure output directory exists
    Directory(outputDir).createSync(recursive: true);
    
    try {
      // For now, we call without callback (simplified version)
      final numClips = VideoProcessingFFI.splitVideo(
        inputPathPtr,
        outputDirPtr,
        clipDurationSeconds,
        ffi.nullptr,  // No callback for now
      );
      
      if (numClips < 0) {
        throw Exception('Failed to split video: error code $numClips');
      }
      
      // Get list of created clips
      final clips = <String>[];
      for (int i = 1; i <= numClips; i++) {
        clips.add(path.join(outputDir, 'clip_$i.mp4'));
      }
      
      _updateProgress(ProcessingStatus.completed, 100, 'Split complete!');
      
      return clips;
    } finally {
      malloc.free(inputPathPtr);
      malloc.free(outputDirPtr);
    }
  }

  /// Add outro to a video
  Future<String> addOutro({
    required String videoPath,
    required String outroPath,
    required String outputPath,
  }) async {
    _ensureInitialized();
    
    _updateProgress(ProcessingStatus.addingOutro, 0, 'Adding outro...');
    
    final videoPathPtr = videoPath.toNativeUtf8();
    final outroPathPtr = outroPath.toNativeUtf8();
    final outputPathPtr = outputPath.toNativeUtf8();
    
    try {
      final result = VideoProcessingFFI.addOutro(
        videoPathPtr,
        outroPathPtr,
        outputPathPtr,
        ffi.nullptr,  // No callback for now
      );
      
      if (result != 0) {
        throw Exception('Failed to add outro: error code $result');
      }
      
      _updateProgress(ProcessingStatus.completed, 100, 'Outro added!');
      
      return outputPath;
    } finally {
      malloc.free(videoPathPtr);
      malloc.free(outroPathPtr);
      malloc.free(outputPathPtr);
    }
  }

  /// Add background music to a video
  Future<String> addBackgroundMusic({
    required String videoPath,
    required String musicPath,
    required String outputPath,
    int fadeInSeconds = 2,
    int fadeOutSeconds = 3,
  }) async {
    _ensureInitialized();
    
    _updateProgress(ProcessingStatus.addingMusic, 0, 'Adding music...');
    
    final videoPathPtr = videoPath.toNativeUtf8();
    final musicPathPtr = musicPath.toNativeUtf8();
    final outputPathPtr = outputPath.toNativeUtf8();
    
    try {
      final result = VideoProcessingFFI.addBackgroundMusic(
        videoPathPtr,
        musicPathPtr,
        outputPathPtr,
        fadeInSeconds,
        fadeOutSeconds,
        ffi.nullptr,  // No callback for now
      );
      
      if (result != 0) {
        throw Exception('Failed to add music: error code $result');
      }
      
      _updateProgress(ProcessingStatus.completed, 100, 'Music added!');
      
      return outputPath;
    } finally {
      malloc.free(videoPathPtr);
      malloc.free(musicPathPtr);
      malloc.free(outputPathPtr);
    }
  }

  /// Convert video to portrait format (9:16)
  Future<String> convertToPortrait({
    required String inputPath,
    required String outputPath,
    int width = 1080,
    int height = 1920,
    CropMode cropMode = CropMode.smartCrop,
  }) async {
    _ensureInitialized();
    
    _updateProgress(ProcessingStatus.encoding, 0, 'Converting to portrait...');
    
    final inputPathPtr = inputPath.toNativeUtf8();
    final outputPathPtr = outputPath.toNativeUtf8();
    
    try {
      final result = VideoProcessingFFI.convertToPortrait(
        inputPathPtr,
        outputPathPtr,
        width,
        height,
        cropMode.index,
        ffi.nullptr,  // No callback for now
      );
      
      if (result != 0) {
        throw Exception('Failed to convert: error code $result');
      }
      
      _updateProgress(ProcessingStatus.completed, 100, 'Converted!');
      
      return outputPath;
    } finally {
      malloc.free(inputPathPtr);
      malloc.free(outputPathPtr);
    }
  }

  /// Process complete workflow: split, add outro/music, convert to portrait
  Future<List<String>> processCompleteWorkflow({
    required String inputPath,
    required String outputDir,
    String? outroPath,
    String? musicPath,
    required AppSettings settings,
    required EditMode mode,
  }) async {
    _ensureInitialized();
    
    final outputVideos = <String>[];
    
    try {
      // Step 1: Split or prepare videos
      List<String> videoClips;
      
      if (mode == EditMode.splitVideo) {
        _updateProgress(ProcessingStatus.splitting, 10, 'Step 1/4: Splitting video...');
        videoClips = await splitVideo(
          inputPath: inputPath,
          outputDir: path.join(outputDir, 'temp_clips'),
          clipDurationSeconds: 15,  // Default 15 seconds clips
        );
      } else {
        videoClips = [inputPath];
      }
      
      // Process each clip
      for (int i = 0; i < videoClips.length; i++) {
        final clipPath = videoClips[i];
        String processedPath = clipPath;
        
        _updateProgress(
          ProcessingStatus.encoding,
          20 + (i / videoClips.length * 60),
          'Processing clip ${i + 1}/${videoClips.length}',
        );
        
        // Step 2: Add outro (if available)
        if (outroPath != null && outroPath.isNotEmpty) {
          final outroOutput = path.join(
            outputDir,
            'temp_with_outro_${i + 1}.mp4',
          );
          processedPath = await addOutro(
            videoPath: processedPath,
            outroPath: outroPath,
            outputPath: outroOutput,
          );
        }
        
        // Step 3: Add music (if available)
        if (musicPath != null && musicPath.isNotEmpty) {
          final musicOutput = path.join(
            outputDir,
            'temp_with_music_${i + 1}.mp4',
          );
          processedPath = await addBackgroundMusic(
            videoPath: processedPath,
            musicPath: musicPath,
            outputPath: musicOutput,
            fadeInSeconds: 2,
            fadeOutSeconds: 3,
          );
        }
        
        // Step 4: Convert to portrait
        final finalOutput = path.join(
          outputDir,
          'output_${DateTime.now().millisecondsSinceEpoch}_${i + 1}.mp4',
        );
        
        await convertToPortrait(
          inputPath: processedPath,
          outputPath: finalOutput,
          width: settings.exportSettings.resolution.portraitWidth,
          height: settings.exportSettings.resolution.portraitHeight,
          cropMode: settings.exportSettings.cropMode,
        );
        
        outputVideos.add(finalOutput);
      }
      
      // Clean up temp files if enabled
      if (settings.autoDeleteTempFiles) {
        _cleanupTempFiles(outputDir);
      }
      
      _updateProgress(
        ProcessingStatus.completed,
        100,
        'Processing complete! Created ${outputVideos.length} video(s)',
      );
      
      // Open output folder if enabled
      if (settings.autoOpenFolderAfterExport) {
        await Process.run('explorer', [outputDir]);
      }
      
      return outputVideos;
      
    } catch (e) {
      _updateProgress(ProcessingStatus.failed, 0, 'Error: $e');
      rethrow;
    }
  }

  /// Get video information
  Future<VideoInfoData> getVideoInfo(String videoPath) async {
    _ensureInitialized();
    
    final videoPathPtr = videoPath.toNativeUtf8();
    final infoPtr = calloc<VideoInfo>();
    
    try {
      final result = VideoProcessingFFI.getVideoInfo(videoPathPtr, infoPtr);
      
      if (result != 0) {
        throw Exception('Failed to get video info: error code $result');
      }
      
      final info = infoPtr.ref;
      return VideoInfoData(
        resolution: VideoResolution(width: info.width, height: info.height),
        duration: Duration(milliseconds: info.durationMs),
        fps: info.fps.toInt(),
        bitrate: info.bitrate,
        hasAudio: info.hasAudio == 1,
      );
    } finally {
      malloc.free(videoPathPtr);
      calloc.free(infoPtr);
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('VideoProcessingService not initialized. Call init() first.');
    }
  }

  void _updateProgress(ProcessingStatus status, double progress, String step) {
    _processingController.add(ProcessingUpdate(
      status: status,
      progress: progress,
      currentStep: step,
    ));
  }

  void _cleanupTempFiles(String outputDir) {
    try {
      final dir = Directory(outputDir);
      final tempFiles = dir.listSync().where((file) {
        final name = path.basename(file.path);
        return name.startsWith('temp_') || name.startsWith('clip_');
      });
      
      for (final file in tempFiles) {
        file.deleteSync();
      }
    } catch (e) {
      print('Warning: Failed to clean up temp files: $e');
    }
  }

  void dispose() {
    VideoProcessingFFI.cleanup();
    _processingController.close();
  }
}

class VideoInfoData {
  final VideoResolution resolution;
  final Duration duration;
  final int fps;
  final int bitrate;
  final bool hasAudio;

  VideoInfoData({
    required this.resolution,
    required this.duration,
    required this.fps,
    required this.bitrate,
    required this.hasAudio,
  });
}

class ProcessingUpdate {
  final ProcessingStatus status;
  final double progress;
  final String currentStep;

  ProcessingUpdate({
    required this.status,
    required this.progress,
    required this.currentStep,
  });
}
