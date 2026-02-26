import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._();
  static Database? _db;

  DBHelper._();

  Future<Database> get database async {
    _db ??= await _initDB();
    await _ensureDefaultAdmin(_db!);
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'asset_inventory.db');
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_number TEXT UNIQUE,
        description TEXT,
        location TEXT,
        remarks TEXT,
        validate TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123'
    });
  }

  Future<void> _ensureDefaultAdmin(Database db) async {
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
      limit: 1,
    );

    if (result.isEmpty) {
      await db.insert('users', {
        'username': 'admin',
        'password': 'admin123',
      });
    }
  }

  Future<void> createUser({
    required String username,
    required String password,
  }) async {
    final db = await database;
    await db.insert('users', {
      'username': username,
      'password': password,
    });
  }
}
