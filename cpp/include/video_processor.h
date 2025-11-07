#ifndef VIDEO_PROCESSOR_H
#define VIDEO_PROCESSOR_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

// Video information structure
typedef struct {
    int32_t width;
    int32_t height;
    int32_t durationMs;
    int32_t fps;
    int32_t bitrate;
    int32_t hasAudio;
} VideoInfo;

// Callback function types
typedef void (*ProgressCallback)(int32_t progress);
typedef void (*SplitProgressCallback)(int32_t current, int32_t total);

// Initialize the video processor
// Returns: 0 on success, non-zero on error
int32_t init_processor();

// Split video into clips
// Parameters:
//   - inputPath: Path to input video
//   - outputDir: Directory to save clips
//   - clipDuration: Duration of each clip in seconds
//   - callback: Progress callback (current, total)
// Returns: Number of clips created, or negative on error
int32_t split_video(
    const char* inputPath,
    const char* outputDir,
    int32_t clipDuration,
    SplitProgressCallback callback
);

// Concatenate multiple video files
// Parameters:
//   - inputPaths: Array of input video paths
//   - inputCount: Number of input videos
//   - outputPath: Path for output video
//   - callback: Progress callback (0-100)
// Returns: 0 on success, non-zero on error
int32_t concatenate_videos(
    const char** inputPaths,
    int32_t inputCount,
    const char* outputPath,
    ProgressCallback callback
);

// Add outro to video
// Parameters:
//   - inputPath: Path to input video
//   - outroPath: Path to outro video
//   - outputPath: Path for output video
//   - callback: Progress callback (0-100)
// Returns: 0 on success, non-zero on error
int32_t add_outro(
    const char* inputPath,
    const char* outroPath,
    const char* outputPath,
    ProgressCallback callback
);

// Add background music to video
// Parameters:
//   - videoPath: Path to video
//   - musicPath: Path to music file
//   - outputPath: Path for output video
//   - fadeIn: Fade in duration in seconds
//   - fadeOut: Fade out duration in seconds
//   - callback: Progress callback (0-100)
// Returns: 0 on success, non-zero on error
int32_t add_background_music(
    const char* videoPath,
    const char* musicPath,
    const char* outputPath,
    int32_t fadeIn,
    int32_t fadeOut,
    ProgressCallback callback
);

// Convert video to portrait mode (9:16)
// Parameters:
//   - inputPath: Path to input video
//   - outputPath: Path for output video
//   - width: Target width
//   - height: Target height
//   - cropMode: 0=smart crop, 1=blur background, 2=letterbox
//   - callback: Progress callback (0-100)
// Returns: 0 on success, non-zero on error
int32_t convert_to_portrait(
    const char* inputPath,
    const char* outputPath,
    int32_t width,
    int32_t height,
    int32_t cropMode,
    ProgressCallback callback
);

// Get video information
// Parameters:
//   - videoPath: Path to video
//   - info: Pointer to VideoInfo struct
// Returns: 0 on success, non-zero on error
int32_t get_video_info(
    const char* videoPath,
    VideoInfo* info
);

// Clean up resources
void cleanup();

#ifdef __cplusplus
}
#endif

#endif // VIDEO_PROCESSOR_H
