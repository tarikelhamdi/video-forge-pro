# Video Editor Pro 🎥✨# 🎬 Video Editor Pro



A professional video editor built with Flutter for Windows. Features timeline editing, video splitting, operations (effects, speed, portrait mode), and high-quality exports up to 4K.An advanced desktop video editing application built with Flutter and C++ for high-performance video processing. Designed specifically for creating portrait-format content for TikTok, Instagram Reels, and YouTube Shorts.



[🇸🇦 النسخة العربية](#-النسخة-العربية)## ✨ Features



![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)### Core Functionality

![FFmpeg](https://img.shields.io/badge/FFmpeg-007808?style=for-the-badge&logo=ffmpeg&logoColor=white)- **Split Mode**: Automatically split long videos into 10-15 second clips

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)- **Multi-Video Mode**: Process multiple videos from a folder

- **Automated Editing**: Add outros and background music with rotation tracking

## ✨ Features- **Portrait Optimization**: Auto-convert videos to 9:16 format

- **Smart Cropping**: Multiple crop modes (smart crop, blur background, letterbox)

- 🎬 **Timeline Editor**

  - Drag & drop interface### Modern UI/UX

  - Multiple video tracks- **Material 3 Design**: Sleek, modern interface with dark/light themes

  - Audio track with auto-looping- **Three-Pane Layout**: Navigation sidebar, workspace, and preview panel

  - Preview & Export- **Drag & Drop**: Easy file and folder imports

- **Real-time Preview**: Live video preview with playback controls

- 🔄 **Video Operations**- **Progress Tracking**: Animated processing overlays with FFmpeg logs

  - Portrait Mode (9:16)

  - Speed Control (0.25x - 4x)### Performance

  - Brightness & Contrast- **C++ Engine**: Native video processing via FFI

  - Saturation- **FFmpeg Integration**: Industry-standard video codec support

  - Fade Effects- **GPU Acceleration**: Hardware-accelerated encoding where available

  - Zoom- **Batch Processing**: Process multiple videos simultaneously

  - Remove Audio

## 🏗️ Architecture

- ✂️ **Video Splitting**

  - Custom duration settings```

  - Choose output folder┌─────────────────────────────────────────┐

  - Batch processing│         Flutter Desktop (UI)            │

│   - Material 3 Design                   │

- ⚙️ **Export Settings**│   - Riverpod State Management           │

  - Multiple resolutions (720p to 4K)│   - Three-Pane Layout                   │

  - Bitrate control└──────────────┬──────────────────────────┘

  - MP4/MOV formats               │ FFI (Foreign Function Interface)

  - Progress tracking┌──────────────▼──────────────────────────┐

│      C++ Processing Engine              │

## 🚀 Getting Started│   - FFmpeg Video Processing             │

│   - OpenCV (optional)                   │

### Prerequisites│   - Multi-threaded Operations           │

└─────────────────────────────────────────┘

1. **Flutter SDK**```

   ```bash

   git clone https://github.com/flutter/flutter.git## 📋 Requirements

   ```

### Flutter Desktop

2. **FFmpeg**- Flutter SDK 3.0+

   - Using Chocolatey:- Dart SDK 3.0+

     ```bash- Windows 10/11, macOS 10.14+, or Linux

     choco install ffmpeg

     ```### C++ Build Tools

   - Or download from [gyan.dev/ffmpeg/builds](https://www.gyan.dev/ffmpeg/builds/)- CMake 3.15+

- C++17 compatible compiler

3. **Visual Studio**  - Windows: Visual Studio 2019+ or MinGW

   - Install with C++ development tools  - macOS: Xcode 11+

   - Or install only the [Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)  - Linux: GCC 9+ or Clang 10+



### Installation### FFmpeg

- FFmpeg 4.4+ with development libraries

1. **Clone the repository**  - libavformat

   ```bash  - libavcodec

   git clone https://github.com/yourusername/video-editor-pro.git  - libavutil

   cd video-editor-pro  - libavfilter

   ```  - libswscale

  - libswresample

2. **Install dependencies**

   ```bash## 🚀 Getting Started

   flutter pub get

   ```### 1. Install Flutter Dependencies



3. **Run the app**```powershell

   ```bash# Navigate to project directory

   flutter run -d windowscd "Video Editor"

   ```

# Get Flutter packages

### Buildingflutter pub get

```

To create a portable executable:

```bash### 2. Install FFmpeg (Windows)

flutter build windows --release

``````powershell

# Using Chocolatey

The output will be in:choco install ffmpeg

```

build/windows/x64/runner/Release/# Or download from https://ffmpeg.org/download.html

```# Add FFmpeg to PATH

```

## 📝 Usage Guide

### 3. Build C++ Library

### Timeline Editor

```powershell

1. Click "Timeline Editor" on home screen# Navigate to C++ directory

2. Drag & drop videos onto timelinecd cpp

3. Add operations from the panel:

   - Click "+" to add operation# Create build directory

   - Click "Edit" to adjust parametersmkdir build

   - Drag to reorder operationscd build

4. (Optional) Add background music

5. Preview or Export# Configure with CMake

cmake ..

### Video Splitting

# Build

1. Click "Split Video" on home screencmake --build . --config Release

2. Drag & drop a video

3. Set min/max durations# Copy library to Flutter project root

4. Choose output foldercopy Release\video_processor.dll ..\..\

5. Click "Split Video"```



### Export Settings### 4. Run the Application



1. Click Settings in sidebar```powershell

2. Choose resolution:# Return to project root

   - 720p (1280x720)cd ..\..

   - 1080p (1920x1080)

   - 1440p (2560x1440)# Run Flutter desktop app

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