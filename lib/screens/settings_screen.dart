import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../models/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 32, color: AppTheme.neonBlue),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Configure your preferences',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            
            Expanded(
              child: ListView(
                children: [
                  // Folder Paths
                  _SettingSection(
                    title: 'Folder Paths',
                    children: [
                      _FolderSettingTile(
                        icon: Icons.folder_open,
                        title: 'Output Folder',
                        path: settings.outputFolderPath,
                        onChanged: (path) {
                          ref.read(settingsProvider.notifier).updateOutputFolder(path);
                        },
                      ),
                      _FolderSettingTile(
                        icon: Icons.movie,
                        title: 'Outros Folder',
                        path: settings.outroFolderPath,
                        onChanged: (path) {
                          ref.read(settingsProvider.notifier).updateOutroFolder(path);
                        },
                      ),
                      _FolderSettingTile(
                        icon: Icons.music_note,
                        title: 'Music Folder',
                        path: settings.musicFolderPath,
                        onChanged: (path) {
                          ref.read(settingsProvider.notifier).updateMusicFolder(path);
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Export Settings
                  _SettingSection(
                    title: 'Export Settings',
                    children: [
                      _SettingTile(
                        icon: Icons.high_quality,
                        title: 'Video Quality',
                        subtitle: settings.exportSettings.resolution.label,
                        trailing: DropdownButton<ExportResolution>(
                          value: settings.exportSettings.resolution,
                          dropdownColor: AppTheme.darkSurface,
                          items: ExportResolution.values.map((res) {
                            return DropdownMenuItem(
                              value: res,
                              child: Text(res.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(settingsProvider.notifier).updateResolution(value);
                            }
                          },
                        ),
                        onTap: () {},
                      ),
                      _SettingTile(
                        icon: Icons.video_file,
                        title: 'Output Format',
                        subtitle: settings.exportSettings.format.name.toUpperCase(),
                        trailing: DropdownButton<ExportFormat>(
                          value: settings.exportSettings.format,
                          dropdownColor: AppTheme.darkSurface,
                          items: ExportFormat.values.map((format) {
                            return DropdownMenuItem(
                              value: format,
                              child: Text(format.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(settingsProvider.notifier).updateFormat(value);
                            }
                          },
                        ),
                        onTap: () {},
                      ),
                      _SettingTile(
                        icon: Icons.crop,
                        title: 'Crop Mode',
                        subtitle: _getCropModeName(settings.exportSettings.cropMode),
                        trailing: DropdownButton<CropMode>(
                          value: settings.exportSettings.cropMode,
                          dropdownColor: AppTheme.darkSurface,
                          items: CropMode.values.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(_getCropModeName(mode)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(settingsProvider.notifier).updateCropMode(value);
                            }
                          },
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Processing Options
                  _SettingSection(
                    title: 'Processing Options',
                    children: [
                      _SettingTile(
                        icon: Icons.shuffle,
                        title: 'Outro Rotation',
                        subtitle: settings.outroRotationMode.name,
                        trailing: DropdownButton<RotationMode>(
                          value: settings.outroRotationMode,
                          dropdownColor: AppTheme.darkSurface,
                          items: RotationMode.values.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(mode.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(settingsProvider.notifier).updateOutroRotation(value);
                            }
                          },
                        ),
                        onTap: () {},
                      ),
                      _SettingTile(
                        icon: Icons.music_note,
                        title: 'Music Rotation',
                        subtitle: settings.musicRotationMode.name,
                        trailing: DropdownButton<RotationMode>(
                          value: settings.musicRotationMode,
                          dropdownColor: AppTheme.darkSurface,
                          items: RotationMode.values.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(mode.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(settingsProvider.notifier).updateMusicRotation(value);
                            }
                          },
                        ),
                        onTap: () {},
                      ),
                      _SwitchSettingTile(
                        icon: Icons.delete_sweep,
                        title: 'Auto-delete temp files',
                        subtitle: 'Clean up after export',
                        value: settings.autoDeleteTempFiles,
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).updateAutoDelete(value);
                        },
                      ),
                      _SwitchSettingTile(
                        icon: Icons.folder_open,
                        title: 'Auto-open output folder',
                        subtitle: 'Open folder when done',
                        value: settings.autoOpenFolderAfterExport,
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).updateAutoOpen(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCropModeName(CropMode mode) {
    switch (mode) {
      case CropMode.smartCrop:
        return 'Smart Crop';
      case CropMode.blurredBackground:
        return 'Blurred Background';
      case CropMode.letterbox:
        return 'Letterbox';
    }
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.neonBlue,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.neonBlue),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SwitchSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.neonBlue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.neonBlue,
      ),
    );
  }
}

class _FolderSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String path;
  final ValueChanged<String> onChanged;

  const _FolderSettingTile({
    required this.icon,
    required this.title,
    required this.path,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.neonBlue),
      title: Text(title),
      subtitle: Text(
        path,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final result = await FilePicker.platform.getDirectoryPath(
            dialogTitle: 'Select $title',
          );
          if (result != null) {
            onChanged(result);
          }
        },
      ),
    );
  }
}
