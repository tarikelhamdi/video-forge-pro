@echo off
echo Building Video Processor C++ Library...
echo.

REM Create build directory
if not exist "build" mkdir build
cd build

REM Configure with CMake
echo Configuring with CMake...
cmake -G "Visual Studio 17 2022" -A x64 ..
if %errorlevel% neq 0 (
    echo.
    echo CMake configuration failed!
    echo If you don't have Visual Studio 2022, try:
    echo   cmake -G "Visual Studio 16 2019" -A x64 ..
    echo   cmake -G "Visual Studio 15 2017" -A x64 ..
    echo   cmake -G "MinGW Makefiles" ..
    pause
    exit /b 1
)

REM Build
echo.
echo Building...
cmake --build . --config Debug
if %errorlevel% neq 0 (
    echo.
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Build successful!
echo DLL should be in: ..\build\windows\runner\Debug\video_processor.dll
echo.
pause
