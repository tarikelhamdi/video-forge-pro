# Video Editor Pro 🎬# Video Editor Pro 🎥✨# 🎬 Video Editor Pro



A powerful desktop video editor built with Flutter for Windows, designed for batch video processing with timeline-based editing.



![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)A professional video editor built with Flutter for Windows. Features timeline editing, video splitting, operations (effects, speed, portrait mode), and high-quality exports up to 4K.An advanced desktop video editing application built with Flutter and C++ for high-performance video processing. Designed specifically for creating portrait-format content for TikTok, Instagram Reels, and YouTube Shorts.

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

![FFmpeg](https://img.shields.io/badge/FFmpeg-007808?style=for-the-badge&logo=ffmpeg&logoColor=white)



## ✨ Features[🇸🇦 النسخة العربية](#-النسخة-العربية)## ✨ Features



### 🎯 Core Features

- **Timeline-based Editing**: Manage multiple video projects with individual timelines

- **Drag & Drop Support**: Intuitive file handling for videos and music![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)### Core Functionality

- **Batch Processing**: Create multiple timelines automatically from multiple files

- **Video Concatenation**: Merge up to 2 videos + outro in each timeline![FFmpeg](https://img.shields.io/badge/FFmpeg-007808?style=for-the-badge&logo=ffmpeg&logoColor=white)- **Split Mode**: Automatically split long videos into 10-15 second clips

- **Background Music**: Add music tracks that loop throughout the entire video

- **Video Operations**: Portrait conversion (9:16), effects, crop, speed adjustment, and more![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)- **Multi-Video Mode**: Process multiple videos from a folder

- **Smart Export**: Export individual timelines or all at once with unique filenames

- **Automated Editing**: Add outros and background music with rotation tracking

### 🚀 Performance Optimizations

- **2-2.5x Faster Processing**: Optimized FFmpeg settings with multi-threading## ✨ Features- **Portrait Optimization**: Auto-convert videos to 9:16 format

- **30% Less RAM Usage**: Memory-efficient processing with queue size limits

- **20% Smaller Files**: Better compression without quality loss- **Smart Cropping**: Multiple crop modes (smart crop, blur background, letterbox)

- **Auto Cleanup**: Automatic deletion of temporary files after each operation

- **Preset: veryfast**: Balanced speed and quality (CRF 26, H.264 codec)- 🎬 **Timeline Editor**



### 🆕 New Features (Latest Update)  - Drag & drop interface### Modern UI/UX



#### Multi-File Auto Timeline Creation  - Multiple video tracks- **Material 3 Design**: Sleek, modern interface with dark/light themes

Drop multiple files at once and choose:

- **Create Timelines**: Automatically generate one timeline per file  - Audio track with auto-looping- **Three-Pane Layout**: Navigation sidebar, workspace, and preview panel

- **Add First Only**: Add only the first file to the current timeline

- **Cyclic Repetition**: Smart file distribution across timelines  - Preview & Export- **Drag & Drop**: Easy file and folder imports



**Example:**- **Real-time Preview**: Live video preview with playback controls

```

Drop 10 videos in Video 1, 3 videos in Video 2, 5 music tracks- 🔄 **Video Operations**- **Progress Tracking**: Animated processing overlays with FFmpeg logs

→ Creates 10 timelines with cyclic repetition of Video 2 and Music

```  - Portrait Mode (9:16)



#### Enhanced File Support  - Speed Control (0.25x - 4x)### Performance

- Case-insensitive file extensions (`.mp4`, `.MP4`, `.Mp4`)

- Video formats: MP4, MOV, AVI, MKV  - Brightness & Contrast- **C++ Engine**: Native video processing via FFI

- Audio formats: MP3, WAV, M4A, AAC, OGG, FLAC

  - Saturation- **FFmpeg Integration**: Industry-standard video codec support

## 🖥️ System Requirements

  - Fade Effects- **GPU Acceleration**: Hardware-accelerated encoding where available

- **OS**: Windows 10/11

- **FFmpeg**: Required (must be installed and in PATH)  - Zoom- **Batch Processing**: Process multiple videos simultaneously

- **RAM**: 4GB minimum, 8GB recommended

- **Storage**: 500MB for app + space for video processing  - Remove Audio



## 📦 Installation## 🏗️ Architecture



### Option 1: Download Release- ✂️ **Video Splitting**

1. Download the latest release from [Releases](https://github.com/tarikelhamdi/video-forge-pro/releases)

2. Extract the ZIP file  - Custom duration settings```

3. Run `video_editor_pro.exe`

  - Choose output folder┌─────────────────────────────────────────┐

### Option 2: Build from Source

```bash  - Batch processing│         Flutter Desktop (UI)            │

# Clone the repository

git clone https://github.com/tarikelhamdi/video-forge-pro.git│   - Material 3 Design                   │

cd video-forge-pro

- ⚙️ **Export Settings**│   - Riverpod State Management           │

# Install dependencies

flutter pub get  - Multiple resolutions (720p to 4K)│   - Three-Pane Layout                   │



# Build for Windows  - Bitrate control└──────────────┬──────────────────────────┘

flutter build windows --release

  - MP4/MOV formats               │ FFI (Foreign Function Interface)

# Run the app

cd build\windows\x64\runner\Release  - Progress tracking┌──────────────▼──────────────────────────┐

video_editor_pro.exe

```│      C++ Processing Engine              │



## 🎓 How to Use## 🚀 Getting Started│   - FFmpeg Video Processing             │



### Basic Workflow│   - OpenCV (optional)                   │

1. **Add Videos**: Drag & drop video files into Video 1, Video 2, or Outro slots

2. **Add Music**: Drag & drop audio files into the Music slot### Prerequisites│   - Multi-threaded Operations           │

3. **Add Operations**: Click the settings icon to add effects (portrait, crop, etc.)

4. **Export**: Click Export to process a single timeline or Export All for batch processing└─────────────────────────────────────────┘



### Multi-File Timeline Creation1. **Flutter SDK**```

1. Select multiple video files in your file explorer

2. Drag and drop them into any slot (Video 1, Video 2, or Music)   ```bash

3. Choose from the confirmation dialog:

   - **Create X Timelines**: Auto-generate timelines for all files   git clone https://github.com/flutter/flutter.git## 📋 Requirements

   - **Add First File Only**: Add only the first file manually

   - **Cancel**: Abort the operation   ```



### Export Settings### Flutter Desktop

- **Single Export**: Choose output folder for each timeline

- **Export All**: Select folder once, all videos export with unique names2. **FFmpeg**- Flutter SDK 3.0+

- **Naming**: `timeline_ID_timestamp.mp4` format

- **Automatic Cleanup**: Temp files deleted after each export   - Using Chocolatey:- Dart SDK 3.0+



## 🛠️ Technical Details     ```bash- Windows 10/11, macOS 10.14+, or Linux



### Architecture     choco install ffmpeg

- **Framework**: Flutter 3.x

- **State Management**: Riverpod     ```### C++ Build Tools

- **Video Processing**: FFmpeg CLI

- **Platform**: Windows Desktop (desktop_drop, file_picker)   - Or download from [gyan.dev/ffmpeg/builds](https://www.gyan.dev/ffmpeg/builds/)- CMake 3.15+



### FFmpeg Optimization Settings- C++17 compatible compiler

```bash

-threads 0                    # Use all CPU cores3. **Visual Studio**  - Windows: Visual Studio 2019+ or MinGW

-preset veryfast              # Fast encoding

-crf 26                       # Quality (lower = better, 18-28 recommended)   - Install with C++ development tools  - macOS: Xcode 11+

-c:v libx264                  # H.264 video codec

-c:a aac                      # AAC audio codec   - Or install only the [Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)  - Linux: GCC 9+ or Clang 10+

-pix_fmt yuv420p             # Compatible pixel format

-max_muxing_queue_size 1024  # Memory limit

```

### Installation### FFmpeg

### Performance Comparison

| Operation | Before | After | Improvement |- FFmpeg 4.4+ with development libraries

|-----------|--------|-------|-------------|

| 1-min video processing | 120s | 50-60s | **2-2.5x faster** |1. **Clone the repository**  - libavformat

| RAM usage | 2GB | 1.4GB | **30% less** |

| Output file size | 100MB | 80MB | **20% smaller** |   ```bash  - libavcodec



## 📁 Project Structure   git clone https://github.com/yourusername/video-editor-pro.git  - libavutil



```   cd video-editor-pro  - libavfilter

lib/

├── main.dart                          # App entry point   ```  - libswscale

├── core/

│   └── theme/  - libswresample

│       └── app_theme.dart            # App theme & colors

├── models/2. **Install dependencies**

│   ├── editor_settings.dart          # Editor configuration

│   └── video_project.dart            # Video project model   ```bash## 🚀 Getting Started

├── screens/

│   └── timeline_editor_screen.dart   # Main timeline UI (~1,700 lines)   flutter pub get

└── services/

    ├── file_import_service.dart      # File picker service   ```### 1. Install Flutter Dependencies

    └── video_processing_service_cli.dart  # FFmpeg processing

```



## 🎨 UI Features3. **Run the app**```powershell



- **Dark Theme**: Professional dark interface with neon accents   ```bash# Navigate to project directory

- **Drag & Drop Zones**: Visual feedback for file drops

- **Progress Indicators**: Real-time export progress tracking   flutter run -d windowscd "Video Editor"

- **Responsive Design**: Clean and organized layout

- **Color Coding**:    ```

  - 🔵 Blue: Video slots

  - 🟣 Purple: Outro & Timeline headers# Get Flutter packages

  - 🟠 Orange: Music slot

  - 🟢 Green: Completed status### Buildingflutter pub get



## 🔧 Configuration```



### Video Quality Tiers (Based on Bitrate)To create a portable executable:

```dart

if (bitrate >= 8000)  → CRF 20, preset medium    (High quality)```bash### 2. Install FFmpeg (Windows)

if (bitrate >= 5000)  → CRF 26, preset veryfast  (Balanced)

if (bitrate >= 3000)  → CRF 28, preset veryfast  (Fast)flutter build windows --release

if (bitrate < 3000)   → CRF 30, preset ultrafast (Very fast)

`````````powershell



## 🐛 Troubleshooting# Using Chocolatey



### FFmpeg Not FoundThe output will be in:choco install ffmpeg

```bash

# Install FFmpeg and add to PATH```

# Windows: Download from https://ffmpeg.org/download.html

# Add FFmpeg bin folder to System Environment Variablesbuild/windows/x64/runner/Release/# Or download from https://ffmpeg.org/download.html

```

```# Add FFmpeg to PATH

### Video Export Fails

- Check FFmpeg installation: `ffmpeg -version` in terminal```

- Ensure sufficient disk space

- Verify video file formats are supported## 📝 Usage Guide

- Check output folder permissions

### 3. Build C++ Library

### High Memory Usage

- Close other applications during export### Timeline Editor

- Process fewer timelines at once

- Reduce video quality settings if needed```powershell



## 📝 Roadmap1. Click "Timeline Editor" on home screen# Navigate to C++ directory



### Planned Features2. Drag & drop videos onto timelinecd cpp

- [ ] GPU Acceleration (NVENC/AMD/Intel QuickSync) - 4-6x speedup

- [ ] Parallel Processing - Process multiple timelines simultaneously3. Add operations from the panel:

- [ ] Single-Pass Encoding - Merge operations for 3-4x speedup

- [ ] Preview Window - Real-time video preview   - Click "+" to add operation# Create build directory

- [ ] Advanced Filters - More video effects and filters

- [ ] Custom Presets - Save and load processing presets   - Click "Edit" to adjust parametersmkdir build

- [ ] Cross-Platform - MacOS and Linux support

   - Drag to reorder operationscd build

## 🤝 Contributing

4. (Optional) Add background music

Contributions are welcome! Please feel free to submit a Pull Request.

5. Preview or Export# Configure with CMake

1. Fork the repository

2. Create your feature branch (`git checkout -b feature/AmazingFeature`)cmake ..

3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)

4. Push to the branch (`git push origin feature/AmazingFeature`)### Video Splitting

5. Open a Pull Request

# Build

## 📄 License

1. Click "Split Video" on home screencmake --build . --config Release

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

2. Drag & drop a video

## 👤 Author

3. Set min/max durations# Copy library to Flutter project root

**Tarik El Hamdi**

- GitHub: [@tarikelhamdi](https://github.com/tarikelhamdi)4. Choose output foldercopy Release\video_processor.dll ..\..\



## 🙏 Acknowledgments5. Click "Split Video"```



- [Flutter](https://flutter.dev/) - UI Framework

- [FFmpeg](https://ffmpeg.org/) - Video processing engine

- [Riverpod](https://riverpod.dev/) - State management### Export Settings### 4. Run the Application

- [desktop_drop](https://pub.dev/packages/desktop_drop) - Drag & drop support

- [file_picker](https://pub.dev/packages/file_picker) - File selection



## 📊 Stats1. Click Settings in sidebar```powershell



- **Lines of Code**: ~1,700 (timeline_editor_screen.dart)2. Choose resolution:# Return to project root

- **Build Size**: ~50MB (Windows Release)

- **Supported Formats**: 4 video + 6 audio formats   - 720p (1280x720)cd ..\..

- **Processing Speed**: 2-2.5x faster than standard FFmpeg

   - 1080p (1920x1080)

---

   - 1440p (2560x1440)# Run Flutter desktop app

**Made with ❤️ using Flutter**

   - 4K (3840x2160)flutter run -d windows

3. Adjust bitrate```

4. Settings save automatically

## 📁 Project Structure

## 🏗️ Project Structure

```

\`\`\`Video Editor/

lib/├── lib/

├── core/│   ├── core/

│   └── theme/│   │   └── theme/

│       └── app_theme.dart      # Theme & styling│   │       └── app_theme.dart          # Material 3 theme

├── models/│   ├── models/

│   ├── editor_settings.dart    # Settings model│   │   ├── app_settings.dart           # Application settings

│   ├── video_project.dart      # Project model│   │   ├── video_clip.dart             # Video clip model

│   └── timeline.dart           # Timeline model│   │   ├── outro_clip.dart             # Outro clip model

├── providers/│   │   ├── music_track.dart            # Music track model

│   └── app_providers.dart      # State management│   │   ├── processing_job.dart         # Processing job model

├── screens/│   │   └── video_project.dart          # Video project model

│   ├── home_screen.dart        # Main menu│   ├── services/

│   ├── settings_screen.dart    # Settings UI│   │   ├── database_service.dart       # SQLite database

│   ├── split_video_screen.dart # Video splitting│   │   ├── video_processing_service.dart # High-level processing

│   └── timeline_screen.dart    # Timeline editor│   │   └── ffi/

├── services/│   │       └── video_processing_ffi.dart # FFI bindings

│   ├── storage_service.dart    # File handling│   ├── screens/

│   └── video_processing.dart   # FFmpeg integration│   │   ├── home_screen.dart            # Dashboard

└── main.dart                   # App entry point│   │   ├── editor_screen.dart          # Video editor

\`\`\`│   │   ├── music_screen.dart           # Music library

│   │   ├── outros_screen.dart          # Outros library

## 🔧 Technical Details│   │   └── settings_screen.dart        # Settings

│   ├── widgets/

### FFmpeg Integration│   │   └── navigation_sidebar.dart     # Side navigation

│   └── main.dart                       # Application entry

The app uses FFmpeg for video processing:│

├── cpp/

```dart│   ├── include/

await Process.run('ffmpeg', [│   │   └── video_processor.h           # C++ header

  '-i', inputPath,│   ├── src/

  '-vf', 'scale=1080:1920,setsar=1:1',│   │   └── video_processor.cpp         # C++ implementation

  '-c:v', 'libx264',│   └── CMakeLists.txt                  # CMake build config

  '-preset', 'medium',│

  '-crf', '23',├── assets/

  outputPath│   ├── fonts/                          # Poppins font files

]);│   ├── icons/                          # App icons

```│   └── images/                         # Images

│

### State Management├── pubspec.yaml                        # Flutter dependencies

└── README.md                           # This file

Using Riverpod for state management:```



```dart## 🎨 Color Palette

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {

  return SettingsNotifier();- **Dark Background**: `#121212`

});- **Dark Surface**: `#1E1E1E`

```- **Neon Blue**: `#00D4FF`

- **Neon Purple**: `#9D4EDD`

### Performance Optimization- **Text Primary**: `#FFFFFF`

- **Text Secondary**: `#B0B0B0`

- Hardware acceleration using FFmpeg

- Efficient timeline rendering## 🔧 Configuration

- Background processing

- Progress tracking### Export Settings

- **Formats**: MP4, MOV

## 📱 Supported Formats- **Resolutions**: 720p, 1080p, 1440p, 4K

- **Aspect Ratio**: 9:16 (Portrait)

### Input- **Bitrate**: Configurable (default 5000 kbps)

- Video: MP4, MOV, AVI, MKV, WebM

- Audio: MP3, WAV, AAC, M4A### Processing Options

- **Clip Duration**: 10-15 seconds (configurable)

### Output- **Outro Rotation**: Sequential or Random

- Video: MP4, MOV- **Music Rotation**: Sequential or Random

- Quality: Up to 4K (3840x2160)- **Fade In/Out**: Configurable duration

- Codecs: H.264, AAC

## 📝 Development Notes

## 🤝 Contributing

### Current Implementation Status

1. Fork the repository✅ **Completed**:

2. Create a branch: \`git checkout -b feature-name\`- Project structure and dependencies

3. Make changes and commit: \`git commit -m 'Add feature'\`- Data models (VideoClip, OutroClip, MusicTrack, etc.)

4. Push to branch: \`git push origin feature-name\`- Modern Material 3 UI theme

5. Create a Pull Request- Database service with SQLite

- FFI bindings structure

## 📜 License- C++ header and template implementation

- Main application screens

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.- Navigation sidebar



## 🙏 Acknowledgments🚧 **In Progress**:

- C++ FFmpeg integration

- [Flutter](https://flutter.dev)- Video processing implementation

- [FFmpeg](https://ffmpeg.org)- Editor workspace UI

- [desktop_drop](https://pub.dev/packages/desktop_drop)- Progress tracking UI

- [file_picker](https://pub.dev/packages/file_picker)

📋 **Planned**:

---- Settings screen implementation

- Export results UI

# 🇸🇦 النسخة العربية- File picker integration

- Video player integration

## ✨ المميزات- Batch processing queue

- AI-based smart cropping

- 🎬 **محرر الخط الزمني**

  - واجهة سحب وإفلات### Known Limitations

  - مسارات فيديو متعددة- C++ library requires manual FFmpeg installation

  - مسار صوتي مع تكرار تلقائي- GPU acceleration depends on system capabilities

  - معاينة وتصدير- Large video files may require significant memory



- 🔄 **عمليات الفيديو**## 🤝 Contributing

  - وضع البورتريه (9:16)

  - التحكم في السرعة (0.25x - 4x)This is a personal project. Suggestions and improvements are welcome!

  - السطوع والتباين

  - التشبع## 📄 License

  - تأثيرات التلاشي

  - التكبيرThis project is for educational and personal use.

  - إزالة الصوت

## 🙏 Acknowledgments

- ✂️ **تقطيع الفيديو**

  - إعدادات المدة المخصصة- **Flutter Team**: For the amazing desktop framework

  - اختيار مجلد الإخراج- **FFmpeg Project**: For the powerful video processing library

  - معالجة دفعية- **Material Design**: For the beautiful UI components



- ⚙️ **إعدادات التصدير**## 📞 Support

  - دقة متعددة (720p إلى 4K)

  - التحكم في معدل البتFor issues or questions:

  - صيغ MP4/MOV1. Check the troubleshooting section below

  - تتبع التقدم2. Review FFmpeg documentation

3. Check Flutter desktop documentation

## 🚀 البدء

## 🔍 Troubleshooting

### المتطلبات المسبقة

### FFmpeg Not Found

1. **Flutter SDK**```powershell

2. **FFmpeg**# Verify FFmpeg installation

3. **Visual Studio** مع أدوات تطوير C++ffmpeg -version



### التثبيت# Add to PATH if needed

setx PATH "%PATH%;C:\path\to\ffmpeg\bin"

1. استنسخ المستودع```

2. ثبّت التبعيات: \`flutter pub get\`

3. شغّل التطبيق: \`flutter run -d windows\`### C++ Build Errors

- Ensure Visual Studio C++ tools are installed

### البناء- Verify CMake version is 3.15+

- Check FFmpeg development libraries are accessible

لإنشاء ملف تنفيذي محمول:

```bash### Flutter Build Errors

flutter build windows --release```powershell

```# Clean and rebuild

flutter clean

## 📝 دليل الاستخدامflutter pub get

flutter run -d windows

### محرر الخط الزمني```



1. انقر على "Timeline Editor"---

2. اسحب وأفلت الفيديوهات

3. أضف العمليات من اللوحة**Built with ❤️ using Flutter and C++**

4. أضف موسيقى خلفية (اختياري)
5. عاين أو صدّر

### تقطيع الفيديو

1. انقر على "Split Video"
2. اسحب وأفلت فيديو
3. اضبط المدد
4. اختر مجلد الإخراج
5. انقر على "Split Video"

### إعدادات التصدير

1. انقر على الإعدادات
2. اختر الدقة (720p إلى 4K)
3. اضبط معدل البت
4. تُحفظ الإعدادات تلقائياً

## 🔧 متطلبات النظام

- Windows 10/11 (64-bit)
- 4GB RAM (8GB موصى به)
- 2GB مساحة حرة
- FFmpeg مثبت