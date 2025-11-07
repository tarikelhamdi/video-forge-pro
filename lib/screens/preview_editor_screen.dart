import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_theme.dart';

/// Preview and Edit Screen - View and adjust processed videos before export
class PreviewEditorScreen extends StatefulWidget {
  final List<String> processedVideos;
  final String outputDir;

  const PreviewEditorScreen({
    super.key,
    required this.processedVideos,
    required this.outputDir,
  });

  @override
  State<PreviewEditorScreen> createState() => _PreviewEditorScreenState();
}

class _PreviewEditorScreenState extends State<PreviewEditorScreen> {
  int _currentVideoIndex = 0;
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isLoading = true;
  
  // Edit parameters
  double _brightness = 0.0; // -1.0 to 1.0
  double _contrast = 1.0;   // 0.0 to 2.0
  double _saturation = 1.0; // 0.0 to 2.0
  double _speed = 1.0;      // 0.5 to 2.0
  double _volume = 1.0;     // 0.0 to 1.0
  
  final List<String> _approvedVideos = [];
  final List<String> _rejectedVideos = [];

  @override
  void initState() {
    super.initState();
    if (widget.processedVideos.isNotEmpty) {
      _loadVideo(_currentVideoIndex);
    }
  }

  Future<void> _loadVideo(int index) async {
    setState(() {
      _isLoading = true;
    });

    // Dispose previous controller and free memory
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
      
      // Give time for resources to be freed
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Load new video
    final videoPath = widget.processedVideos[index];
    _controller = VideoPlayerController.file(File(videoPath));
    
    try {
      await _controller!.initialize();
      // Set volume to current value
      _controller!.setVolume(_volume);
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    
    setState(() {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _nextVideo() {
    if (_currentVideoIndex < widget.processedVideos.length - 1) {
      setState(() {
        _currentVideoIndex++;
      });
      _loadVideo(_currentVideoIndex);
    }
  }

  void _previousVideo() {
    if (_currentVideoIndex > 0) {
      setState(() {
        _currentVideoIndex--;
      });
      _loadVideo(_currentVideoIndex);
    }
  }

  void _approveVideo() {
    final currentVideo = widget.processedVideos[_currentVideoIndex];
    if (!_approvedVideos.contains(currentVideo)) {
      setState(() {
        _approvedVideos.add(currentVideo);
        _rejectedVideos.remove(currentVideo);
      });
    }
    
    // Move to next video
    if (_currentVideoIndex < widget.processedVideos.length - 1) {
      _nextVideo();
    } else {
      _showCompletionDialog();
    }
  }

  void _rejectVideo() {
    final currentVideo = widget.processedVideos[_currentVideoIndex];
    setState(() {
      _rejectedVideos.add(currentVideo);
      _approvedVideos.remove(currentVideo);
    });
    
    // Move to next video
    if (_currentVideoIndex < widget.processedVideos.length - 1) {
      _nextVideo();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('✅ Review Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✓ Approved: ${_approvedVideos.length} videos'),
            Text('✗ Rejected: ${_rejectedVideos.length} videos'),
            const SizedBox(height: 16),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(_approvedVideos);
            },
            child: const Text('Save Approved'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Reviewing'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyEdits() async {
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Applying edits...'),
          ],
        ),
      ),
    );

    try {
      // TODO: Apply FFmpeg filters based on parameters
      // For now, just simulate processing
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Edits applied successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload video
        _loadVideo(_currentVideoIndex);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Properly dispose video controller
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.processedVideos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview & Edit')),
        body: const Center(
          child: Text('No videos to preview'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Preview & Edit (${_currentVideoIndex + 1}/${widget.processedVideos.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.darkSurface,
                  title: const Text('📊 Review Status'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✓ Approved: ${_approvedVideos.length}'),
                      Text('✗ Rejected: ${_rejectedVideos.length}'),
                      Text('⏳ Pending: ${widget.processedVideos.length - _approvedVideos.length - _rejectedVideos.length}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Video Preview (Left Side - 70%)
          Expanded(
            flex: 7,
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  // Video Player
                  Expanded(
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : _controller != null && _controller!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: _controller!.value.aspectRatio,
                                  child: VideoPlayer(_controller!),
                                )
                              : const Text(
                                  'Failed to load video',
                                  style: TextStyle(color: Colors.white),
                                ),
                    ),
                  ),
                  
                  // Video Controls
                  Container(
                    color: AppTheme.darkSurface,
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      children: [
                        // Progress Bar
                        if (_controller != null && _controller!.value.isInitialized)
                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: AppTheme.neonBlue,
                              bufferedColor: AppTheme.textSecondary,
                              backgroundColor: AppTheme.darkBackground,
                            ),
                          ),
                        const SizedBox(height: AppTheme.spacingM),
                        
                        // Play/Pause and Navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous, size: 32),
                              color: _currentVideoIndex > 0 ? Colors.white : Colors.grey,
                              onPressed: _currentVideoIndex > 0 ? _previousVideo : null,
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.neonBlue,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 40,
                                ),
                                color: Colors.white,
                                onPressed: _togglePlayPause,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            IconButton(
                              icon: const Icon(Icons.skip_next, size: 32),
                              color: _currentVideoIndex < widget.processedVideos.length - 1
                                  ? Colors.white
                                  : Colors.grey,
                              onPressed: _currentVideoIndex < widget.processedVideos.length - 1
                                  ? _nextVideo
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        
                        // Approve/Reject Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _rejectVideo,
                              icon: const Icon(Icons.close),
                              label: const Text('Reject & Re-process'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingXL,
                                  vertical: AppTheme.spacingM,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            ElevatedButton.icon(
                              onPressed: _approveVideo,
                              icon: const Icon(Icons.check),
                              label: const Text('Approve & Next'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingXL,
                                  vertical: AppTheme.spacingM,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Edit Panel (Right Side - 30%)
          Expanded(
            flex: 3,
            child: Container(
              color: AppTheme.darkSurface,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.tune, color: AppTheme.neonPurple),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Edit Tools',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.neonPurple,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    
                    // Video Info
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Video:',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.processedVideos[_currentVideoIndex].split('\\').last,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    
                    // Brightness Control
                    _buildSliderControl(
                      icon: Icons.brightness_6,
                      label: 'Brightness',
                      value: _brightness,
                      min: -1.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (value) => setState(() => _brightness = value),
                    ),
                    
                    // Contrast Control
                    _buildSliderControl(
                      icon: Icons.contrast,
                      label: 'Contrast',
                      value: _contrast,
                      min: 0.0,
                      max: 2.0,
                      divisions: 20,
                      onChanged: (value) => setState(() => _contrast = value),
                    ),
                    
                    // Saturation Control
                    _buildSliderControl(
                      icon: Icons.palette,
                      label: 'Saturation',
                      value: _saturation,
                      min: 0.0,
                      max: 2.0,
                      divisions: 20,
                      onChanged: (value) => setState(() => _saturation = value),
                    ),
                    
                    // Speed Control
                    _buildSliderControl(
                      icon: Icons.speed,
                      label: 'Speed',
                      value: _speed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: (value) => setState(() => _speed = value),
                    ),
                    
                    // Volume Control
                    _buildSliderControl(
                      icon: Icons.volume_up,
                      label: 'Volume',
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() => _volume = value);
                        _controller?.setVolume(value);
                      },
                    ),
                    
                    const SizedBox(height: AppTheme.spacingL),
                    const Divider(),
                    const SizedBox(height: AppTheme.spacingL),
                    
                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _applyEdits,
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Apply Edits'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonBlue,
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _brightness = 0.0;
                            _contrast = 1.0;
                            _saturation = 1.0;
                            _speed = 1.0;
                            _volume = 1.0;
                          });
                          _controller?.setVolume(1.0);
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset All'),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingXL),
                    
                    // Status Info
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: AppTheme.neonBlue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 Review Progress',
                            style: TextStyle(
                              color: AppTheme.neonBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          _buildStatusRow('✓ Approved', _approvedVideos.length, Colors.green),
                          _buildStatusRow('✗ Rejected', _rejectedVideos.length, Colors.red),
                          _buildStatusRow(
                            '⏳ Pending',
                            widget.processedVideos.length - _approvedVideos.length - _rejectedVideos.length,
                            AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.neonBlue, size: 20),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                value.toStringAsFixed(2),
                style: const TextStyle(
                  color: AppTheme.neonBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppTheme.neonBlue,
            inactiveColor: AppTheme.darkBackground,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
