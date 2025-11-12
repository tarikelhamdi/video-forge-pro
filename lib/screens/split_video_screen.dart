import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_theme.dart';
import '../services/video_processing_service_cli.dart';
import 'timeline_editor_screen.dart';
import 'dart:io';

/// Split Video Screen - Dedicated screen for video splitting only
class SplitVideoScreen extends ConsumerStatefulWidget {
  const SplitVideoScreen({super.key});

  @override
  ConsumerState<SplitVideoScreen> createState() => _SplitVideoScreenState();
}

class _SplitVideoScreenState extends ConsumerState<SplitVideoScreen> {
  String? _selectedVideo;
  String? _outputDirectory; // مجلد الحفظ المختار
  bool _isDragging = false;
  bool _isSplitting = false;
  double _progress = 0.0;
  String _statusMessage = '';
  List<String> _splitClips = [];
  
  // Split settings (0 seconds to 10 minutes = 600 seconds)
  int _minClipDuration = 10;
  int _maxClipDuration = 15;
  bool _discardShortClips = true;

  Future<void> _handleDrop(List<XFile> files) async {
    if (files.isEmpty) return;
    
    final file = files.first;
    final path = file.path;
    final extension = path.toLowerCase().split('.').last;
    
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
      setState(() {
        _selectedVideo = path;
        _splitClips.clear();
      });
    } else {
      _showError('Invalid video file. Use MP4, MOV, AVI, MKV, or WebM');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectOutputDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Output Folder for Split Clips',
    );

    if (result != null) {
      setState(() {
        _outputDirectory = result;
      });
    }
  }

  Future<void> _startSplitting() async {
    if (_selectedVideo == null) {
      _showError('Please select a video first');
      return;
    }

    setState(() {
      _isSplitting = true;
      _progress = 0.0;
      _statusMessage = 'Initializing...';
      _splitClips.clear();
    });

    try {
      final processingService = VideoProcessingService();
      await processingService.init();

      // Listen to progress
      processingService.processingUpdates.listen((update) {
        if (mounted) {
          setState(() {
            _progress = update.progress;
            _statusMessage = update.message;
          });
        }
      });

      // Create output directory
      final videoFile = File(_selectedVideo!);
      
      // تحديد مجلد الإخراج
      Directory outputDir;
      if (_outputDirectory != null) {
        // استخدام المجلد المختار
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        outputDir = Directory('$_outputDirectory\\split_clips_$timestamp');
      } else {
        // استخدام نفس مجلد الفيديو الأصلي
        final videoDir = videoFile.parent.path;
        outputDir = Directory('$videoDir\\split_clips_${DateTime.now().millisecondsSinceEpoch}');
      }
      outputDir.createSync(recursive: true);

      // Split video
      final clips = await processingService.splitVideo(
        inputPath: _selectedVideo!,
        outputDir: outputDir.path,
        clipDurationSeconds: _maxClipDuration,
        minClipDuration: _minClipDuration,
        maxClipDuration: _maxClipDuration,
      );

      setState(() {
        _splitClips = clips;
        _isSplitting = false;
        _statusMessage = 'Split complete!';
      });

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(clips.length);
      }
    } catch (e) {
      setState(() {
        _isSplitting = false;
        _statusMessage = 'Error: $e';
      });
      _showError('Failed to split video: $e');
    }
  }

  void _showSuccessDialog(int clipsCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Split Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Successfully split into $clipsCount clips'),
            const SizedBox(height: 16),
            const Text(
              'What would you like to do next?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay Here'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimelineEditorScreen(
                    splitClips: _splitClips,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.timeline),
            label: const Text('Go to Timeline Editor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _clearVideo() {
    setState(() {
      _selectedVideo = null;
      _splitClips.clear();
      _progress = 0.0;
      _statusMessage = '';
    });
  }

  /// Format duration in seconds to readable format (MM:SS or XXs)
  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Split Video'),
        actions: [
          if (_selectedVideo != null && !_isSplitting)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearVideo,
              tooltip: 'Clear',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Drop Zone
              SizedBox(
                height: 300,
                child: DropTarget(
                  onDragEntered: (_) => setState(() => _isDragging = true),
                  onDragExited: (_) => setState(() => _isDragging = false),
                  onDragDone: (details) {
                    setState(() => _isDragging = false);
                    _handleDrop(details.files);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? AppTheme.neonBlue.withOpacity(0.1)
                          : AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(
                        color: _isDragging
                            ? AppTheme.neonBlue
                            : _selectedVideo != null
                                ? AppTheme.neonPurple.withOpacity(0.5)
                                : AppTheme.textSecondary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                    child: _selectedVideo == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.video_library,
                                size: 60,
                                color: AppTheme.neonBlue.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Drag & Drop Video Here',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'or click to browse',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                                child: const Icon(
                                  Icons.video_file,
                                  size: 60,
                                  color: AppTheme.neonPurple,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  _selectedVideo!.split('\\').last,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXL),
            
            // Settings Panel
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings, color: AppTheme.neonBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Split Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.neonBlue,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Min Duration: ${_formatDuration(_minClipDuration)}',
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                            Slider(
                              value: _minClipDuration.toDouble(),
                              min: 0,
                              max: 600,
                              divisions: 120,
                              activeColor: AppTheme.neonBlue,
                              onChanged: (value) {
                                setState(() {
                                  _minClipDuration = value.toInt();
                                  if (_minClipDuration > _maxClipDuration) {
                                    _maxClipDuration = _minClipDuration;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Max Duration: ${_formatDuration(_maxClipDuration)}',
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                            Slider(
                              value: _maxClipDuration.toDouble(),
                              min: 0,
                              max: 600,
                              divisions: 120,
                              activeColor: AppTheme.neonPurple,
                              onChanged: (value) {
                                setState(() {
                                  _maxClipDuration = value.toInt();
                                  if (_maxClipDuration < _minClipDuration) {
                                    _minClipDuration = _maxClipDuration;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Discard clips shorter than minimum'),
                    value: _discardShortClips,
                    onChanged: (value) {
                      setState(() {
                        _discardShortClips = value ?? true;
                      });
                    },
                    activeColor: AppTheme.neonBlue,
                  ),
                  
                  const Divider(height: 24, color: AppTheme.darkSurfaceVariant),
                  
                  // Output Directory Selection
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, color: AppTheme.neonPurple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Output Folder',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.darkSurfaceVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _outputDirectory ?? 'Same as video location (default)',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _selectOutputDirectory,
                          icon: const Icon(Icons.folder_open, size: 16),
                          label: const Text('Browse'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                        if (_outputDirectory != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _outputDirectory = null;
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Reset to default',
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXL),
            
            // Progress Section
            if (_isSplitting) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _statusMessage,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          '${_progress.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppTheme.neonBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: LinearProgressIndicator(
                        value: _progress / 100,
                        minHeight: 8,
                        backgroundColor: AppTheme.darkBackground,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonBlue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
            
            // Split Results
            if (_splitClips.isNotEmpty && !_isSplitting) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Split Complete!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.green,
                                ),
                          ),
                          Text(
                            '${_splitClips.length} clips created',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TimelineEditorScreen(
                              splitClips: _splitClips,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.timeline),
                      label: const Text('Edit Clips'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selectedVideo != null && !_isSplitting
                    ? _startSplitting
                    : null,
                icon: const Icon(Icons.content_cut, size: 24),
                label: const Text(
                  'Split Video',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPurple,
                  disabledBackgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
