import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Base local SQLite para el modo offline.
/// - cache: última respuesta de cada GET por API y endpoint.
/// - pendientes: cambios (POST/PUT/DELETE) hechos sin conexión, con la API destino.
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  static const _dbName = 'krosty_offline.db';
  Database? _db;

  static Future<void> init() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await instance.db;
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _crearCache(db);
        await db.execute('''
          CREATE TABLE pendientes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            api TEXT NOT NULL DEFAULT 'web',
            metodo TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            body TEXT,
            creado_en TEXT NOT NULL,
            intentos INTEGER NOT NULL DEFAULT 0,
            estado TEXT NOT NULL DEFAULT 'pendiente',
            ultimo_error TEXT
          )''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 -> v2: caché y pendientes separados por API. Lo existente era de la API web.
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE cache RENAME TO cache_v1');
          await _crearCache(db);
          await db.execute(
              "INSERT INTO cache(api, endpoint, body, actualizado_en) SELECT 'web', endpoint, body, actualizado_en FROM cache_v1");
          await db.execute('DROP TABLE cache_v1');
          await db.execute("ALTER TABLE pendientes ADD COLUMN api TEXT NOT NULL DEFAULT 'web'");
        }
      },
    );
    return _db!;
  }

  static Future<void> _crearCache(Database db) => db.execute('''
        CREATE TABLE cache(
          api TEXT NOT NULL,
          endpoint TEXT NOT NULL,
          body TEXT NOT NULL,
          actualizado_en TEXT NOT NULL,
          PRIMARY KEY (api, endpoint)
        )''');

  // ---------- cache ----------
  Future<void> guardarCache(String api, String endpoint, String body) async {
    await (await db).insert(
      'cache',
      {'api': api, 'endpoint': endpoint, 'body': body, 'actualizado_en': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> leerCache(String api, String endpoint) async {
    final rows = await (await db)
        .query('cache', where: 'api = ? AND endpoint = ?', whereArgs: [api, endpoint]);
    return rows.isEmpty ? null : rows.first['body'] as String;
  }

  // ---------- pendientes ----------
  Future<int> encolar(String api, String metodo, String endpoint, String? body) async {
    return (await db).insert('pendientes', {
      'api': api,
      'metodo': metodo,
      'endpoint': endpoint,
      'body': body,
      'creado_en': DateTime.now().toIso8601String(),
    });
  }

  /// Pendientes en orden de creación (se envían en ese orden).
  Future<List<Map<String, Object?>>> listarPendientes({bool incluirConError = true}) async {
    return (await db).query(
      'pendientes',
      where: incluirConError ? null : "estado = 'pendiente'",
      orderBy: 'id ASC',
    );
  }

  /// Versión actual de un pendiente (su endpoint/body pueden cambiar al sincronizar).
  Future<Map<String, Object?>?> obtenerPendiente(int id) async {
    final rows = await (await db).query('pendientes', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> contarPendientes() async {
    final r = await (await db).rawQuery('SELECT COUNT(*) AS c FROM pendientes');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<void> eliminarPendiente(int id) async {
    await (await db).delete('pendientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> marcarError(int id, String error) async {
    await (await db).rawUpdate(
      "UPDATE pendientes SET estado = 'error', intentos = intentos + 1, ultimo_error = ? WHERE id = ?",
      [error, id],
    );
  }

  Future<void> actualizarPendiente(int id, String endpoint, String? body) async {
    await (await db).update('pendientes', {'endpoint': endpoint, 'body': body},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reintentar(int id) async {
    await (await db).update('pendientes', {'estado': 'pendiente'}, where: 'id = ?', whereArgs: [id]);
  }
}
