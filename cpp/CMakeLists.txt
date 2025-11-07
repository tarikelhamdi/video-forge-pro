# CMake build file for video processor library (CLI-based version)

cmake_minimum_required(VERSION 3.15)
project(video_processor)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(include)

# Source files - using CLI-based version
set(SOURCES src/video_processor_cli.cpp)

# Create shared library
add_library(video_processor SHARED ${SOURCES})

# Set output directory to Flutter's build directory
set_target_properties(video_processor PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../build/windows/runner/Debug"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../build/windows/runner/Debug"
)

# Platform-specific settings
if(WIN32)
    set_target_properties(video_processor PROPERTIES
        PREFIX ""
        SUFFIX ".dll"
    )
    target_compile_definitions(video_processor PRIVATE
        _CRT_SECURE_NO_WARNINGS
    )
elseif(APPLE)
    set_target_properties(video_processor PROPERTIES
        SUFFIX ".dylib"
    )
else()
    set_target_properties(video_processor PROPERTIES
        PREFIX "lib"
        SUFFIX ".so"
    )
endif()

# Install target
install(TARGETS video_processor
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES include/video_processor.h
    DESTINATION include
)
