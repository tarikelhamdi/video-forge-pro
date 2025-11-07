import 'package:flutter/material.dart';

/// Timeline model - Represents a single timeline with tracks and operations
class Timeline {
  String name;
  List<String> videoTracks;
  String? audioTrack;
  List<VideoOperation> operations;

  Timeline({
    required this.name,
    required this.videoTracks,
    this.audioTrack,
    required this.operations,
  });
}

/// Video Operation Types
enum OperationType {
  removeAudio,
  portrait,
  speed,
  brightness,
  contrast,
  saturation,
  fade,
  zoom,
}

/// Video Operation Model
class VideoOperation {
  final OperationType type;
  final Map<String, dynamic> parameters;

  VideoOperation({
    required this.type,
    required this.parameters,
  });

  String get name {
    switch (type) {
      case OperationType.removeAudio:
        return 'Remove Audio';
      case OperationType.portrait:
        return 'Portrait (9:16)';
      case OperationType.speed:
        return 'Speed ${parameters['speed'] ?? 1.0}x';
      case OperationType.brightness:
        return 'Brightness ${parameters['brightness'] ?? 0}';
      case OperationType.contrast:
        return 'Contrast ${parameters['contrast'] ?? 1.0}';
      case OperationType.saturation:
        return 'Saturation ${parameters['saturation'] ?? 1.0}';
      case OperationType.fade:
        return 'Fade ${parameters['duration'] ?? 0.5}s';
      case OperationType.zoom:
        return 'Zoom ${parameters['zoom'] ?? 1.0}x';
    }
  }

  IconData get icon {
    switch (type) {
      case OperationType.removeAudio:
        return Icons.volume_off;
      case OperationType.portrait:
        return Icons.crop_portrait;
      case OperationType.speed:
        return Icons.speed;
      case OperationType.brightness:
        return Icons.brightness_6;
      case OperationType.contrast:
        return Icons.contrast;
      case OperationType.saturation:
        return Icons.palette;
      case OperationType.fade:
        return Icons.gradient;
      case OperationType.zoom:
        return Icons.zoom_in;
    }
  }
}
