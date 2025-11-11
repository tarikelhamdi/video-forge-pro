import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../core/theme/app_theme.dart';
import '../models/app_settings.dart';
import '../providers/app_providers.dart';
import '../services/file_import_service.dart';
import '../services/video_processing_service_cli.dart';

class TimelineEditorScreen extends ConsumerStatefulWidget {
  final List<String>? splitClips;

  const TimelineEditorScreen({super.key, this.splitClips});

  @override
  ConsumerState<TimelineEditorScreen> createState() => _TimelineEditorScreenState();
}

class _TimelineEditorScreenState extends ConsumerState<TimelineEditorScreen> {
  final List<TimelineTrack> _timelines = [];
  final FileImportService _fileService = FileImportService();
  int? _currentExportingIndex;
  bool _isExportingAll = false;

  @override
  void initState() {
    super.initState();
    if (widget.splitClips != null && widget.splitClips!.isNotEmpty) {
      for (int i = 0; i < widget.splitClips!.length; i++) {
        _timelines.add(TimelineTrack(
          id: i + 1,
          videoPath: widget.splitClips![i],
          videoName: widget.splitClips![i].split('\\').last,
        ));
      }
    } else {
      _timelines.add(TimelineTrack(id: 1));
    }
  }

  @override
  void dispose() {
    // محاولة حذف أي ملفات temp متبقية عند إغلاق التطبيق
    _cleanupAllTempOnDispose();
    super.dispose();
  }

  /// حذف جميع ملفات temp عند إغلاق الشاشة
  void _cleanupAllTempOnDispose() {
    // نستخدم compute للحذف في background لعدم تأخير الإغلاق
    try {
      // البحث عن مجلدات temp في المواقع الشائعة
      final commonPaths = [
        'C:\\Videos\\Output',
        'C:\\temp',
        Platform.environment['TEMP'] ?? '',
      ];

      for (final basePath in commonPaths) {
        if (basePath.isEmpty) continue;
        
        final dir = Directory(basePath);
        if (dir.existsSync()) {
          dir.list(recursive: false).listen((entity) {
            if (entity is Directory) {
              final name = entity.path.split('\\').last;
              if (name == 'temp' || name.startsWith('temp_')) {
                try {
                  entity.deleteSync(recursive: true);
                  print('✓ Cleaned up on dispose: ${entity.path}');
                } catch (e) {
                  // تجاهل الأخطاء عند الإغلاق
                }
              }
            }
          });
        }
      }
    } catch (e) {
      // تجاهل أي أخطاء عند الإغلاق
    }
  }

  void _addTimeline() {
    setState(() {
      _timelines.add(TimelineTrack(id: _timelines.length + 1));
    });
  }

