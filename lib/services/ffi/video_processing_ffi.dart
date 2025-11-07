import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

/// FFI bindings to C++ video processing library
class VideoProcessingFFI {
  static ffi.DynamicLibrary? _dylib;
  
  /// Load the native library
  static void initialize() {
    if (_dylib != null) return;
    
    if (Platform.isWindows) {
      _dylib = ffi.DynamicLibrary.open('video_processor.dll');
    } else if (Platform.isLinux) {
      _dylib = ffi.DynamicLibrary.open('libvideo_processor.so');
    } else if (Platform.isMacOS) {
      _dylib = ffi.DynamicLibrary.open('libvideo_processor.dylib');
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  static ffi.DynamicLibrary get dylib {
    if (_dylib == null) {
      throw StateError('FFI not initialized. Call initialize() first.');
    }
    return _dylib!;
  }

  // Function signatures
  
  /// Initialize the video processor
  /// Returns: 0 on success, non-zero on error
  static int Function() initProcessor = dylib
      .lookup<ffi.NativeFunction<ffi.Int32 Function()>>('init_processor')
      .asFunction();

  /// Split video into clips
  /// Parameters:
  ///   - inputPath: Path to input video
  ///   - outputDir: Directory to save clips
  ///   - clipDuration: Duration of each clip in seconds
  ///   - callback: Progress callback (current, total)
  /// Returns: Number of clips created, or negative on error
  static int Function(
    ffi.Pointer<Utf8> inputPath,
    ffi.Pointer<Utf8> outputDir,
    int clipDuration,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int32, ffi.Int32)>>
        callback,
  ) splitVideo = dylib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                ffi.Pointer<Utf8>,
                ffi.Pointer<Utf8>,
                ffi.Int32,
                ffi.Pointer<
                    ffi.NativeFunction<
                        ffi.Void Function(ffi.Int32, ffi.Int32)>>,
              )>>('split_video')
      .asFunction();

  /// Concatenate multiple video files
  /// Parameters:
  ///   - inputPaths: Array of input video paths
  ///   - inputCount: Number of input videos
  ///   - outputPath: Path for output video
  ///   - callback: Progress callback (0-100)
  /// Returns: 0 on success, non-zero on error
  static int Function(
    ffi.Pointer<ffi.Pointer<Utf8>> inputPaths,
    int inputCount,
    ffi.Pointer<Utf8> outputPath,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>> callback,
  ) concatenateVideos = dylib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                ffi.Pointer<ffi.Pointer<Utf8>>,
                ffi.Int32,
                ffi.Pointer<Utf8>,
                ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>>,
              )>>('concatenate_videos')
      .asFunction();

  /// Add outro to video
  /// Parameters:
  ///   - inputPath: Path to input video
  ///   - outroPath: Path to outro video
  ///   - outputPath: Path for output video
  ///   - callback: Progress callback (0-100)
  /// Returns: 0 on success, non-zero on error
  static int Function(
    ffi.Pointer<Utf8> inputPath,
    ffi.Pointer<Utf8> outroPath,
    ffi.Pointer<Utf8> outputPath,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>> callback,
  ) addOutro = dylib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                ffi.Pointer<Utf8>,
                ffi.Pointer<Utf8>,
                ffi.Pointer<Utf8>,
                ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>>,
              )>>('add_outro')
      .asFunction();

  /// Add background music to video
  /// Parameters:
  ///   - videoPath: Path to video
  ///   - musicPath: Path to music file
  ///   - outputPath: Path for output video
  ///   - fadeIn: Fade in duration in seconds
  ///   - fadeOut: Fade out duration in seconds
  ///   - callback: Progress callback (0-100)
  /// Returns: 0 on success, non-zero on error
  static int Function(
    ffi.Pointer<Utf8> videoPath,
    ffi.Pointer<Utf8> musicPath,
    ffi.Pointer<Utf8> outputPath,
    int fadeIn,
    int fadeOut,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>> callback,
  ) addBackgroundMusic = dylib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                ffi.Pointer<Utf8>,
                ffi.Pointer<Utf8>,
                ffi.Pointer<Utf8>,
                ffi.Int32,
                ffi.Int32,
                ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>>,
              )>>('add_background_music')
      .asFunction();

  /// Convert video to portrait mode (9:16)
  /// Parameters:
  ///   - inputPath: Path to input video
  ///   - outputPath: Path for output video
  ///   - width: Target width
  ///   - height: Target height
  ///   - cropMode: 0=smart crop, 1=blur background, 2=letterbox
  ///   - callback: Progress callback (0-100)
  /// Returns: 0 on success, non-zero on error
  static int Function(
    ffi.Pointer<Utf8> inputPath,
    ffi.Pointer<Utf8> outputPath,
    int width,
    int height,
    int cropMode,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>> callback,
  ) convertToPortrait = dylib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                ffi.Pointer<Utf8>,
                ffi.Pointer<Utf8>,
                ffi.Int32,
                ffi.Int32,
                ffi.Int32,
                ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>>,
              )>>('convert_to_portrait')
      .asFunction();

  /// Get video information
  /// Parameters:
  ///   - videoPath: Path to video
  ///   - info: Pointer to VideoInfo struct
  /// Returns: 0 on success, non-zero on error
  static int Function(
    ffi.Pointer<Utf8> videoPath,
    ffi.Pointer<VideoInfo> info,
  ) getVideoInfo = dylib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                ffi.Pointer<Utf8>,
                ffi.Pointer<VideoInfo>,
              )>>('get_video_info')
      .asFunction();

  /// Clean up resources
  static void Function() cleanup = dylib
      .lookup<ffi.NativeFunction<ffi.Void Function()>>('cleanup')
      .asFunction();
}

/// Video information structure (must match C++ struct)
final class VideoInfo extends ffi.Struct {
  @ffi.Int32()
  external int width;

  @ffi.Int32()
  external int height;

  @ffi.Int32()
  external int durationMs;

  @ffi.Int32()
  external int fps;

  @ffi.Int32()
  external int bitrate;

  @ffi.Int32()
  external int hasAudio;
}
