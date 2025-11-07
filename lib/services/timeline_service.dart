import 'dart:io';
import '../models/timeline.dart';
import '../models/app_settings.dart';

/// Timeline Service - Handles video processing for timeline
class TimelineService {
  /// Process a single timeline with all operations
  Future<String> processTimeline({
    required List<String> videoTracks,
    String? audioTrack,
    required List<VideoOperation> operations,
    required String outputPath,
    required Function(double) onProgress,
    ExportSettings? exportSettings, // إضافة الإعدادات
  }) async {
    onProgress(10);
    
    // استخدام الإعدادات أو القيم الافتراضية
    final settings = exportSettings ?? ExportSettings();
    final resolution = settings.resolution;
    final bitrate = settings.bitrate;
    final audioBitrate = settings.audioBitrate;
    
    // Build FFmpeg command
    final List<String> ffmpegArgs = [];
    
    // Input files
    for (var video in videoTracks) {
      ffmpegArgs.addAll(['-i', video]);
    }
    
    // Add audio with stream_loop for infinite looping
    if (audioTrack != null && audioTrack.isNotEmpty) {
      ffmpegArgs.addAll(['-stream_loop', '-1', '-i', audioTrack]);
    }
    
    onProgress(30);
    
    // Build filter_complex (no audio processing here)
    String filterComplex = _buildFilterComplex(
      videoCount: videoTracks.length,
      hasAudio: false, // Audio handled separately
      operations: operations,
      targetResolution: resolution, // تمرير resolution
    );
    
    if (filterComplex.isNotEmpty) {
      ffmpegArgs.addAll(['-filter_complex', filterComplex]);
    }
    
    onProgress(50);
    
    // Output settings
    List<String> outputArgs = [
      '-map', '[outv]',
    ];
    
    // Add audio mapping - will be trimmed by -shortest
    if (audioTrack != null && audioTrack.isNotEmpty) {
      final audioIndex = videoTracks.length;
      outputArgs.addAll(['-map', '$audioIndex:a']);
      outputArgs.addAll(['-c:a', 'aac', '-b:a', '${audioBitrate}k']);
      outputArgs.addAll(['-shortest']); // Trim to shortest stream (video)
    } else {
      // No audio
      outputArgs.addAll(['-an']);
    }
    
    outputArgs.addAll([
      '-c:v', 'libx264',
      '-preset', 'fast',
      '-b:v', '${bitrate}k', // استخدام bitrate من الإعدادات
      '-maxrate', '${(bitrate * 1.5).toInt()}k',
      '-bufsize', '${(bitrate * 2).toInt()}k',
      '-pix_fmt', 'yuv420p',
      '-y',
      outputPath,
    ]);
    
    ffmpegArgs.addAll(outputArgs);
    
    // Run FFmpeg
    final process = await Process.start('ffmpeg', ffmpegArgs);
    
    // Capture output
    final stderr = <String>[];
    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      stderr.add(data);
      // Parse progress from FFmpeg output
      if (data.contains('time=')) {
        onProgress(70);
      }
    });
    
    final exitCode = await process.exitCode;
    
    if (exitCode != 0) {
      throw Exception('FFmpeg failed: ${stderr.join('\\n')}');
    }
    
    onProgress(100);
    return outputPath;
  }
  
  /// Build filter_complex string based on operations
  String _buildFilterComplex({
    required int videoCount,
    required bool hasAudio,
    required List<VideoOperation> operations,
    ExportResolution? targetResolution,
  }) {
    List<String> filters = [];
    
    // If no videos, return empty
    if (videoCount == 0) return '';
    
    // Process each video input
    for (int i = 0; i < videoCount; i++) {
      String currentLabel = '$i:v';
      List<String> videoFilters = [];
      
      // Apply target resolution (Portrait 9:16) from settings FIRST
      if (targetResolution != null) {
        final w = targetResolution.portraitWidth;
        final h = targetResolution.portraitHeight;
        videoFilters.add('scale=$w:$h:force_original_aspect_ratio=increase,crop=$w:$h');
      }
      
      // Apply operations to each video
      for (var op in operations) {
        switch (op.type) {
          case OperationType.portrait:
            // Portrait operation is now redundant since we always apply portrait format
            // Skip it to avoid double scaling
            break;
          case OperationType.speed:
            final speed = op.parameters['speed'] ?? 1.0;
            videoFilters.add('setpts=${(1/speed).toStringAsFixed(2)}*PTS');
            break;
          case OperationType.brightness:
            final brightness = op.parameters['brightness'] ?? 0.0;
            videoFilters.add('eq=brightness=$brightness');
            break;
          case OperationType.contrast:
            final contrast = op.parameters['contrast'] ?? 1.0;
            videoFilters.add('eq=contrast=$contrast');
            break;
          case OperationType.saturation:
            final saturation = op.parameters['saturation'] ?? 1.0;
            videoFilters.add('eq=saturation=$saturation');
            break;
          case OperationType.fade:
            videoFilters.add('fade=t=in:st=0:d=0.5,fade=t=out:st=9:d=0.5');
            break;
          case OperationType.zoom:
            videoFilters.add('zoompan=z=min(zoom+0.0015,1.5):d=125:x=iw/2-(iw/zoom/2):y=ih/2-(ih/zoom/2)');
            break;
          default:
            break;
        }
      }
      
      // Build the filter for this video
      if (videoFilters.isNotEmpty) {
        filters.add('[$currentLabel]${videoFilters.join(',')}[v$i]');
      } else {
        filters.add('[$currentLabel]copy[v$i]');
      }
    }
    
    // Concatenate videos if multiple
    if (videoCount > 1) {
      String concatInputs = '';
      for (int i = 0; i < videoCount; i++) {
        concatInputs += '[v$i]';
      }
      filters.add('${concatInputs}concat=n=$videoCount:v=1:a=0[outv]');
    } else {
      // Single video - just rename the label
      filters.add('[v0]copy[outv]');
    }
    
    // Handle audio separately (not in filter_complex)
    // Audio will be handled with -stream_loop and -shortest
    
    return filters.join(';');
  }
  
  /// Preview timeline (generate quick preview)
  Future<String> previewTimeline({
    required List<String> videoTracks,
    String? audioTrack,
    required List<VideoOperation> operations,
    required String outputPath,
    ExportSettings? exportSettings,
    required Function(double) onProgress,
    int duration = 10, // Preview first 10 seconds
  }) async {
    onProgress(10);
    
    // Get settings with defaults
    final settings = exportSettings ?? ExportSettings();
    final resolution = settings.resolution;
    
    // Similar to processTimeline but with -t 10 for quick preview
    final List<String> ffmpegArgs = [];
    
    // Input files
    for (var video in videoTracks) {
      ffmpegArgs.addAll(['-i', video]);
    }
    
    // Add audio with stream_loop
    if (audioTrack != null && audioTrack.isNotEmpty) {
      ffmpegArgs.addAll(['-stream_loop', '-1', '-i', audioTrack]);
    }
    
    // Limit duration for preview
    ffmpegArgs.addAll(['-t', duration.toString()]);
    
    onProgress(30);
    
    // Build filter_complex (no audio processing)
    String filterComplex = _buildFilterComplex(
      videoCount: videoTracks.length,
      hasAudio: false, // Audio handled separately
      operations: operations,
      targetResolution: resolution,
    );
    
    if (filterComplex.isNotEmpty) {
      ffmpegArgs.addAll(['-filter_complex', filterComplex]);
    }
    
    onProgress(50);
    
    // Output settings (faster preset for preview)
    List<String> outputArgs = [
      '-map', '[outv]',
    ];
    
    if (audioTrack != null && audioTrack.isNotEmpty) {
      final audioIndex = videoTracks.length;
      outputArgs.addAll(['-map', '$audioIndex:a']);
      outputArgs.addAll(['-c:a', 'aac', '-b:a', '128k']);
      outputArgs.addAll(['-shortest']);
    } else {
      outputArgs.addAll(['-an']);
    }
    
    outputArgs.addAll([
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-crf', '28',
      '-pix_fmt', 'yuv420p',
      '-y',
      outputPath,
    ]);
    
    ffmpegArgs.addAll(outputArgs);
    
    // Run FFmpeg
    final result = await Process.run('ffmpeg', ffmpegArgs);
    
    onProgress(100);
    
    if (result.exitCode != 0) {
      throw Exception('Preview failed: ${result.stderr}');
    }
    
    return outputPath;
  }
}
