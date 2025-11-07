import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/app_settings.dart';
import '../models/outro_clip.dart';
import '../models/music_track.dart';
import '../models/video_project.dart';

/// Database service for persistent storage
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'video_editor.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _settingsTable = 'settings';
  static const String _outrosTable = 'outros';
  static const String _musicTable = 'music';
  static const String _projectsTable = 'projects';

  /// Initialize the database
  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDir.path, 'VideoEditorPro', _dbName);
    
    // Ensure directory exists
    await Directory(path.dirname(dbPath)).create(recursive: true);

    _database = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Settings table
    await db.execute('''
      CREATE TABLE $_settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Outros table
    await db.execute('''
      CREATE TABLE $_outrosTable (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        duration INTEGER NOT NULL,
        thumbnail_path TEXT,
        order_index INTEGER NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');

    // Music table
    await db.execute('''
      CREATE TABLE $_musicTable (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        duration INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        added_at TEXT NOT NULL,
        artist TEXT,
        title TEXT
      )
    ''');

    // Projects table
    await db.execute('''
      CREATE TABLE $_projectsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_modified TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await _insertDefaultSettings(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
  }

  Future<void> _insertDefaultSettings(Database db) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final baseDir = path.join(documentsDir.path, 'VideoEditorPro');

    final defaultSettings = AppSettings(
      inputFolderPath: path.join(baseDir, 'Input'),
      outroFolderPath: path.join(baseDir, 'Outros'),
      musicFolderPath: path.join(baseDir, 'Music'),
      outputFolderPath: path.join(baseDir, 'Output'),
      tempFolderPath: path.join(baseDir, 'Temp'),
      exportSettings: ExportSettings(),
    );

    final json = defaultSettings.toJson();
    for (final entry in json.entries) {
      await db.insert(_settingsTable, {
        'key': entry.key,
        'value': entry.value.toString(),
      });
    }
  }

  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _database!;
  }

  // Settings operations
  Future<AppSettings> getSettings() async {
    final results = await database.query(_settingsTable);
    final map = {for (var row in results) row['key'] as String: row['value']};
    
    // Convert map values back to proper types
    final jsonMap = <String, dynamic>{};
    for (final entry in map.entries) {
      jsonMap[entry.key] = _parseValue(entry.value as String);
    }
    
    return AppSettings.fromJson(jsonMap);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final json = settings.toJson();
    final batch = database.batch();
    
    for (final entry in json.entries) {
      batch.insert(
        _settingsTable,
        {'key': entry.key, 'value': entry.value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    if (int.tryParse(value) != null) return int.parse(value);
    if (double.tryParse(value) != null) return double.parse(value);
    if (value.startsWith('{') && value.endsWith('}')) {
      // It's a JSON object string - return as is, will be parsed later
      return value;
    }
    return value;
  }

  // Outro operations
  Future<List<OutroClip>> getOutros() async {
    final results = await database.query(
      _outrosTable,
      orderBy: 'order_index ASC',
    );
    
    return results.map((row) => OutroClip(
      id: row['id'] as String,
      filePath: row['file_path'] as String,
      fileName: row['file_name'] as String,
      duration: Duration(milliseconds: row['duration'] as int),
      thumbnailPath: row['thumbnail_path'] as String?,
      orderIndex: row['order_index'] as int,
      addedAt: DateTime.parse(row['added_at'] as String),
    )).toList();
  }

  Future<void> addOutro(OutroClip outro) async {
    await database.insert(_outrosTable, {
      'id': outro.id,
      'file_path': outro.filePath,
      'file_name': outro.fileName,
      'duration': outro.duration.inMilliseconds,
      'thumbnail_path': outro.thumbnailPath,
      'order_index': outro.orderIndex,
      'added_at': outro.addedAt.toIso8601String(),
    });
  }

  Future<void> deleteOutro(String id) async {
    await database.delete(_outrosTable, where: 'id = ?', whereArgs: [id]);
  }

  // Music operations
  Future<List<MusicTrack>> getMusicTracks() async {
    final results = await database.query(
      _musicTable,
      orderBy: 'order_index ASC',
    );
    
    return results.map((row) => MusicTrack(
      id: row['id'] as String,
      filePath: row['file_path'] as String,
      fileName: row['file_name'] as String,
      duration: Duration(milliseconds: row['duration'] as int),
      orderIndex: row['order_index'] as int,
      addedAt: DateTime.parse(row['added_at'] as String),
      artist: row['artist'] as String?,
      title: row['title'] as String?,
    )).toList();
  }

  Future<void> addMusicTrack(MusicTrack track) async {
    await database.insert(_musicTable, {
      'id': track.id,
      'file_path': track.filePath,
      'file_name': track.fileName,
      'duration': track.duration.inMilliseconds,
      'order_index': track.orderIndex,
      'added_at': track.addedAt.toIso8601String(),
      'artist': track.artist,
      'title': track.title,
    });
  }

  Future<void> deleteMusicTrack(String id) async {
    await database.delete(_musicTable, where: 'id = ?', whereArgs: [id]);
  }

  // Project operations
  Future<List<VideoProject>> getProjects() async {
    final results = await database.query(
      _projectsTable,
      orderBy: 'last_modified DESC',
    );
    
    return results.map((row) {
      // TODO: Parse the JSON data string and deserialize full project
      // final data = row['data'] as String;
      return VideoProject(
        id: row['id'] as String,
        name: row['name'] as String,
        clips: [],
        createdAt: DateTime.parse(row['created_at'] as String),
        lastModified: DateTime.parse(row['last_modified'] as String),
      );
    }).toList();
  }

  Future<void> saveProject(VideoProject project) async {
    await database.insert(
      _projectsTable,
      {
        'id': project.id,
        'name': project.name,
        'data': project.toJson().toString(),
        'created_at': project.createdAt.toIso8601String(),
        'last_modified': project.lastModified.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProject(String id) async {
    await database.delete(_projectsTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Close the database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
