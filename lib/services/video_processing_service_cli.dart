import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import '../models/app_settings.dart';

/// Video processing service using FFmpeg CLI directly
class VideoProcessingService {
  final _processingController = StreamController<ProcessingUpdate>.broadcast();
  final List<Process> _activeProcesses = []; // Track active processes
  
  Stream<ProcessingUpdate> get processingUpdates => _processingController.stream;
  bool _isInitialized = false;
  bool _isCancelled = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Check if FFmpeg is available
      final result = await Process.run('ffmpeg', ['-version']);
      if (result.exitCode != 0) {
        throw Exception('FFmpeg not found or not working');
      }
      _isInitialized = true;
      print('✓ FFmpeg is available and ready');
    } catch (e) {
      throw Exception('FFmpeg not found. Please install FFmpeg first: $e');
    }
  }
  
  /// Cancel all running processes
  void cancel() {
    _isCancelled = true;
    for (var process in _activeProcesses) {
      try {
        process.kill();
      } catch (e) {
        print('Error killing process: $e');
      }
    }
    _activeProcesses.clear();
  }
  
  /// Run FFmpeg with resource management and performance optimizations
  Future<ProcessResult> _runFFmpeg(List<String> arguments) async {
    if (_isCancelled) {
      throw Exception('Processing cancelled');
    }
    
    // إضافة Multi-threading optimization
    final optimizedArgs = [
      '-threads', '0', // استخدام كل النوى المتاحة
      ...arguments,
    ];
    
    final process = await Process.start('ffmpeg', optimizedArgs);
    _activeProcesses.add(process);
    
    final stdout = <int>[];
    final stderr = <int>[];
    
    process.stdout.listen(stdout.addAll);
    process.stderr.listen(stderr.addAll);
    
    final exitCode = await process.exitCode;
    
    _activeProcesses.remove(process);
    
    return ProcessResult(
      process.pid,
      exitCode,
      String.fromCharCodes(stdout),
      String.fromCharCodes(stderr),
    );
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('VideoProcessingService not initialized. Call init() first.');
    }
  }

  void _updateProgress(ProcessingStatus status, double progress, String message) {
    _processingController.add(ProcessingUpdate(
      status: status,
      progress: progress,
      message: message,
    ));
  }

  /// Split a video into multiple clips
  Future<List<String>> splitVideo({
    required String inputPath,
    required String outputDir,
    required int clipDurationSeconds,
  }) async {
    _ensureInitialized();
    
    _updateProgress(ProcessingStatus.splitting, 0, 'Analyzing video...');
    
    // Ensure output directory exists
    Directory(outputDir).createSync(recursive: true);
    
    // Get video duration
    final probeResult = await Process.run('ffprobe', [
      '-v', 'error',
      '-show_entries', 'format=duration',
      '-of', 'default=noprint_wrappers=1:nokey=1',
      inputPath
    ]);
    
    if (probeResult.exitCode != 0) {
      throw Exception('Failed to analyze video: ${probeResult.stderr}');
    }
    
    final totalDuration = double.parse(probeResult.stdout.toString().trim());
    final outputFiles = <String>[];
    final random = Random();
    
    double currentTime = 0;
    int clipIndex = 1;
    
    while (currentTime < totalDuration) {
      // Random clip duration between 10 and 15 seconds
      final randomDuration = 10 + random.nextInt(6); // 10-15 seconds
      final remainingTime = totalDuration - currentTime;
      
      // Skip if remaining time is less than 10 seconds
      if (remainingTime < 10) {
        print('Skipping last segment (${remainingTime.toStringAsFixed(1)}s < 10s)');
        break;
      }
      
      // Use random duration or remaining time, whichever is smaller
      final actualDuration = remainingTime < randomDuration ? remainingTime : randomDuration.toDouble();
      
      final outputFile = path.join(outputDir, 'clip_$clipIndex.mp4');
      
      _updateProgress(
        ProcessingStatus.splitting,
        (currentTime / totalDuration) * 100,
        'Splitting clip $clipIndex (${actualDuration.toStringAsFixed(1)}s)...',
      );
      
      final result = await _runFFmpeg([
        '-i', inputPath,
        '-ss', currentTime.toString(),
        '-t', actualDuration.toString(),
        '-c', 'copy',
        '-y',
        outputFile
      ]);
      
      if (result.exitCode == 0) {
        outputFiles.add(outputFile);
        clipIndex++;
      }
      
      currentTime += actualDuration;
    }
    
    return outputFiles;
  }

  /// Add outro to a video using concat demuxer (more reliable)
  Future<String> addOutro({
    required String videoPath,
    required String outroPath,
    required String outputPath,
  }) async {
    _ensureInitialized();
    
    _updateProgress(ProcessingStatus.encoding, 0, 'Preparing outro...');
    
    // Get video properties
    final videoProbe = await Process.run('ffprobe', [
      '-v', 'error',
      '-select_streams', 'v:0',
      '-show_entries', 'stream=width,height,r_frame_rate',
      '-of', 'csv=p=0',
      videoPath
    ]);
    
    if (videoProbe.exitCode != 0) {
      throw Exception('Failed to analyze video');
    }
    
    final videoInfo = videoProbe.stdout.toString().trim().split(',');
    final width = videoInfo[0];
    final height = videoInfo[1];
    final fps = videoInfo[2].split('/')[0]; // Get FPS numerator
    
    print('Video specs: ${width}x${height} @ ${fps}fps');
    
    // Step 1: Normalize outro to match video specs
    final tempDir = Directory(path.dirname(outputPath));
    final normalizedOutro = path.join(tempDir.path, 'normalized_outro.mp4');
    
    _updateProgress(ProcessingStatus.encoding, 20, 'Normalizing outro...');
    
    final normalizeResult = await _runFFmpeg([
      '-i', outroPath,
      '-vf', 'scale=$width:$height,fps=$fps',
      '-c:v', 'libx264',
      '-preset', 'veryfast', // تسريع (كان fast)
      '-crf', '26', // جودة جيدة (كان 23)
      '-pix_fmt', 'yuv420p',
      '-an', // No audio
      '-movflags', '+faststart',
      '-y',
      normalizedOutro
    ]);
    
    if (normalizeResult.exitCode != 0) {
      print('Warning: Failed to normalize outro, using re-encode method');
      // Try without normalization but with re-encode
      final concatFile = path.join(tempDir.path, 'concat_list.txt');
      final concatContent = "file '${videoPath.replaceAll('\\', '/')}'\nfile '${outroPath.replaceAll('\\', '/')}'";
      File(concatFile).writeAsStringSync(concatContent);
      
      final result = await _runFFmpeg([
        '-f', 'concat',
        '-safe', '0',
        '-i', concatFile,
        '-c:v', 'libx264',
        '-preset', 'veryfast', // تسريع (كان fast)
        '-crf', '26', // جودة جيدة (كان 23)
        '-pix_fmt', 'yuv420p',
        '-an',
        '-movflags', '+faststart',
        '-y',
        outputPath
      ]);
      
      File(concatFile).deleteSync();
      
      if (result.exitCode != 0) {
        throw Exception('Failed to concatenate videos');
      }
      
      return outputPath;
    }
    
    // Step 2: Create concat file
    _updateProgress(ProcessingStatus.encoding, 50, 'Merging video and outro...');
    
    final concatFile = path.join(tempDir.path, 'concat_list.txt');
    final concatContent = "file '${videoPath.replaceAll('\\', '/')}'\nfile '${normalizedOutro.replaceAll('\\', '/')}'";
    File(concatFile).writeAsStringSync(concatContent);
    
    print('Concat file created: $concatFile');
    print('Content:\n$concatContent');
    
    // Step 3: Concatenate using concat demuxer - محسّن للسرعة
    final result = await _runFFmpeg([
      '-f', 'concat',
      '-safe', '0',
      '-i', concatFile,
      '-c:v', 'libx264',
      '-preset', 'veryfast', // تسريع (كان fast)
      '-crf', '26', // جودة جيدة (كان 23)
      '-pix_fmt', 'yuv420p',
      '-an', // No audio (will add music later)
      '-movflags', '+faststart',
      '-y',
      outputPath
    ]);
    
    // Cleanup
    try {
      File(concatFile).deleteSync();
      File(normalizedOutro).deleteSync();
    } catch (e) {
      print('Warning: Failed to delete temp files: $e');
    }
    
    if (result.exitCode != 0) {
      print('FFmpeg error: ${result.stderr}');
      throw Exception('Failed to add outro');
    }
    
    print('✓ Outro added successfully');
    return outputPath;
  }

  /// Add background music to a video
  Future<String> addBackgroundMusic({
    required String videoPath,
    required String musicPath,
    required String outputPath,
    double musicVolume = 0.3,
    bool fadeIn = true,
    bool fadeOut = true,
    AppSettings? settings,
  }) async {
    _ensureInitialized();
    
    _updateProgress(ProcessingStatus.encoding, 0, 'Adding background music...');
    
    // Get video duration first
    final probeResult = await Process.run('ffprobe', [
      '-v', 'error',
      '-show_entries', 'format=duration',
      '-of', 'default=noprint_wrappers=1:nokey=1',
      videoPath
    ]);
    
    if (probeResult.exitCode != 0) {
      throw Exception('Failed to get video duration: ${probeResult.stderr}');
    }
    
    final videoDuration = double.parse(probeResult.stdout.toString().trim());
    
    // إعدادات الجودة بناءً على bitrate - محسّنة للسرعة
    final bitrate = settings?.exportSettings.bitrate ?? 5000;
    String crf;
    String preset;
    
    // استخدام presets أسرع مع جودة جيدة
    if (bitrate >= 8000) {
      crf = '20'; // Very high quality (كان 18)
      preset = 'medium'; // أسرع (كان slow)
    } else if (bitrate >= 5000) {
      crf = '26'; // High quality (كان 23)
      preset = 'veryfast'; // أسرع (كان medium)
    } else if (bitrate >= 3000) {
      crf = '28'; // Medium quality (كان 26)
      preset = 'veryfast'; // نفسه (كان fast)
    } else {
      crf = '30'; // Low quality (كان 28)
      preset = 'ultrafast'; // أسرع (كان veryfast)
    }
    
    // Add music as audio track with quality settings - محسّن للأداء
    // الموسيقى تتكرر وتستمر حتى نهاية الفيديو
    final result = await _runFFmpeg([
      '-i', videoPath,
      '-stream_loop', '-1', // تكرار الموسيقى بشكل لا نهائي
      '-i', musicPath,
      '-filter_complex', 
      '[1:a]volume=$musicVolume[music];[music]atrim=0:${videoDuration.toStringAsFixed(2)}[musicfinal]',
      '-map', '0:v',
      '-map', '[musicfinal]',
      '-c:v', 'libx264',
      '-preset', preset,
      '-crf', crf,
      '-b:v', '${bitrate}k',
      '-pix_fmt', 'yuv420p',
      '-max_muxing_queue_size', '1024', // تحديد استهلاك الذاكرة
      '-c:a', 'aac',
      '-b:a', '${settings?.exportSettings.audioBitrate ?? 192}k',
      '-movflags', '+faststart',
      '-t', videoDuration.toStringAsFixed(2), // مدة الفيديو النهائي
      '-y',
      outputPath
    ]);
    
    if (result.exitCode != 0) {
      print('FFmpeg error: ${result.stderr}');
      throw Exception('Failed to add music');
    }
    
    return outputPath;
  }

  /// Convert video to portrait mode (9:16)
  Future<String> convertToPortrait({
    required String inputPath,
    required String outputPath,
    required CropMode cropMode,
    required ExportResolution resolution,
  }) async {
    _ensureInitialized();
    
    _updateProgress(ProcessingStatus.encoding, 0, 'Converting to portrait...');
    
    final targetWidth = resolution.portraitWidth;
    final targetHeight = resolution.portraitHeight;
    
    // Use simple scale and crop - much more stable
    final result = await _runFFmpeg([
      '-i', inputPath,
      '-vf', 'scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$targetHeight',
      '-c:a', 'copy',
      '-y',
      outputPath
    ]);
    
    if (result.exitCode != 0) {
      print('FFmpeg error: ${result.stderr}');
      throw Exception('Failed to convert to portrait. Check if video file is valid.');
    }
    
    return outputPath;
  }

  /// Add random effects to video (speed up, zoom, transitions)
  Future<String> addRandomEffects({
    required String inputPath,
    required String outputPath,
  }) async {
    _ensureInitialized();
    
    final random = Random();
    final effectType = random.nextInt(4); // 0-3: different effects
    
    String filterComplex;
    String effectName;
    
    switch (effectType) {
      case 0:
        // Speed up (1.1x - 1.3x)
        final speed = 1.1 + (random.nextDouble() * 0.2);
        filterComplex = 'setpts=${(1/speed).toStringAsFixed(2)}*PTS';
        effectName = 'Speed ${speed.toStringAsFixed(1)}x';
        break;
      case 1:
        // Zoom in effect (Ken Burns)
        filterComplex = 'zoompan=z=\'min(zoom+0.0015,1.5)\':d=125:x=\'iw/2-(iw/zoom/2)\':y=\'ih/2-(ih/zoom/2)\'';
        effectName = 'Zoom In';
        break;
      case 2:
        // Fade in/out
        filterComplex = 'fade=t=in:st=0:d=1,fade=t=out:st=14:d=1';
        effectName = 'Fade In/Out';
        break;
      case 3:
        // Brightness & Saturation boost
        filterComplex = 'eq=brightness=0.05:saturation=1.2';
        effectName = 'Color Boost';
        break;
      default:
        filterComplex = 'null';
        effectName = 'None';
    }
    
    print('Applying effect: $effectName');
    
    final result = await _runFFmpeg([
      '-i', inputPath,
      '-vf', filterComplex,
      '-c:a', 'copy',
      '-y',
      outputPath
    ]);
    
    if (result.exitCode != 0) {
      print('Warning: Failed to add effect, using original video');
      await File(inputPath).copy(outputPath);
    }
    
    return outputPath;
  }

  /// Complete workflow: process video with all effects
  Future<List<String>> processCompleteWorkflow({
    required String inputPath,
    required String outputDir,
    String? outroPath,
    String? musicPath,
    required AppSettings settings,
    required EditMode mode,
    String? outputFileName,
  }) async {
    _ensureInitialized();
    
    final outputVideos = <String>[];
    
    // Create output directory
    Directory(outputDir).createSync(recursive: true);
    final tempDir = Directory(path.join(outputDir, 'temp'));
    tempDir.createSync(recursive: true);
    
    // استخدام اسم فريد للملف النهائي
    final uniqueFileName = outputFileName ?? 'video_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // Step 1: Split or prepare videos
      List<String> videoClips;
      
      if (mode == EditMode.splitVideo) {
        _updateProgress(ProcessingStatus.splitting, 10, 'Splitting video into clips...');
        try {
          videoClips = await splitVideo(
            inputPath: inputPath,
            outputDir: path.join(tempDir.path, 'clips'),
            clipDurationSeconds: 15,
          );
          _updateProgress(ProcessingStatus.splitting, 20, 'Split complete: ${videoClips.length} clips');
        } catch (e) {
          print('Split error: $e');
          throw Exception('Failed to split video: $e');
        }
      } else {
        videoClips = [inputPath];
      }
      
      // Process each clip with ALL steps
      for (int i = 0; i < videoClips.length; i++) {
        final clipPath = videoClips[i];
        String currentPath = clipPath;
        
        final clipNum = i + 1;
        final totalClips = videoClips.length;
        final baseProgress = 20 + (i / totalClips * 70);
        
        try {
          // STEP 1: Remove original audio (replace with silence)
          _updateProgress(
            ProcessingStatus.encoding,
            baseProgress + 5,
            'Clip $clipNum/$totalClips: Removing original audio...',
          );
          
          final noAudioPath = path.join(tempDir.path, 'noaudio_$clipNum.mp4');
          final muteResult = await _runFFmpeg([
            '-i', currentPath,
            '-an', // Remove audio
            '-c:v', 'copy',
            '-y',
            noAudioPath
          ]);
          
          if (muteResult.exitCode == 0) {
            currentPath = noAudioPath;
          } else {
            print('Warning: Failed to remove audio, continuing with original audio');
          }
          
          // STEP 2: Convert to portrait (9:16)
          _updateProgress(
            ProcessingStatus.encoding,
            baseProgress + 15,
            'Clip $clipNum/$totalClips: Converting to Portrait 9:16...',
          );
          
          final portraitPath = path.join(tempDir.path, 'portrait_$clipNum.mp4');
          final portraitResult = await _runFFmpeg([
            '-i', currentPath,
            '-vf', 'scale=${settings.exportSettings.resolution.portraitWidth}:${settings.exportSettings.resolution.portraitHeight}:force_original_aspect_ratio=increase,crop=${settings.exportSettings.resolution.portraitWidth}:${settings.exportSettings.resolution.portraitHeight}',
            '-c:v', 'libx264',
            '-preset', 'veryfast', // تسريع (كان medium)
            '-crf', '26', // جودة جيدة (كان 23)
            '-pix_fmt', 'yuv420p',
            '-c:a', 'copy', // نسخ الصوت بدون إعادة تشفير
            '-movflags', '+faststart',
            '-y',
            portraitPath
          ]);
          
          if (portraitResult.exitCode != 0) {
            print('Portrait conversion error: ${portraitResult.stderr}');
            throw Exception('Failed to convert video to portrait');
          }
          currentPath = portraitPath;
          
          // STEP 2.5: Add random visual effects
          _updateProgress(
            ProcessingStatus.encoding,
            baseProgress + 20,
            'Clip $clipNum/$totalClips: Adding random effects...',
          );
          
          final effectsPath = path.join(tempDir.path, 'effects_$clipNum.mp4');
          currentPath = await addRandomEffects(
            inputPath: currentPath,
            outputPath: effectsPath,
          );
          
          // STEP 3: Add outro video FIRST (before music)
          if (outroPath != null && outroPath.isNotEmpty && File(outroPath).existsSync()) {
            _updateProgress(
              ProcessingStatus.encoding,
              baseProgress + 30,
              'Clip $clipNum/$totalClips: Adding outro...',
            );
            
            final withOutroPath = path.join(tempDir.path, 'with_outro_$clipNum.mp4');
            
            try {
              currentPath = await addOutro(
                videoPath: currentPath,
                outroPath: outroPath,
                outputPath: withOutroPath,
              );
              print('✓ Outro added successfully');
            } catch (e) {
              print('Warning: Failed to add outro: $e');
            }
          }
          
          // STEP 4: Now add background music to (video + outro)
          if (musicPath != null && musicPath.isNotEmpty && File(musicPath).existsSync()) {
            _updateProgress(
              ProcessingStatus.encoding,
              baseProgress + 50,
              'Clip $clipNum/$totalClips: Adding music to full video...',
            );
            
            final finalPath = path.join(outputDir, '${uniqueFileName}_$clipNum.mp4');
            
            try {
              await addBackgroundMusic(
                videoPath: currentPath, // This is now (video + outro)
                musicPath: musicPath,
                outputPath: finalPath,
                musicVolume: 0.3,
                settings: settings,
              );
              currentPath = finalPath;
              outputVideos.add(currentPath);
              print('✓ Music added to full video (clip + outro)');
            } catch (e) {
              print('Warning: Failed to add music: $e');
              // Save without music
              final finalPath = path.join(outputDir, '${uniqueFileName}_$clipNum.mp4');
              await File(currentPath).copy(finalPath);
              outputVideos.add(finalPath);
            }
          } else {
            // No music - just copy to final output
            final finalPath = path.join(outputDir, '${uniqueFileName}_$clipNum.mp4');
            await File(currentPath).copy(finalPath);
            outputVideos.add(finalPath);
          }
          
          _updateProgress(
            ProcessingStatus.encoding,
            baseProgress + 70,
            'Clip $clipNum/$totalClips: Complete ✓',
          );
          
          // Clean up temp files for this clip to free memory
          try {
            final tempFiles = [
              path.join(tempDir.path, 'noaudio_$clipNum.mp4'),
              path.join(tempDir.path, 'portrait_$clipNum.mp4'),
              path.join(tempDir.path, 'effects_$clipNum.mp4'),
              path.join(tempDir.path, 'with_outro_$clipNum.mp4'),
            ];
            for (var filePath in tempFiles) {
              final file = File(filePath);
              if (file.existsSync()) {
                file.deleteSync();
              }
            }
            print('✓ Cleaned temp files for clip $clipNum');
          } catch (e) {
            print('Warning: Could not clean temp files: $e');
          }
          
        } catch (e) {
          print('Error processing clip $clipNum: $e');
          // Continue with other clips
        }
      }
      
      // Final cleanup of temp directory
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
          print('✓ Cleaned temp directory');
        }
      } catch (e) {
        print('Warning: Failed to delete temp directory: $e');
      }
      
      if (outputVideos.isEmpty) {
        throw Exception('No videos were processed successfully');
      }
      
      _updateProgress(ProcessingStatus.completed, 100, 'Complete! ${outputVideos.length} videos ready.');
      
    } catch (e) {
      _updateProgress(ProcessingStatus.error, 0, 'Error: $e');
      rethrow;
    }
    
    return outputVideos;
  }

  void dispose() {
    _processingController.close();
  }
}

/// Processing status enum
enum ProcessingStatus {
  idle,
  splitting,
  encoding,
  completed,
  error,
}

/// Processing update event
class ProcessingUpdate {
  final ProcessingStatus status;
  final double progress;
  final String message;

  ProcessingUpdate({
    required this.status,
    required this.progress,
    required this.message,
  });
}
