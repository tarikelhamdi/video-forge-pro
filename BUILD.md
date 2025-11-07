# Build Instructions for Video Editor Pro

## Prerequisites Setup

### 1. Install Flutter
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add to PATH: `C:\src\flutter\bin`
4. Run `flutter doctor` to verify installation

### 2. Install Visual Studio (for C++ compilation)
1. Download Visual Studio 2022 Community
2. During installation, select:
   - "Desktop development with C++"
   - "Windows 10 SDK"
3. Or install Build Tools for Visual Studio 2022

### 3. Install CMake
```powershell
# Using Chocolatey (recommended)
choco install cmake

# Or download installer from https://cmake.org/download/
```

### 4. Install FFmpeg

#### Option A: Using Chocolatey (Easiest)
```powershell
choco install ffmpeg
```

#### Option B: Manual Installation
1. Download FFmpeg from https://www.gyan.dev/ffmpeg/builds/
2. Choose "ffmpeg-release-full-shared.7z"
3. Extract to `C:\ffmpeg`
4. Add to PATH: `C:\ffmpeg\bin`
5. Download FFmpeg dev package for headers and libraries

## Building the Project

### Step 1: Setup Flutter Project

```powershell
# Navigate to project directory
cd "c:\Users\tarik\OneDrive\Bureau\google index\Video Editor"

# Get Flutter packages
flutter pub get

# Enable Windows desktop
flutter config --enable-windows-desktop
```

### Step 2: Build C++ Native Library

```powershell
# Navigate to C++ directory
cd cpp

# Create build directory
New-Item -ItemType Directory -Force -Path build
cd build

# Configure CMake (adjust paths as needed)
cmake .. -G "Visual Studio 17 2022" -A x64 `
  -DFFMPEG_ROOT="C:/ffmpeg"

# Build Release version
cmake --build . --config Release

# Verify DLL was created
dir Release/video_processor.dll
```

### Step 3: Copy Native Library

```powershell
# Copy DLL to Flutter project root
Copy-Item Release/video_processor.dll ../../

# Or copy to build output directory
Copy-Item Release/video_processor.dll ../../build/windows/runner/Release/
```

### Step 4: Build Flutter App

```powershell
# Return to project root
cd ../..

# Build Windows app
flutter build windows --release

# Or run in debug mode
flutter run -d windows
```

## Common Build Issues

### Issue: CMake can't find FFmpeg

**Solution**: Specify FFmpeg path explicitly
```powershell
cmake .. -DFFMPEG_ROOT="C:/path/to/ffmpeg"
```

### Issue: Missing FFmpeg DLLs at runtime

**Solution**: Copy FFmpeg DLLs to output directory
```powershell
# Copy all FFmpeg DLLs
Copy-Item C:/ffmpeg/bin/*.dll build/windows/runner/Release/
```

### Issue: Flutter can't load native library

**Solution**: Verify DLL is in correct location
```powershell
# Should be in project root or build output
dir video_processor.dll
dir build/windows/runner/Release/video_processor.dll
```

### Issue: Access denied errors

**Solution**: Run PowerShell as Administrator
```powershell
# Right-click PowerShell -> Run as Administrator
```

## Development Workflow

### Running in Debug Mode
```powershell
# Hot reload enabled
flutter run -d windows
```

### Building Release Version
```powershell
# Optimized build
flutter build windows --release
```

### Cleaning Build
```powershell
# Clean Flutter build
flutter clean

# Clean C++ build
Remove-Item -Recurse -Force cpp/build
```

## Testing

### Test FFmpeg Integration
```powershell
# Test FFmpeg installation
ffmpeg -version

# Test with sample video
ffmpeg -i input.mp4 -c copy output.mp4
```

### Test C++ Library
Create a test file in `cpp/src/test.cpp`:
```cpp
#include "../include/video_processor.h"
#include <iostream>

int main() {
    if (init_processor() == 0) {
        std::cout << "Video processor initialized successfully!\n";
        cleanup();
        return 0;
    }
    return 1;
}
```

Build and run:
```powershell
cd cpp/build
cmake --build . --config Release --target test
./Release/test.exe
```

## Deployment

### Creating Installer (Optional)

1. Install Inno Setup: https://jrsoftware.org/isdl.php
2. Create installer script (`installer.iss`)
3. Include all dependencies:
   - Flutter app executable
   - video_processor.dll
   - FFmpeg DLLs
   - Visual C++ Redistributable

### Package Structure
```
VideoEditorPro/
├── video_editor_pro.exe
├── video_processor.dll
├── flutter_windows.dll
├── msvcp140.dll
├── vcruntime140.dll
├── avcodec-*.dll
├── avformat-*.dll
├── avutil-*.dll
├── swscale-*.dll
└── data/
    └── ... (Flutter assets)
```

## Platform-Specific Notes

### Windows
- Requires Visual C++ Redistributable 2015-2022
- FFmpeg DLLs must be in same directory as executable
- May need to add to Windows Defender exclusions for better performance

### macOS (Future)
- Use Homebrew for FFmpeg: `brew install ffmpeg`
- Build with Xcode: `cmake -G Xcode ..`
- Sign and notarize for distribution

### Linux (Future)
- Install FFmpeg dev packages: `sudo apt install ffmpeg libavcodec-dev libavformat-dev`
- Build with GCC/Clang
- Create AppImage or Snap for distribution

## Performance Optimization

### C++ Compiler Flags
Add to CMakeLists.txt:
```cmake
if(MSVC)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /arch:AVX2")
else()
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -march=native")
endif()
```

### Flutter Build Flags
```powershell
flutter build windows --release --dart-define=PRODUCTION=true
```

## Next Steps

1. ✅ Build C++ library
2. ✅ Build Flutter app
3. 🔄 Test video processing
4. 🔄 Implement full editor UI
5. 📋 Add batch processing
6. 📋 Create installer

---

**Questions?** Check the main README.md or FFmpeg documentation.
