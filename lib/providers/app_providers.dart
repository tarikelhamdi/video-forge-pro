import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_clip.dart';
import '../models/outro_clip.dart';
import '../models/music_track.dart';
import '../models/app_settings.dart';

/// Provider for application settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(_defaultSettings());

  static AppSettings _defaultSettings() {
    return AppSettings(
      inputFolderPath: r'C:\Videos\Input',
      outroFolderPath: r'C:\Videos\Outros',
      musicFolderPath: r'C:\Videos\Music',
      outputFolderPath: r'C:\Videos\Output',
      tempFolderPath: r'C:\Videos\Temp',
      exportSettings: ExportSettings(),
      outroRotationMode: RotationMode.sequential,
      musicRotationMode: RotationMode.sequential,
      autoDeleteTempFiles: true,
      autoOpenFolderAfterExport: false,
      themeMode: ThemeMode.dark,
      lastOutroIndex: 0,
      lastMusicIndex: 0,
    );
  }

  void updateSettings(AppSettings settings) {
    state = settings;
  }

  void updateExportSettings(ExportSettings exportSettings) {
    state = state.copyWith(exportSettings: exportSettings);
  }

  void updateRotationMode(RotationMode outroMode, RotationMode musicMode) {
    state = state.copyWith(
      outroRotationMode: outroMode,
      musicRotationMode: musicMode,
    );
  }

  void updateFolderPaths({
    String? inputFolder,
    String? outroFolder,
    String? musicFolder,
    String? outputFolder,
  }) {
    state = state.copyWith(
      inputFolderPath: inputFolder,
      outroFolderPath: outroFolder,
      musicFolderPath: musicFolder,
      outputFolderPath: outputFolder,
    );
  }

  // Individual folder updates
  void updateOutputFolder(String path) {
    state = state.copyWith(outputFolderPath: path);
  }

  void updateOutroFolder(String path) {
    state = state.copyWith(outroFolderPath: path);
  }

  void updateMusicFolder(String path) {
    state = state.copyWith(musicFolderPath: path);
  }

  // Export settings updates
  void updateResolution(ExportResolution resolution) {
    state = state.copyWith(
      exportSettings: state.exportSettings.copyWith(resolution: resolution),
    );
  }

  void updateFormat(ExportFormat format) {
    state = state.copyWith(
      exportSettings: state.exportSettings.copyWith(format: format),
    );
  }

  void updateCropMode(CropMode cropMode) {
    state = state.copyWith(
      exportSettings: state.exportSettings.copyWith(cropMode: cropMode),
    );
  }

  // Rotation mode updates
  void updateOutroRotation(RotationMode mode) {
    state = state.copyWith(outroRotationMode: mode);
  }

  void updateMusicRotation(RotationMode mode) {
    state = state.copyWith(musicRotationMode: mode);
  }

  // Boolean settings
  void updateAutoDelete(bool value) {
    state = state.copyWith(autoDeleteTempFiles: value);
  }

  void updateAutoOpen(bool value) {
    state = state.copyWith(autoOpenFolderAfterExport: value);
  }
}

/// Provider for video clips
final videoClipsProvider = StateNotifierProvider<VideoClipsNotifier, List<VideoClip>>((ref) {
  return VideoClipsNotifier();
});

class VideoClipsNotifier extends StateNotifier<List<VideoClip>> {
  VideoClipsNotifier() : super([]);

  void addClip(VideoClip clip) {
    state = [...state, clip];
  }

  void addClips(List<VideoClip> clips) {
    state = [...state, ...clips];
  }

  void removeClip(String clipId) {
    state = state.where((clip) => clip.id != clipId).toList();
  }

  void clear() {
    state = [];
  }
}

/// Provider for outro clips
final outroClipsProvider = StateNotifierProvider<OutroClipsNotifier, List<OutroClip>>((ref) {
  return OutroClipsNotifier();
});

class OutroClipsNotifier extends StateNotifier<List<OutroClip>> {
  OutroClipsNotifier() : super([]);

  void addOutro(OutroClip outro) {
    state = [...state, outro];
  }

  void removeOutro(String outroId) {
    state = state.where((outro) => outro.id != outroId).toList();
  }

  void clear() {
    state = [];
  }

  OutroClip? getNextOutro(RotationMode mode, int lastIndex) {
    if (state.isEmpty) return null;
    
    if (mode == RotationMode.random) {
      final randomIndex = DateTime.now().millisecond % state.length;
      return state[randomIndex];
    } else {
      final nextIndex = (lastIndex + 1) % state.length;
      return state[nextIndex];
    }
  }
}

/// Provider for music tracks
final musicTracksProvider = StateNotifierProvider<MusicTracksNotifier, List<MusicTrack>>((ref) {
  return MusicTracksNotifier();
});

class MusicTracksNotifier extends StateNotifier<List<MusicTrack>> {
  MusicTracksNotifier() : super([]);

  void addTrack(MusicTrack track) {
    state = [...state, track];
  }

  void removeTrack(String trackId) {
    state = state.where((track) => track.id != trackId).toList();
  }

  void clear() {
    state = [];
  }

  MusicTrack? getNextTrack(RotationMode mode, int lastIndex) {
    if (state.isEmpty) return null;
    
    if (mode == RotationMode.random) {
      final randomIndex = DateTime.now().millisecond % state.length;
      return state[randomIndex];
    } else {
      final nextIndex = (lastIndex + 1) % state.length;
      return state[nextIndex];
    }
  }
}

/// Provider for processing state
final processingStateProvider = StateNotifierProvider<ProcessingStateNotifier, ProcessingState>((ref) {
  return ProcessingStateNotifier();
});

class ProcessingStateNotifier extends StateNotifier<ProcessingState> {
  ProcessingStateNotifier() : super(ProcessingState.idle);

  void setProcessing() {
    state = ProcessingState.processing;
  }

  void setCompleted() {
    state = ProcessingState.completed;
  }

  void setError() {
    state = ProcessingState.error;
  }

  void setIdle() {
    state = ProcessingState.idle;
  }
}

enum ProcessingState {
  idle,
  processing,
  completed,
  error,
}
