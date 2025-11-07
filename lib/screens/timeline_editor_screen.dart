import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_theme.dart';
import '../services/timeline_service.dart';
import '../models/timeline.dart';
import '../providers/app_providers.dart';

/// Timeline Editor Screen - Functional drag & drop timeline editor
class TimelineEditorScreen extends ConsumerStatefulWidget {
  final List<String> splitClips;

  const TimelineEditorScreen({
    super.key,
    required this.splitClips,
  });

  @override
  ConsumerState<TimelineEditorScreen> createState() => _TimelineEditorScreenState();
}

class _TimelineEditorScreenState extends ConsumerState<TimelineEditorScreen> {
  final TimelineService _timelineService = TimelineService();
  
  // Multiple Timelines Support
  final List<Timeline> _timelines = [];
  int _currentTimelineIndex = 0;
  
  bool _isProcessing = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Create first timeline with split clips
    _timelines.add(Timeline(
      name: 'Timeline 1',
      videoTracks: widget.splitClips.isNotEmpty ? [widget.splitClips.first] : [],
      audioTrack: null,
      operations: [],
    ));
  }

  Timeline get _currentTimeline {
    if (_timelines.isEmpty || _currentTimelineIndex < 0 || _currentTimelineIndex >= _timelines.length) {
      // Return a default timeline if index is invalid
      return Timeline(
        name: 'Empty',
        videoTracks: [],
        audioTrack: null,
        operations: [],
      );
    }
    return _timelines[_currentTimelineIndex];
  }

  void _addTimeline() {
    setState(() {
      _timelines.add(Timeline(
        name: 'Timeline ${_timelines.length + 1}',
        videoTracks: [],
        audioTrack: null,
        operations: [],
      ));
      _currentTimelineIndex = _timelines.length - 1;
    });
  }

  void _addVideoTrack() {
    setState(() {
      _currentTimeline.videoTracks.add('');
    });
  }

  void _addOperation() {
    showDialog(
      context: context,
      builder: (context) => _OperationPickerDialog(
        onOperationSelected: (operation) {
          setState(() {
            _currentTimeline.operations.add(operation);
          });
        },
      ),
    );
  }

  Future<void> _handleDrop(List<XFile> files, String trackType, int? trackIndex) async {
    if (files.isEmpty) return;
    
    final file = files.first;
    final path = file.path;
    
    final extension = path.toLowerCase().split('.').last;
    
    if (trackType == 'audio') {
      if (['mp3', 'wav', 'aac', 'm4a', 'ogg'].contains(extension)) {
        setState(() {
          _currentTimeline.audioTrack = path;
        });
      } else {
        _showError('Invalid audio file');
      }
    } else {
      if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
        setState(() {
          if (trackIndex != null && trackIndex < _currentTimeline.videoTracks.length) {
            _currentTimeline.videoTracks[trackIndex] = path;
          }
        });
      } else {
        _showError('Invalid video file');
      }
    }
  }

  // Edit operation parameters
  Future<void> _editOperation(int index) async {
    final operation = _currentTimeline.operations[index];
    final newParams = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _OperationEditDialog(operation: operation),
    );

    if (newParams != null) {
      setState(() {
        _currentTimeline.operations[index] = VideoOperation(
          type: operation.type,
          parameters: newParams,
        );
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // ACTUAL EXPORT FUNCTIONALITY
  Future<void> _exportTimeline() async {
    final timeline = _currentTimeline;
    
    // Validate
    if (timeline.videoTracks.isEmpty || timeline.videoTracks.every((t) => t.isEmpty)) {
      _showError('Add at least one video to export');
      return;
    }

    // Pick output location
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Exported Video',
      fileName: 'exported_${DateTime.now().millisecondsSinceEpoch}.mp4',
      type: FileType.video,
    );

    if (result == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    try {
      // Get export settings from provider
      final settings = ref.read(settingsProvider);
      
      await _timelineService.processTimeline(
        videoTracks: timeline.videoTracks.where((t) => t.isNotEmpty).toList(),
        audioTrack: timeline.audioTrack,
        operations: timeline.operations,
        outputPath: result,
        exportSettings: settings.exportSettings,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Export completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
        _progress = 0.0;
      });
    }
  }

  // ACTUAL PREVIEW FUNCTIONALITY
  Future<void> _previewTimeline() async {
    final timeline = _currentTimeline;
    
    if (timeline.videoTracks.isEmpty || timeline.videoTracks.every((t) => t.isEmpty)) {
      _showError('Add at least one video to preview');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    try {
      // Get export settings from provider
      final settings = ref.read(settingsProvider);
      
      // Create temporary preview file
      final tempDir = Directory.systemTemp;
      final previewPath = '${tempDir.path}\\preview_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _timelineService.previewTimeline(
        videoTracks: timeline.videoTracks.where((t) => t.isNotEmpty).toList(),
        audioTrack: timeline.audioTrack,
        operations: timeline.operations,
        outputPath: previewPath,
        exportSettings: settings.exportSettings,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      setState(() {
        _isProcessing = false;
      });

      // Show preview player
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => _PreviewPlayerDialog(videoPath: previewPath),
        );
      }

      // Cleanup
      try {
        await File(previewPath).delete();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preview failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline Editor'),
        actions: [
          // Timeline Selector
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers),
            tooltip: 'Select Timeline',
            onSelected: (index) {
              if (index >= 0) {
                setState(() {
                  _currentTimelineIndex = index;
                });
              }
            },
            itemBuilder: (context) => [
              ..._timelines.asMap().entries.map((entry) {
                return PopupMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      if (entry.key == _currentTimelineIndex)
                        const Icon(Icons.check, size: 16),
                      const SizedBox(width: 8),
                      Text(entry.value.name),
                    ],
                  ),
                );
              }),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: -1,
                onTap: () {
                  // Use Future.microtask to avoid conflict with PopupMenu close
                  Future.microtask(_addTimeline);
                },
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 8),
                    Text('Add New Timeline'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: _progress),
                  const SizedBox(height: 16),
                  Text('Processing: ${(_progress * 100).toInt()}%'),
                ],
              ),
            )
          : Row(
              children: [
                // Main Timeline Area
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Header with buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppTheme.cardColor,
                        child: Row(
                          children: [
                            Text(
                              _currentTimeline.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _previewTimeline,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Preview'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _exportTimeline,
                              icon: const Icon(Icons.file_download),
                              label: const Text('Export'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Timeline Tracks
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Video Tracks
                            ..._currentTimeline.videoTracks.asMap().entries.map((entry) {
                              return _TrackSlot(
                                trackName: 'Video Track ${entry.key + 1}',
                                file: _currentTimeline.videoTracks[entry.key],
                                onFileDrop: (files) => _handleDrop(files, 'video', entry.key),
                                onFileRemove: () {
                                  setState(() {
                                    _currentTimeline.videoTracks[entry.key] = '';
                                  });
                                },
                                onTrackRemove: _currentTimeline.videoTracks.length > 1
                                    ? () {
                                        setState(() {
                                          _currentTimeline.videoTracks.removeAt(entry.key);
                                        });
                                      }
                                    : null,
                              );
                            }),
                            
                            // Add Track Button
                            _AddTrackButton(onPressed: _addVideoTrack),
                            
                            const SizedBox(height: 24),
                            
                            // Audio Track
                            _TrackSlot(
                              trackName: 'Audio Track',
                              file: _currentTimeline.audioTrack ?? '',
                              onFileDrop: (files) => _handleDrop(files, 'audio', null),
                              onFileRemove: () {
                                setState(() {
                                  _currentTimeline.audioTrack = null;
                                });
                              },
                              isAudioTrack: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Operations Panel
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    border: Border(
                      left: BorderSide(color: AppTheme.borderColor, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Operations Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Operations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: _addOperation,
                              tooltip: 'Add Operation',
                            ),
                          ],
                        ),
                      ),
                      
                      // Operations List
                      Expanded(
                        child: _currentTimeline.operations.isEmpty
                            ? const Center(
                                child: Text(
                                  'No operations added\nClick + to add',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _currentTimeline.operations.length,
                                itemBuilder: (context, index) {
                                  final operation = _currentTimeline.operations[index];
                                  return _OperationCard(
                                    operation: operation,
                                    onDelete: () {
                                      setState(() {
                                        _currentTimeline.operations.removeAt(index);
                                      });
                                    },
                                    onEdit: () {
                                      _editOperation(index);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// Track Slot Widget
class _TrackSlot extends StatefulWidget {
  final String trackName;
  final String file;
  final Function(List<XFile>) onFileDrop;
  final VoidCallback onFileRemove;
  final VoidCallback? onTrackRemove;
  final bool isAudioTrack;

  const _TrackSlot({
    required this.trackName,
    required this.file,
    required this.onFileDrop,
    required this.onFileRemove,
    this.onTrackRemove,
    this.isAudioTrack = false,
  });

  @override
  State<_TrackSlot> createState() => _TrackSlotState();
}

class _TrackSlotState extends State<_TrackSlot> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.file.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Track Name
          SizedBox(
            width: 120,
            child: Text(
              widget.trackName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          
          // Drop Zone
          Expanded(
            child: DropTarget(
              onDragEntered: (_) => setState(() => _isDragging = true),
              onDragExited: (_) => setState(() => _isDragging = false),
              onDragDone: (details) {
                setState(() => _isDragging = false);
                widget.onFileDrop(details.files);
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: _isDragging ? AppTheme.accentColor.withOpacity(0.2) : AppTheme.cardColor,
                  border: Border.all(
                    color: _isDragging ? AppTheme.accentColor : AppTheme.borderColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: hasFile
                    ? _FileChip(
                        fileName: widget.file.split('\\').last,
                        icon: widget.isAudioTrack ? Icons.music_note : Icons.movie,
                        onRemove: widget.onFileRemove,
                      )
                    : Center(
                        child: Text(
                          'Drop ${widget.isAudioTrack ? 'audio' : 'video'} here',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
              ),
            ),
          ),
          
          // Remove Track Button
          if (widget.onTrackRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onTrackRemove,
              tooltip: 'Remove Track',
            ),
          ],
        ],
      ),
    );
  }
}

// File Chip Widget
class _FileChip extends StatelessWidget {
  final String fileName;
  final IconData icon;
  final VoidCallback onRemove;

  const _FileChip({
    required this.fileName,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

// Add Track Button
class _AddTrackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddTrackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 12, left: 120),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: const Text('Add Video Track'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.borderColor),
        ),
      ),
    );
  }
}

// Operation Card Widget
class _OperationCard extends StatelessWidget {
  final VideoOperation operation;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _OperationCard({
    required this.operation,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.cardColor,
      child: ListTile(
        leading: Icon(operation.icon, color: AppTheme.accentColor),
        title: Text(operation.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

// Operation Picker Dialog
class _OperationPickerDialog extends StatelessWidget {
  final Function(VideoOperation) onOperationSelected;

  const _OperationPickerDialog({required this.onOperationSelected});

  @override
  Widget build(BuildContext context) {
    final operations = [
      VideoOperation(
        type: OperationType.removeAudio,
        parameters: {},
      ),
      VideoOperation(
        type: OperationType.portrait,
        parameters: {},
      ),
      VideoOperation(
        type: OperationType.speed,
        parameters: {'speed': 1.0},
      ),
      VideoOperation(
        type: OperationType.brightness,
        parameters: {'brightness': 0.0},
      ),
      VideoOperation(
        type: OperationType.contrast,
        parameters: {'contrast': 1.0},
      ),
      VideoOperation(
        type: OperationType.saturation,
        parameters: {'saturation': 1.0},
      ),
      VideoOperation(
        type: OperationType.fade,
        parameters: {'duration': 0.5},
      ),
      VideoOperation(
        type: OperationType.zoom,
        parameters: {'zoom': 1.0},
      ),
    ];

    return AlertDialog(
      title: const Text('Add Operation'),
      content: SizedBox(
        width: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: operations.length,
          itemBuilder: (context, index) {
            final operation = operations[index];
            return ListTile(
              leading: Icon(operation.icon),
              title: Text(operation.name),
              onTap: () {
                Navigator.pop(context);
                onOperationSelected(operation);
              },
            );
          },
        ),
      ),
    );
  }
}

// Preview Player Dialog
class _PreviewPlayerDialog extends StatefulWidget {
  final String videoPath;

  const _PreviewPlayerDialog({required this.videoPath});

  @override
  State<_PreviewPlayerDialog> createState() => _PreviewPlayerDialogState();
}

class _PreviewPlayerDialogState extends State<_PreviewPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preview'),
      content: _isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const Center(child: CircularProgressIndicator()),
      actions: [
        TextButton(
          onPressed: () {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          },
          child: const Text('Play/Pause'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Operation Edit Dialog
class _OperationEditDialog extends StatefulWidget {
  final VideoOperation operation;

  const _OperationEditDialog({required this.operation});

  @override
  State<_OperationEditDialog> createState() => _OperationEditDialogState();
}

class _OperationEditDialogState extends State<_OperationEditDialog> {
  late Map<String, dynamic> _params;

  @override
  void initState() {
    super.initState();
    _params = Map<String, dynamic>.from(widget.operation.parameters);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      title: Text(
        'Edit ${widget.operation.type.name}',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      content: SizedBox(
        width: 400,
        child: _buildParameterEditor(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _params),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildParameterEditor() {
    switch (widget.operation.type) {
      case OperationType.speed:
        return _buildSpeedEditor();
      case OperationType.brightness:
        return _buildBrightnessEditor();
      case OperationType.contrast:
        return _buildContrastEditor();
      case OperationType.saturation:
        return _buildSaturationEditor();
      case OperationType.fade:
        return _buildFadeEditor();
      case OperationType.zoom:
        return _buildZoomEditor();
      case OperationType.portrait:
      case OperationType.removeAudio:
        return const Text(
          'This operation has no parameters to edit',
          style: TextStyle(color: AppTheme.textSecondary),
        );
    }
  }

  Widget _buildSpeedEditor() {
    double speed = _params['speed'] ?? 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Speed: ${speed.toStringAsFixed(2)}x',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        Slider(
          value: speed,
          min: 0.25,
          max: 4.0,
          divisions: 15,
          label: '${speed.toStringAsFixed(2)}x',
          onChanged: (value) {
            setState(() {
              _params['speed'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBrightnessEditor() {
    double brightness = _params['brightness'] ?? 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Brightness: ${brightness.toStringAsFixed(2)}',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        Slider(
          value: brightness,
          min: -1.0,
          max: 1.0,
          divisions: 20,
          label: brightness.toStringAsFixed(2),
          onChanged: (value) {
            setState(() {
              _params['brightness'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildContrastEditor() {
    double contrast = _params['contrast'] ?? 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Contrast: ${contrast.toStringAsFixed(2)}',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        Slider(
          value: contrast,
          min: 0.0,
          max: 3.0,
          divisions: 30,
          label: contrast.toStringAsFixed(2),
          onChanged: (value) {
            setState(() {
              _params['contrast'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSaturationEditor() {
    double saturation = _params['saturation'] ?? 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Saturation: ${saturation.toStringAsFixed(2)}',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        Slider(
          value: saturation,
          min: 0.0,
          max: 3.0,
          divisions: 30,
          label: saturation.toStringAsFixed(2),
          onChanged: (value) {
            setState(() {
              _params['saturation'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFadeEditor() {
    double duration = _params['duration'] ?? 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Duration: ${duration.toStringAsFixed(1)}s',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        Slider(
          value: duration,
          min: 0.1,
          max: 5.0,
          divisions: 49,
          label: '${duration.toStringAsFixed(1)}s',
          onChanged: (value) {
            setState(() {
              _params['duration'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildZoomEditor() {
    double scale = _params['scale'] ?? 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Zoom Scale: ${scale.toStringAsFixed(2)}x',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        Slider(
          value: scale,
          min: 1.0,
          max: 3.0,
          divisions: 20,
          label: '${scale.toStringAsFixed(2)}x',
          onChanged: (value) {
            setState(() {
              _params['scale'] = value;
            });
          },
        ),
      ],
    );
  }
}
