/// Application settings and preferences
class AppSettings {
  final String inputFolderPath;
  final String outroFolderPath;
  final String musicFolderPath;
  final String outputFolderPath;
  final String tempFolderPath;
  final ExportSettings exportSettings;
  final RotationMode outroRotationMode;
  final RotationMode musicRotationMode;
  final bool autoDeleteTempFiles;
  final bool autoOpenFolderAfterExport;
  final ThemeMode themeMode;
  final int lastOutroIndex;
  final int lastMusicIndex;
  
  AppSettings({
    required this.inputFolderPath,
    required this.outroFolderPath,
    required this.musicFolderPath,
    required this.outputFolderPath,
    required this.tempFolderPath,
    required this.exportSettings,
    this.outroRotationMode = RotationMode.sequential,
    this.musicRotationMode = RotationMode.sequential,
    this.autoDeleteTempFiles = true,
    this.autoOpenFolderAfterExport = false,
    this.themeMode = ThemeMode.dark,
    this.lastOutroIndex = 0,
    this.lastMusicIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'inputFolderPath': inputFolderPath,
      'outroFolderPath': outroFolderPath,
      'musicFolderPath': musicFolderPath,
      'outputFolderPath': outputFolderPath,
      'tempFolderPath': tempFolderPath,
      'exportSettings': exportSettings.toJson(),
      'outroRotationMode': outroRotationMode.name,
      'musicRotationMode': musicRotationMode.name,
      'autoDeleteTempFiles': autoDeleteTempFiles,
      'autoOpenFolderAfterExport': autoOpenFolderAfterExport,
      'themeMode': themeMode.name,
      'lastOutroIndex': lastOutroIndex,
      'lastMusicIndex': lastMusicIndex,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      inputFolderPath: json['inputFolderPath'],
      outroFolderPath: json['outroFolderPath'],
      musicFolderPath: json['musicFolderPath'],
      outputFolderPath: json['outputFolderPath'],
      tempFolderPath: json['tempFolderPath'],
      exportSettings: ExportSettings.fromJson(json['exportSettings']),
      outroRotationMode: RotationMode.values.byName(json['outroRotationMode']),
      musicRotationMode: RotationMode.values.byName(json['musicRotationMode']),
      autoDeleteTempFiles: json['autoDeleteTempFiles'],
      autoOpenFolderAfterExport: json['autoOpenFolderAfterExport'],
      themeMode: ThemeMode.values.byName(json['themeMode']),
      lastOutroIndex: json['lastOutroIndex'],
      lastMusicIndex: json['lastMusicIndex'],
    );
  }

  AppSettings copyWith({
    String? inputFolderPath,
    String? outroFolderPath,
    String? musicFolderPath,
    String? outputFolderPath,
    String? tempFolderPath,
    ExportSettings? exportSettings,
    RotationMode? outroRotationMode,
    RotationMode? musicRotationMode,
    bool? autoDeleteTempFiles,
    bool? autoOpenFolderAfterExport,
    ThemeMode? themeMode,
    int? lastOutroIndex,
    int? lastMusicIndex,
  }) {
    return AppSettings(
      inputFolderPath: inputFolderPath ?? this.inputFolderPath,
      outroFolderPath: outroFolderPath ?? this.outroFolderPath,
      musicFolderPath: musicFolderPath ?? this.musicFolderPath,
      outputFolderPath: outputFolderPath ?? this.outputFolderPath,
      tempFolderPath: tempFolderPath ?? this.tempFolderPath,
      exportSettings: exportSettings ?? this.exportSettings,
      outroRotationMode: outroRotationMode ?? this.outroRotationMode,
      musicRotationMode: musicRotationMode ?? this.musicRotationMode,
      autoDeleteTempFiles: autoDeleteTempFiles ?? this.autoDeleteTempFiles,
      autoOpenFolderAfterExport: autoOpenFolderAfterExport ?? this.autoOpenFolderAfterExport,
      themeMode: themeMode ?? this.themeMode,
      lastOutroIndex: lastOutroIndex ?? this.lastOutroIndex,
      lastMusicIndex: lastMusicIndex ?? this.lastMusicIndex,
    );
  }
}

/// Export configuration settings
class ExportSettings {
  final ExportFormat format;
  final ExportResolution resolution;
  final int bitrate; // in kbps
  final int audioBitrate; // in kbps
  final bool maintainAspectRatio;
  final CropMode cropMode;
  
  ExportSettings({
    this.format = ExportFormat.mp4,
    this.resolution = ExportResolution.hd1080,
    this.bitrate = 5000,
    this.audioBitrate = 192,
    this.maintainAspectRatio = true,
    this.cropMode = CropMode.smartCrop,
  });

  Map<String, dynamic> toJson() {
    return {
      'format': format.name,
      'resolution': resolution.name,
      'bitrate': bitrate,
      'audioBitrate': audioBitrate,
      'maintainAspectRatio': maintainAspectRatio,
      'cropMode': cropMode.name,
    };
  }

  factory ExportSettings.fromJson(Map<String, dynamic> json) {
    return ExportSettings(
      format: ExportFormat.values.byName(json['format']),
      resolution: ExportResolution.values.byName(json['resolution']),
      bitrate: json['bitrate'],
      audioBitrate: json['audioBitrate'],
      maintainAspectRatio: json['maintainAspectRatio'],
      cropMode: CropMode.values.byName(json['cropMode']),
    );
  }

  ExportSettings copyWith({
    ExportFormat? format,
    ExportResolution? resolution,
    int? bitrate,
    int? audioBitrate,
    bool? maintainAspectRatio,
    CropMode? cropMode,
  }) {
    return ExportSettings(
      format: format ?? this.format,
      resolution: resolution ?? this.resolution,
      bitrate: bitrate ?? this.bitrate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      maintainAspectRatio: maintainAspectRatio ?? this.maintainAspectRatio,
      cropMode: cropMode ?? this.cropMode,
    );
  }
}

enum RotationMode {
  sequential,
  random,
}

enum ThemeMode {
  light,
  dark,
}

enum EditMode {
  splitVideo,
  multipleVideos,
}

enum ExportFormat {
  mp4,
  mov,
}

enum ExportResolution {
  hd720(1280, 720, '720p'),
  hd1080(1920, 1080, '1080p'),
  hd1440(2560, 1440, '1440p'),
  uhd4k(3840, 2160, '4K');

  final int width;
  final int height;
  final String label;

  const ExportResolution(this.width, this.height, this.label);

  // Portrait dimensions (9:16 aspect ratio)
  // For portrait mode, we flip landscape to portrait
  // So if landscape is 1280x720, portrait becomes 720x1280
  int get portraitWidth => height;
  int get portraitHeight => width;
}

enum CropMode {
  smartCrop,
  blurredBackground,
  letterbox,
}
