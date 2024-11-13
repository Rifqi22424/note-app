import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        checklistItems TEXT,
        drawingPath TEXT,
        images TEXT,
        type INTEGER,
        status INTEGER,
        audioPath TEXT,
        deletedAt TEXT,
        createdAt TEXT,
        modifiedAt TEXT
      )
    ''');
  }

  Future<String> insertNote(Note note) async {
    final db = await instance.database;
    await db.insert('notes', note.toMap());
    return note.id;
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(String id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Note>> getNotes() async {
    final db = await instance.database;
    final maps = await db.query('notes');
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  Future<Note?> getNoteById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      return null;
    }
  }
}