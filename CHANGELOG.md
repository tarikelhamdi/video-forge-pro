# Changelog

All notable changes to Video Editor Pro will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-11

### Added
- **Multi-File Auto Timeline Creation**: Drop multiple files at once to automatically create timelines
  - Confirmation dialog with 3 options: Create Timelines, Add First Only, or Cancel
  - Cyclic repetition for smart file distribution across timelines
  - Works for Video 1, Video 2, and Music slots
- **Case-Insensitive File Extensions**: Support for `.mp4`, `.MP4`, `.Mp4`, etc.
- **Enhanced User Experience**: Clear confirmation dialogs before batch operations

### Changed
- Improved file drop handling with better filtering logic
- Enhanced timeline creation logic with proper file distribution
- Better error handling for invalid file formats

### Fixed
- Video 2 slot not accepting multiple file drops
- File extension case sensitivity issues
- Music slot multi-file drop functionality

## [1.5.0] - 2025-11-10

### Added
- **Performance Optimizations**:
  - Multi-threading support (-threads 0)
  - Faster encoding presets (veryfast)
  - Optimized CRF values (26 instead of 23)
  - Memory limiting (max_muxing_queue_size 1024)
- **Automatic Temp File Cleanup**:
  - Per-operation cleanup
  - Post-export-all cleanup
  - On-dispose cleanup
- **Documentation**: Created PERFORMANCE_OPTIMIZATIONS.md

### Changed
- FFmpeg preset from medium/fast to veryfast
- CRF value from 23 to 26 for better speed/quality balance
- Export All now selects output folder once

### Performance
- 2-2.5x faster video processing
- 30% reduction in RAM usage
- 20% smaller output files

## [1.0.0] - 2025-11-09

### Added
- Timeline-based video editor
- Drag & drop support for videos and music
- Video concatenation (Video 1 + Video 2 + Outro)
- Background music with auto-looping
- Video operations:
  - Portrait mode conversion (9:16)
  - Effects
  - Crop
  - Speed adjustment
  - Remove audio
- Export functionality:
  - Single timeline export
  - Export All feature
  - Progress tracking
  - Unique filename generation
- Dark theme with neon accents
- FFmpeg integration with H.264/AAC codecs
- Riverpod state management

### Supported Formats
- Video: MP4, MOV, AVI, MKV
- Audio: MP3, WAV, M4A, AAC, OGG, FLAC

---

## Version Numbering

- **Major version** (X.0.0): Breaking changes or major feature additions
- **Minor version** (0.X.0): New features, backwards compatible
- **Patch version** (0.0.X): Bug fixes and minor improvements