  Future<void> _exportTimeline(int index, {String? outputFolder}) async {
    final timeline = _timelines[index];
    
    if (timeline.videoPath == null) {
      _showMessage('⚠️ Please add a video to Timeline ${timeline.id}', isError: true);
      return;
    }

    // اختيار مجلد الاستخراج (إذا لم يتم تمريره)
    String? selectedFolder = outputFolder;
    if (selectedFolder == null) {
      selectedFolder = await _fileService.selectOutputFolder();
      if (selectedFolder == null) {
        _showMessage('⚠️ Export cancelled - No output folder selected', isError: true);
        return;
      }
    }

    setState(() {
      _currentExportingIndex = index;
      timeline.isExporting = true;
      timeline.exportProgress = 0.0;
    });

    Directory? tempConcatDir; // لتتبع مجلد temp الخاص بالجمع

    try {
      final settings = ref.read(settingsProvider);
      final processingService = VideoProcessingService();
      await processingService.init();

      processingService.processingUpdates.listen((update) {
        if (mounted && _currentExportingIndex == index) {
          setState(() {
            timeline.exportProgress = update.progress / 100;
            timeline.exportStatus = update.message;
          });
        }
      });

      // جمع الفيديوهات معاً
      String mainVideoPath = timeline.videoPath!;
      
      // إذا كان هناك فيديو ثاني، نجمعهما معاً
      if (timeline.secondVideoPath != null && timeline.secondVideoPath!.isNotEmpty) {
        setState(() {
          timeline.exportStatus = 'جمع الفيديوهات...';
          timeline.exportProgress = 0.05;
        });
        
        tempConcatDir = Directory('${selectedFolder}\\temp_concat_${DateTime.now().millisecondsSinceEpoch}');
        tempConcatDir.createSync(recursive: true);
        
        final concatenatedPath = '${tempConcatDir.path}\\concatenated.mp4';
        
        // إنشاء ملف قائمة الفيديوهات
        final listFile = File('${tempConcatDir.path}\\videos_list.txt');
        listFile.writeAsStringSync(
          "file '${timeline.videoPath!.replaceAll('\\', '/')}'\n"
          "file '${timeline.secondVideoPath!.replaceAll('\\', '/')}'\n"
        );
        
        // جمع الفيديوهات باستخدام FFmpeg - محسّن للسرعة
        final result = await Process.run('ffmpeg', [
          '-threads', '0', // استخدام كل النوى
          '-f', 'concat',
          '-safe', '0',
          '-i', listFile.path,
          '-c:v', 'libx264',
          '-preset', 'veryfast', // تسريع (كان fast)
          '-crf', '26', // جودة جيدة مع سرعة أفضل (كان 23)
          '-c:a', 'aac',
          '-b:a', '192k',
          '-movflags', '+faststart',
          '-y',
          concatenatedPath,
        ]);
        
        if (result.exitCode == 0) {
          mainVideoPath = concatenatedPath;
          setState(() {
            timeline.exportStatus = 'تم جمع الفيديوهات ✓';
            timeline.exportProgress = 0.1;
          });
        } else {
          print('خطأ في جمع الفيديوهات: ${result.stderr}');
          // في حالة الفشل، استخدام الفيديو الأول فقط
          _showMessage('⚠️ Failed to concatenate videos, using first video only', isError: true);
        }
      }

      // إنشاء اسم فريد للفيديو النهائي
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueName = 'timeline_${timeline.id}_$timestamp';

      final results = await processingService.processCompleteWorkflow(
        inputPath: mainVideoPath,
        outputDir: selectedFolder,
        outroPath: timeline.outroPath,
        musicPath: timeline.musicPath,
        settings: settings,
        mode: EditMode.multipleVideos,
        outputFileName: uniqueName,
      );

      if (mounted) {
        setState(() {
          timeline.isExporting = false;
          timeline.isCompleted = true;
          timeline.exportProgress = 1.0;
          timeline.outputPath = results.isNotEmpty ? results.first : null;
        });

        _showMessage('✅ Timeline ${timeline.id} exported successfully!');

        if (!_isExportingAll && index < _timelines.length - 1) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            _exportTimeline(index + 1);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          timeline.isExporting = false;
          timeline.exportStatus = 'Error: ${e.toString()}';
        });
        _showMessage('❌ Export failed: ${e.toString()}', isError: true);
      }
    } finally {
      // حذف ملفات temp بعد العملية
      await _cleanupTempFiles(selectedFolder, tempConcatDir);
      
      if (mounted && _currentExportingIndex == index) {
        setState(() {
          _currentExportingIndex = null;
        });
      }
    }
  }

  /// حذف جميع الملفات المؤقتة بعد اكتمال العملية
  Future<void> _cleanupTempFiles(String? outputFolder, Directory? tempConcatDir) async {
    try {
      if (mounted) {
        setState(() {
          _timelines[_currentExportingIndex ?? 0].exportStatus = 'تنظيف الملفات المؤقتة...';
        });
      }

      // 1. حذف مجلد temp الخاص بجمع الفيديوهات
      if (tempConcatDir != null && await tempConcatDir.exists()) {
        await tempConcatDir.delete(recursive: true);
        print('✓ Deleted temp concat directory: ${tempConcatDir.path}');
      }

      // 2. حذف مجلد temp الخاص بـ FFmpeg processing
      if (outputFolder != null) {
        final ffmpegTempDir = Directory('$outputFolder\\temp');
        if (await ffmpegTempDir.exists()) {
          await ffmpegTempDir.delete(recursive: true);
          print('✓ Deleted FFmpeg temp directory: ${ffmpegTempDir.path}');
        }

        // 3. حذف أي مجلدات temp قديمة متبقية
        final outputDir = Directory(outputFolder);
        if (await outputDir.exists()) {
          await for (final entity in outputDir.list()) {
            if (entity is Directory && entity.path.contains('temp_concat_')) {
              try {
                await entity.delete(recursive: true);
                print('✓ Deleted old temp directory: ${entity.path}');
              } catch (e) {
                print('Warning: Could not delete ${entity.path}: $e');
              }
            }
          }
        }
      }

      print('✓ Cleanup completed successfully');
    } catch (e) {
      print('Warning: Error during cleanup: $e');
      // لا نريد أن يفشل التطبيق بسبب فشل الحذف
    }
  }

  Future<void> _exportAll() async {
    // اختيار مجلد الاستخراج مرة واحدة لجميع الفيديوهات
    final outputFolder = await _fileService.selectOutputFolder();
    if (outputFolder == null) {
      _showMessage('⚠️ Export cancelled - No output folder selected', isError: true);
      return;
    }

    setState(() {
      _isExportingAll = true;
    });

    for (int i = 0; i < _timelines.length; i++) {
      if (_timelines[i].videoPath != null && !_timelines[i].isCompleted) {
        await _exportTimeline(i, outputFolder: outputFolder);
      }
    }

    // حذف شامل لجميع الملفات المؤقتة بعد الانتهاء من جميع العمليات
    await _finalCleanup(outputFolder);

    setState(() {
      _isExportingAll = false;
    });

    if (mounted) {
      _showMessage('🎉 All timelines exported successfully!');
    }
  }

  /// حذف نهائي شامل لجميع الملفات المؤقتة
  Future<void> _finalCleanup(String outputFolder) async {
    try {
      print('🧹 Starting final cleanup...');
      
      final outputDir = Directory(outputFolder);
      if (!await outputDir.exists()) return;

      int deletedCount = 0;
      
      // حذف جميع مجلدات temp ومجلدات temp_concat
      await for (final entity in outputDir.list()) {
        if (entity is Directory) {
          final dirName = entity.path.split('\\').last;
          if (dirName == 'temp' || 
              dirName.startsWith('temp_') || 
              dirName.startsWith('temp_concat_')) {
            try {
              await entity.delete(recursive: true);
              deletedCount++;
              print('✓ Deleted: ${entity.path}');
            } catch (e) {
              print('⚠️ Could not delete ${entity.path}: $e');
            }
          }
        }
      }

      print('✓ Final cleanup completed - Deleted $deletedCount temp directories');
    } catch (e) {
      print('⚠️ Error during final cleanup: $e');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addVideoToTimeline(int index) async {
    final clip = await _fileService.importVideoFile();
    if (clip != null && mounted) {
      setState(() {
        _timelines[index].videoPath = clip.filePath;
        _timelines[index].videoName = clip.fileName;
        // لا تقم بنسخه للخانة الثانية - اجعلها منفصلة
      });
    }
  }

  Future<void> _addSecondVideoToTimeline(int index) async {
    final clip = await _fileService.importVideoFile();
    if (clip != null && mounted) {
      setState(() {
        _timelines[index].secondVideoPath = clip.filePath;
        _timelines[index].secondVideoName = clip.fileName;
      });
    }
  }

  Future<void> _addOutroToTimeline(int index) async {
    final clip = await _fileService.importVideoFile();
    if (clip != null && mounted) {
      setState(() {
        _timelines[index].outroPath = clip.filePath;
        _timelines[index].outroName = clip.fileName;
      });
    }
  }

  Future<void> _addMusicToTimeline(int index) async {
    final music = await _fileService.importMusicTrack();
    if (music != null && mounted) {
      setState(() {
        _timelines[index].musicPath = music.filePath;
        _timelines[index].musicName = music.fileName;
      });
    }
  }

  void _deleteTimeline(int index) {
    setState(() {
      _timelines.removeAt(index);
      for (int i = 0; i < _timelines.length; i++) {
        _timelines[i].id = i + 1;
      }
    });
  }

  void _handleDropVideo(int index, String path, int slot) {
    // التحقق إذا كان هناك عدة ملفات (مفصولة بـ |MULTI|)
    if (path.contains('|MULTI|')) {
      final files = path.split('|MULTI|');
      _createTimelinesFromMultipleFiles(index, files, slot);
      return;
    }
    
    // معالجة ملف واحد (الطريقة القديمة)
    setState(() {
      if (slot == 1) {
        _timelines[index].videoPath = path;
        _timelines[index].videoName = path.split('\\').last;
      } else if (slot == 2) {
        _timelines[index].secondVideoPath = path;
        _timelines[index].secondVideoName = path.split('\\').last;
      } else if (slot == 3) {
        // Music slot
        _timelines[index].musicPath = path;
        _timelines[index].musicName = path.split('\\').last;
      }
    });
  }

  /// إنشاء تايم لاين متعددة من ملفات متعددة مع التكرار الدوري
  Future<void> _createTimelinesFromMultipleFiles(int startIndex, List<String> files, int slot) async {
    // عرض نافذة تأكيد
    final slotName = slot == 1 ? 'Video 1' : slot == 2 ? 'Video 2' : 'Music';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: AppTheme.neonPurple),
            const SizedBox(width: 8),
            Text('Create ${files.length} Timelines?', 
                 style: const TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You dropped ${files.length} files in $slotName.',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose an option:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              // إضافة يدوياً - استخدام الملف الأول فقط
              Navigator.pop(context, null);
              setState(() {
                final path = files.first;
                if (slot == 1) {
                  _timelines[startIndex].videoPath = path;
                  _timelines[startIndex].videoName = path.split('\\').last;
                } else if (slot == 2) {
                  _timelines[startIndex].secondVideoPath = path;
                  _timelines[startIndex].secondVideoName = path.split('\\').last;
                } else if (slot == 3) {
                  _timelines[startIndex].musicPath = path;
                  _timelines[startIndex].musicName = path.split('\\').last;
                }
              });
              _showMessage('✓ Added first file manually', isError: false);
            },
            child: const Text('Add First File Only', style: TextStyle(color: AppTheme.neonBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonPurple,
            ),
            child: Text('Create ${files.length} Timelines', 
                        style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      // جمع كل الملفات حسب النوع من التايم لاين الحالية
      final video1Files = <String>[];
      final video2Files = <String>[];
      final musicFiles = <String>[];
      
      // إضافة الملفات الجديدة حسب slot
      if (slot == 1) {
        video1Files.addAll(files);
        // الاحتفاظ بالملفات الموجودة في slots الأخرى
        if (_timelines[startIndex].secondVideoPath != null) {
          video2Files.add(_timelines[startIndex].secondVideoPath!);
        }
        if (_timelines[startIndex].musicPath != null) {
          musicFiles.add(_timelines[startIndex].musicPath!);
        }
      } else if (slot == 2) {
        video2Files.addAll(files);
        if (_timelines[startIndex].videoPath != null) {
          video1Files.add(_timelines[startIndex].videoPath!);
        }
        if (_timelines[startIndex].musicPath != null) {
          musicFiles.add(_timelines[startIndex].musicPath!);
        }
      } else if (slot == 3) {
        musicFiles.addAll(files);
        if (_timelines[startIndex].videoPath != null) {
          video1Files.add(_timelines[startIndex].videoPath!);
        }
        if (_timelines[startIndex].secondVideoPath != null) {
          video2Files.add(_timelines[startIndex].secondVideoPath!);
        }
      }
      
      // تحديد العدد الأقصى من الملفات
      final maxFiles = [video1Files.length, video2Files.length, musicFiles.length]
          .reduce((a, b) => a > b ? a : b);
      
      if (maxFiles == 0) return;
      
      // حفظ العمليات والخيارات من التايم لاين الحالية قبل حذفها
      final savedOperations = List<String>.from(_timelines[startIndex].operations);
      final savedOutroPath = _timelines[startIndex].outroPath;
      final savedOutroName = _timelines[startIndex].outroName;
      
      // حذف التايم لاين الحالية
      _timelines.removeAt(startIndex);
      
      // إنشاء تايم لاين جديدة بالتكرار الدوري
      for (int i = 0; i < maxFiles; i++) {
        final timeline = TimelineTrack(id: startIndex + i + 1);
        
        // استخدام modulo للتكرار الدوري
        if (video1Files.isNotEmpty) {
          final path = video1Files[i % video1Files.length];
          timeline.videoPath = path;
          timeline.videoName = path.split('\\').last;
        }
        
        if (video2Files.isNotEmpty) {
          final path = video2Files[i % video2Files.length];
          timeline.secondVideoPath = path;
          timeline.secondVideoName = path.split('\\').last;
        }
        
        if (musicFiles.isNotEmpty) {
          final path = musicFiles[i % musicFiles.length];
          timeline.musicPath = path;
          timeline.musicName = path.split('\\').last;
        }
        
        // نسخ العمليات والخيارات المحفوظة
        timeline.operations = List.from(savedOperations);
        timeline.outroPath = savedOutroPath;
        timeline.outroName = savedOutroName;
        
        _timelines.insert(startIndex + i, timeline);
      }
      
      // إعادة ترقيم جميع التايم لاين
      for (int i = 0; i < _timelines.length; i++) {
        _timelines[i].id = i + 1;
      }
      
      // عرض رسالة نجاح
      _showMessage('✅ Created $maxFiles timelines successfully', isError: false);
    });
  }

  void _showOperationDialog(int index) {
    final timeline = _timelines[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Row(
          children: [
            const Icon(Icons.settings, color: AppTheme.neonPurple),
            const SizedBox(width: 8),
            Text('Timeline ${timeline.id} - Operations', 
                 style: const TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // عرض العمليات المضافة
              if (timeline.operations.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.neonBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.neonBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.neonBlue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Active Operations',
                            style: TextStyle(
                              color: AppTheme.neonBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...timeline.operations.map((op) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right, color: AppTheme.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                op,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 18),
                              onPressed: () {
                                setState(() {
                                  timeline.operations.remove(op);
                                });
                                Navigator.pop(context);
                                _showOperationDialog(index);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Remove operation',
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.darkSurfaceVariant),
                const SizedBox(height: 16),
              ],
              // خيارات العمليات المتاحة
              const Text(
                'Add Operation:',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _OperationOption(
                icon: Icons.crop,
                title: 'Crop to 9:16',
                description: 'Convert to portrait format',
                onTap: () {
                  setState(() {
                    if (!timeline.operations.contains('Crop to 9:16')) {
                      timeline.operations.add('Crop to 9:16');
                    }
                  });
                  Navigator.pop(context);
                  _showMessage('✓ Crop operation added');
                },
              ),
              const SizedBox(height: 12),
              _OperationOption(
                icon: Icons.volume_off,
                title: 'Remove Audio',
                description: 'Remove original audio track',
                onTap: () {
                  setState(() {
                    if (!timeline.operations.contains('Remove Audio')) {
                      timeline.operations.add('Remove Audio');
                    }
                  });
                  Navigator.pop(context);
                  _showMessage('✓ Remove audio operation added');
                },
              ),
              const SizedBox(height: 12),
              _OperationOption(
                icon: Icons.auto_fix_high,
                title: 'Add Effects',
                description: 'Apply random effects',
                onTap: () {
                  setState(() {
                    if (!timeline.operations.contains('Add Effects')) {
                      timeline.operations.add('Add Effects');
                    }
                  });
                  Navigator.pop(context);
                  _showMessage('✓ Effects operation added');
                },
              ),
              const SizedBox(height: 12),
              _OperationOption(
                icon: Icons.speed,
                title: 'Change Speed',
                description: 'Adjust playback speed',
                onTap: () {
                  setState(() {
                    if (!timeline.operations.contains('Change Speed')) {
                      timeline.operations.add('Change Speed');
                    }
                  });
                  Navigator.pop(context);
                  _showMessage('✓ Speed operation added');
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
          if (timeline.operations.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  timeline.operations.clear();
                });
                Navigator.pop(context);
                _showMessage('All operations cleared');
              },
              icon: const Icon(Icons.clear_all, color: Colors.red),
              label: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.neonBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              itemCount: _timelines.length,
              itemBuilder: (context, index) {
                return _TimelineCard(
                  timeline: _timelines[index],
                  isExporting: _currentExportingIndex == index,
                  onAddVideo: () => _addVideoToTimeline(index),
                  onAddSecondVideo: () => _addSecondVideoToTimeline(index),
                  onAddOutro: () => _addOutroToTimeline(index),
                  onAddMusic: () => _addMusicToTimeline(index),
                  onExport: () => _exportTimeline(index),
                  onOperation: () => _showOperationDialog(index),
                  onDelete: _timelines.length > 1 ? () => _deleteTimeline(index) : null,
                  onDropVideo: (path, slot) => _handleDropVideo(index, path, slot),
                );
              },
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.neonBlue),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppTheme.spacingM),
          const Icon(Icons.timeline, size: 32, color: AppTheme.neonPurple),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timeline Editor',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_timelines.length} Timeline(s) • ${_timelines.where((t) => t.isCompleted).length} Completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isExportingAll || _timelines.every((t) => t.videoPath == null)
                ? null
                : _exportAll,
            icon: _isExportingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_download),
            label: Text(_isExportingAll ? 'Exporting...' : 'EXPORT ALL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonPurple,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXL,
                vertical: AppTheme.spacingM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _addTimeline,
          icon: const Icon(Icons.add),
          label: const Text('ADD TIMELINE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.darkSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          ),
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final TimelineTrack timeline;
  final bool isExporting;
  final VoidCallback onAddVideo;
  final VoidCallback onAddSecondVideo;
  final VoidCallback onAddOutro;
  final VoidCallback onAddMusic;
  final VoidCallback onExport;
  final VoidCallback onOperation;
  final VoidCallback? onDelete;
  final Function(String path, int slot) onDropVideo;

  const _TimelineCard({
    required this.timeline,
    required this.isExporting,
    required this.onAddVideo,
    required this.onAddSecondVideo,
    required this.onAddOutro,
    required this.onAddMusic,
    required this.onExport,
    required this.onOperation,
    this.onDelete,
    required this.onDropVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isExporting
              ? AppTheme.neonBlue
              : timeline.isCompleted
                  ? Colors.green
                  : AppTheme.darkSurfaceVariant,
          width: 2,
        ),
        boxShadow: [
          if (isExporting)
            BoxShadow(
              color: AppTheme.neonBlue.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLarge),
                topRight: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    'TIMELINE ${timeline.id}',
                    style: const TextStyle(
                      color: AppTheme.neonPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                if (timeline.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (onDelete != null && !isExporting) ...[
                  const SizedBox(width: AppTheme.spacingM),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete Timeline',
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                _MediaSlotWithDrop(
                  icon: Icons.videocam,
                  label: 'Video 1',
                  fileName: timeline.videoName,
                  onTap: isExporting ? null : onAddVideo,
                  onDrop: (path) => onDropVideo(path, 1),
                  color: AppTheme.neonBlue,
                ),
                const SizedBox(width: AppTheme.spacingM),
                _MediaSlotWithDrop(
                  icon: Icons.videocam,
                  label: 'Video 2',
                  fileName: timeline.secondVideoName,
                  onTap: isExporting ? null : onAddSecondVideo,
                  onDrop: (path) => onDropVideo(path, 2),
                  color: AppTheme.neonBlue.withOpacity(0.7),
                ),
                const SizedBox(width: AppTheme.spacingM),
                _MediaSlot(
                  icon: Icons.add_circle_outline,
                  label: 'Outro',
                  fileName: timeline.outroName,
                  onTap: isExporting ? null : onAddOutro,
                  color: AppTheme.neonPurple,
                ),
                const SizedBox(width: AppTheme.spacingM),
                _MusicSlotWithDrop(
                  icon: Icons.music_note,
                  label: 'Music',
                  fileName: timeline.musicName,
                  onTap: isExporting ? null : onAddMusic,
                  onDrop: (path) => onDropVideo(path, 3),
                  color: Colors.orange,
                ),
                const SizedBox(width: AppTheme.spacingM),
                _OperationButton(
                  onTap: isExporting ? null : onOperation,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _ExportButton(
                    timeline: timeline,
                    isExporting: isExporting,
                    onExport: onExport,
                  ),
                ),
              ],
            ),
          ),
          if (isExporting || timeline.exportProgress > 0)
            _ProgressIndicator(
              progress: timeline.exportProgress,
              status: timeline.exportStatus,
            ),
        ],
      ),
    );
  }
}

class _MediaSlot extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? fileName;
  final VoidCallback? onTap;
  final Color color;

  const _MediaSlot({
    required this.icon,
    required this.label,
    this.fileName,
    this.onTap,
    required this.color,
  });

  @override
  State<_MediaSlot> createState() => _MediaSlotState();
}

class _MediaSlotState extends State<_MediaSlot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.fileName != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: hasFile ? widget.color.withOpacity(0.15) : AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: hasFile
                  ? widget.color
                  : _isHovered && widget.onTap != null
                      ? widget.color.withOpacity(0.5)
                      : AppTheme.darkSurfaceVariant,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: hasFile ? widget.color : AppTheme.textSecondary, size: 32),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                widget.label,
                style: TextStyle(
                  color: hasFile ? widget.color : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasFile && widget.fileName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.fileName!.length > 12 ? '${widget.fileName!.substring(0, 12)}...' : widget.fileName!,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final TimelineTrack timeline;
  final bool isExporting;
  final VoidCallback onExport;

  const _ExportButton({
    required this.timeline,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final canExport = timeline.videoPath != null && !timeline.isCompleted;
    return ElevatedButton(
      onPressed: canExport && !isExporting ? onExport : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: timeline.isCompleted
            ? Colors.green
            : isExporting
                ? AppTheme.neonBlue
                : AppTheme.neonPurple,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
      child: isExporting
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                ),
                SizedBox(height: 8),
                Text('Exporting...', style: TextStyle(fontSize: 12)),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(timeline.isCompleted ? Icons.check_circle : Icons.play_arrow, size: 32),
                const SizedBox(height: 8),
                Text(
                  timeline.isCompleted ? 'Completed' : 'Export',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final double progress;
  final String status;

  const _ProgressIndicator({required this.progress, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusLarge),
          bottomRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(color: AppTheme.neonBlue, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.darkSurfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress < 0.3
                    ? AppTheme.neonPurple
                    : progress < 0.7
                        ? AppTheme.neonBlue
                        : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Media Slot with Drag & Drop Support
class _MediaSlotWithDrop extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? fileName;
  final VoidCallback? onTap;
  final Function(String) onDrop;
  final Color color;

  const _MediaSlotWithDrop({
    required this.icon,
    required this.label,
    this.fileName,
    this.onTap,
    required this.onDrop,
    required this.color,
  });

  @override
  State<_MediaSlotWithDrop> createState() => _MediaSlotWithDropState();
}

class _MediaSlotWithDropState extends State<_MediaSlotWithDrop> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.fileName != null;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          // إذا كان هناك أكثر من ملف، نرسلهم جميعاً
          final videoFiles = details.files.where((file) {
            final lowerPath = file.path.toLowerCase();
            return lowerPath.endsWith('.mp4') || 
                   lowerPath.endsWith('.mov') || 
                   lowerPath.endsWith('.avi') ||
                   lowerPath.endsWith('.mkv');
          }).toList();
          
          if (videoFiles.isNotEmpty) {
            // إذا كان ملف واحد، استخدم الطريقة القديمة
            if (videoFiles.length == 1) {
              widget.onDrop(videoFiles.first.path);
            } else {
              // إذا كان أكثر من ملف، نرسل قائمة الملفات
              widget.onDrop(videoFiles.map((f) => f.path).join('|MULTI|'));
            }
          }
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _isDragging
                  ? widget.color.withOpacity(0.3)
                  : hasFile
                      ? widget.color.withOpacity(0.15)
                      : AppTheme.darkBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: _isDragging
                    ? widget.color
                    : hasFile
                        ? widget.color
                        : _isHovered && widget.onTap != null
                            ? widget.color.withOpacity(0.5)
                            : AppTheme.darkSurfaceVariant,
                width: _isDragging ? 3 : 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: hasFile || _isDragging ? widget.color : AppTheme.textSecondary,
                  size: 32,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: hasFile || _isDragging ? widget.color : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasFile && widget.fileName != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.fileName!.length > 12
                          ? '${widget.fileName!.substring(0, 12)}...'
                          : widget.fileName!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Music Slot with Drag & Drop (Audio files only)
class _MusicSlotWithDrop extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? fileName;
  final VoidCallback? onTap;
  final Function(String) onDrop;
  final Color color;

  const _MusicSlotWithDrop({
    required this.icon,
    required this.label,
    this.fileName,
    this.onTap,
    required this.onDrop,
    required this.color,
  });

  @override
  State<_MusicSlotWithDrop> createState() => _MusicSlotWithDropState();
}

class _MusicSlotWithDropState extends State<_MusicSlotWithDrop> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.fileName != null;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          // جمع الملفات الصوتية فقط
          final audioFiles = details.files.where((file) {
            final lowerPath = file.path.toLowerCase();
            return lowerPath.endsWith('.mp3') || 
                   lowerPath.endsWith('.wav') || 
                   lowerPath.endsWith('.m4a') ||
                   lowerPath.endsWith('.aac') ||
                   lowerPath.endsWith('.ogg') ||
                   lowerPath.endsWith('.flac');
          }).toList();
          
          if (audioFiles.isNotEmpty) {
            // إذا كان ملف واحد، استخدم الطريقة القديمة
            if (audioFiles.length == 1) {
              widget.onDrop(audioFiles.first.path);
            } else {
              // إذا كان أكثر من ملف، نرسل قائمة الملفات
              widget.onDrop(audioFiles.map((f) => f.path).join('|MULTI|'));
            }
          } else if (details.files.isNotEmpty) {
            // عرض رسالة خطأ إذا كان الملف ليس صوت
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Please drop an audio file (mp3, wav, m4a, aac, ogg, flac)'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _isDragging
                  ? widget.color.withOpacity(0.3)
                  : hasFile
                      ? widget.color.withOpacity(0.15)
                      : AppTheme.darkBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: _isDragging
                    ? widget.color
                    : hasFile
                        ? widget.color
                        : _isHovered && widget.onTap != null
                            ? widget.color.withOpacity(0.5)
                            : AppTheme.darkSurfaceVariant,
                width: _isDragging ? 3 : 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: hasFile || _isDragging ? widget.color : AppTheme.textSecondary,
                  size: 32,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: hasFile || _isDragging ? widget.color : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasFile && widget.fileName != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.fileName!.length > 12
                          ? '${widget.fileName!.substring(0, 12)}...'
                          : widget.fileName!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (_isDragging)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Drop audio',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Operation Button Widget
class _OperationButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _OperationButton({this.onTap});

  @override
  State<_OperationButton> createState() => _OperationButtonState();
}

class _OperationButtonState extends State<_OperationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.neonPurple.withOpacity(0.15)
                : AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.neonPurple
                  : AppTheme.darkSurfaceVariant,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings,
                color: _isHovered ? AppTheme.neonPurple : AppTheme.textSecondary,
                size: 32,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Operation',
                style: TextStyle(
                  color: _isHovered ? AppTheme.neonPurple : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Operation Option Widget for Dialog
class _OperationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _OperationOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.darkSurfaceVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: AppTheme.neonPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(icon, color: AppTheme.neonPurple, size: 24),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

class TimelineTrack {
  int id;
  String? videoPath;
  String? videoName;
  String? secondVideoPath;
  String? secondVideoName;
  String? outroPath;
  String? outroName;
  String? musicPath;
  String? musicName;
  bool isExporting = false;
  bool isCompleted = false;
  double exportProgress = 0.0;
  String exportStatus = '';
  String? outputPath;
  List<String> operations = []; // العمليات المضافة

  TimelineTrack({
    required this.id,
    this.videoPath,
    this.videoName,
    this.secondVideoPath,
    this.secondVideoName,
    this.outroPath,
    this.outroName,
    this.musicPath,
    this.musicName,
  });
}
