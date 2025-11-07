#include "../include/video_processor.h"
#include <iostream>
#include <cstring>
#include <cmath>
#include <sstream>
#include <vector>
#include <string>
#include <fstream>
#include <windows.h>

// FFmpeg command execution helper
static int execute_ffmpeg_command(const std::string& command) {
    std::cout << "Executing: " << command << std::endl;
    
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;  // Hide console window
    ZeroMemory(&pi, sizeof(pi));

    // Create process
    char* cmd = _strdup(command.c_str());
    BOOL success = CreateProcessA(
        NULL, cmd, NULL, NULL, FALSE,
        CREATE_NO_WINDOW, NULL, NULL, &si, &pi
    );
    
    if (!success) {
        free(cmd);
        return -1;
    }

    // Wait for process to complete
    WaitForSingleObject(pi.hProcess, INFINITE);
    
    DWORD exitCode;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    free(cmd);
    
    return exitCode;
}

// Get command output
static std::string get_command_output(const std::string& command) {
    FILE* pipe = _popen(command.c_str(), "r");
    if (!pipe) return "";

    char buffer[256];
    std::string result = "";
    while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
        result += buffer;
    }
    _pclose(pipe);
    return result;
}

// Initialize FFmpeg
extern "C" __declspec(dllexport) int32_t init_processor() {
    std::string result = get_command_output("ffmpeg -version 2>&1");
    if (result.find("ffmpeg version") == std::string::npos) {
        std::cerr << "FFmpeg not found! Please install FFmpeg and add to PATH." << std::endl;
        return -1;
    }
    std::cout << "FFmpeg initialized successfully" << std::endl;
    return 0;
}

// Split video into clips
extern "C" __declspec(dllexport) int32_t split_video(
    const char* inputPath,
    const char* outputDir,
    int32_t clipDuration,
    SplitProgressCallback callback
) {
    if (!inputPath || !outputDir || clipDuration <= 0) {
        return -1;
    }

    // Create output directory
    CreateDirectoryA(outputDir, NULL);

    // Get video duration
    std::stringstream probe_cmd;
    probe_cmd << "ffprobe -v error -show_entries format=duration "
              << "-of default=noprint_wrappers=1:nokey=1 \""
              << inputPath << "\" 2>&1";

    std::string duration_str = get_command_output(probe_cmd.str());
    double total_duration = std::stod(duration_str);
    int32_t num_clips = static_cast<int32_t>(std::ceil(total_duration / clipDuration));

    // Split video into segments
    for (int32_t i = 0; i < num_clips; i++) {
        std::stringstream output_ss;
        output_ss << outputDir << "\\clip_" << (i + 1) << ".mp4";
        std::string output_path = output_ss.str();

        double start_time = i * clipDuration;
        
        std::stringstream cmd;
        cmd << "ffmpeg -y -i \"" << inputPath << "\" "
            << "-ss " << start_time << " "
            << "-t " << clipDuration << " "
            << "-c copy -avoid_negative_ts 1 \""
            << output_path << "\"";

        int result = execute_ffmpeg_command(cmd.str());
        if (result != 0) {
            std::cerr << "Failed to create clip " << (i + 1) << std::endl;
            return -1;
        }

        if (callback) {
            callback(i + 1, num_clips);
        }
    }

    return num_clips;
}

// Concatenate multiple videos
extern "C" __declspec(dllexport) int32_t concatenate_videos(
    const char** inputPaths,
    int32_t inputCount,
    const char* outputPath,
    ProgressCallback callback
) {
    if (!inputPaths || inputCount <= 0 || !outputPath) {
        return -1;
    }

    // Create concat file list
    std::string concat_file = "concat_temp.txt";
    std::ofstream file(concat_file);
    
    for (int32_t i = 0; i < inputCount; i++) {
        std::string path = inputPaths[i];
        // Escape backslashes for FFmpeg
        size_t pos = 0;
        while ((pos = path.find("\\", pos)) != std::string::npos) {
            path.replace(pos, 1, "/");
            pos += 1;
        }
        file << "file '" << path << "'\n";
    }
    file.close();

    if (callback) callback(50);

    // Concatenate using concat demuxer
    std::stringstream cmd;
    cmd << "ffmpeg -y -f concat -safe 0 -i \"" << concat_file << "\" "
        << "-c copy \"" << outputPath << "\"";

    int result = execute_ffmpeg_command(cmd.str());
    
    // Clean up
    DeleteFileA(concat_file.c_str());
    
    if (callback) callback(100);
    
    return result == 0 ? 0 : -1;
}

// Add outro to video
extern "C" __declspec(dllexport) int32_t add_outro(
    const char* inputPath,
    const char* outroPath,
    const char* outputPath,
    ProgressCallback callback
) {
    if (!inputPath || !outroPath || !outputPath) {
        return -1;
    }

    const char* paths[] = {inputPath, outroPath};
    return concatenate_videos(paths, 2, outputPath, callback);
}

