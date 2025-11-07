@echo off
echo ========================================
echo   Video Editor Pro - Complete Build
echo ========================================
echo.

REM Check for FFmpeg
echo [1/4] Checking FFmpeg installation...
ffmpeg -version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] FFmpeg not found!
    echo Please install FFmpeg first. See FFMPEG_INSTALL.md
    echo.
    pause
    exit /b 1
)
echo [✓] FFmpeg found

echo.
echo [2/4] Building C++ library...
cd cpp
call build.bat
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] C++ build failed!
    cd ..
    pause
    exit /b 1
)
cd ..
echo [✓] C++ library built

echo.
echo [3/4] Getting Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Flutter pub get failed!
    pause
    exit /b 1
)
echo [✓] Dependencies downloaded

echo.
echo [4/4] Building Flutter app...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo [ERROR] Flutter build failed!
    pause
    exit /b 1
)
echo [✓] App built successfully!

echo.
echo ========================================
echo          Build Complete! ✓
echo ========================================
echo.
echo Executable location:
echo build\windows\runner\Release\video_editor_pro.exe
echo.
echo To run in debug mode instead:
echo   flutter run -d windows
echo.
pause