// Add background music with fade
extern "C" __declspec(dllexport) int32_t add_background_music(
    const char* videoPath,
    const char* musicPath,
    const char* outputPath,
    int32_t fadeIn,
    int32_t fadeOut,
    ProgressCallback callback
) {
    if (!videoPath || !musicPath || !outputPath) {
        return -1;
    }

    // Get video duration
    std::stringstream probe_cmd;
    probe_cmd << "ffprobe -v error -show_entries format=duration "
              << "-of default=noprint_wrappers=1:nokey=1 \""
              << videoPath << "\" 2>&1";

    std::string duration_str = get_command_output(probe_cmd.str());
    double video_duration = std::stod(duration_str);
    double fade_out_start = video_duration - fadeOut;

    if (callback) callback(30);

    // Build audio filter with fades and volume adjustment
    std::stringstream audio_filter;
    audio_filter << "afade=t=in:st=0:d=" << fadeIn;
    
    if (fadeOut > 0 && fade_out_start > 0) {
        audio_filter << ",afade=t=out:st=" << fade_out_start 
                    << ":d=" << fadeOut;
    }
    
    audio_filter << ",volume=0.3"; // Lower music volume (30%)

    if (callback) callback(50);

    // Combine video with music
    std::stringstream cmd;
    cmd << "ffmpeg -y -i \"" << videoPath << "\" -i \"" << musicPath << "\" "
        << "-filter_complex \"[1:a]" << audio_filter.str() 
        << ",aloop=loop=-1:size=2e9[music];[0:a][music]amix=inputs=2:duration=first:dropout_transition=0\" "
        << "-c:v copy -c:a aac -b:a 192k -shortest \""
        << outputPath << "\"";

    int result = execute_ffmpeg_command(cmd.str());
    
    if (callback) callback(100);
    
    return result == 0 ? 0 : -1;
}

// Convert to portrait (9:16)
extern "C" __declspec(dllexport) int32_t convert_to_portrait(
    const char* inputPath,
    const char* outputPath,
    int32_t width,
    int32_t height,
    int32_t cropMode,
    ProgressCallback callback
) {
    if (!inputPath || !outputPath) {
        return -1;
    }

    if (callback) callback(20);

    std::stringstream cmd;
    cmd << "ffmpeg -y -i \"" << inputPath << "\" ";

    if (cropMode == 0) {
        // Smart crop - crop center to 9:16
        cmd << "-vf \"crop=ih*9/16:ih,scale=" << width << ":" << height << "\" ";
    } 
    else if (cropMode == 1) {
        // Blurred background
        cmd << "-filter_complex \""
            << "[0:v]scale=" << width << ":" << height 
            << ":force_original_aspect_ratio=decrease,pad=" << width << ":" << height 
            << ":(ow-iw)/2:(oh-ih)/2:black[fg];"
            << "[0:v]scale=" << width << ":" << height << ",boxblur=20:20[bg];"
            << "[bg][fg]overlay=(W-w)/2:(H-h)/2\" ";
    }
    else {
        // Letterbox - black bars
        cmd << "-vf \"scale=" << width << ":" << height 
            << ":force_original_aspect_ratio=decrease,"
            << "pad=" << width << ":" << height << ":(ow-iw)/2:(oh-ih)/2:black\" ";
    }

    if (callback) callback(50);

    cmd << "-c:a copy -preset medium \"" << outputPath << "\"";

    int result = execute_ffmpeg_command(cmd.str());
    
    if (callback) callback(100);
    
    return result == 0 ? 0 : -1;
}

// Get video information
extern "C" __declspec(dllexport) int32_t get_video_info(
    const char* videoPath,
    VideoInfo* info
) {
    if (!videoPath || !info) {
        return -1;
    }

    // Get video information using ffprobe
    std::stringstream probe_cmd;
    probe_cmd << "ffprobe -v error -select_streams v:0 "
              << "-show_entries stream=width,height,r_frame_rate,bit_rate "
              << "-show_entries format=duration "
              << "-of csv=p=0 \""
              << videoPath << "\" 2>&1";

    std::string result = get_command_output(probe_cmd.str());
    
    // Parse result
    std::stringstream ss(result);
    std::string item;
    std::vector<std::string> values;
    
    while (std::getline(ss, item, ',')) {
        values.push_back(item);
    }

    if (values.size() >= 3) {
        info->width = std::stoi(values[0]);
        info->height = std::stoi(values[1]);
        
        // Parse fps (format: num/den)
        std::stringstream fps_ss(values[2]);
        std::string num_str, den_str;
        std::getline(fps_ss, num_str, '/');
        std::getline(fps_ss, den_str);
        
        if (!den_str.empty()) {
            double num = std::stod(num_str);
            double den = std::stod(den_str);
            info->fps = num / den;
        } else {
            info->fps = std::stod(num_str);
        }
        
        if (values.size() >= 4) {
            info->bitrate = std::stoll(values[3]);
        }
        
        if (values.size() >= 5) {
            info->durationMs = static_cast<int64_t>(std::stod(values[4]) * 1000);
        }
        
        // Check for audio
        std::string audio_check = get_command_output(
            std::string("ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 \"") 
            + videoPath + "\" 2>&1"
        );
        info->hasAudio = audio_check.find("audio") != std::string::npos ? 1 : 0;
        
        return 0;
    }

    return -1;
}

extern "C" __declspec(dllexport) void cleanup() {
    // Cleanup if needed
}
