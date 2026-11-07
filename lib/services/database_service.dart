import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/resultado_licencia.dart';

/// Almacenamiento local (SQLite). Guarda solo los datos extraídos de la
/// licencia de conducción: es un dato sensible y se queda en el celular.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'rentauto.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async => _crearTablaLicencias(db),
      onUpgrade: (db, oldVersion, newVersion) async => _crearTablaLicencias(db),
    );
  }

  Future<void> _crearTablaLicencias(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS licencias(
        usuario TEXT PRIMARY KEY,
        datos TEXT NOT NULL,
        fechaValidacion TEXT NOT NULL
      )
    ''');
  }

  // Se guardan solo categorías y fechas, nunca la foto del documento
  Future<void> guardarLicencia(String usuario, ResultadoLicencia r) async {
    final db = await database;
    final datos = jsonEncode({
      'nombre': r.nombre,
      'legible': r.legible,
      'categorias': r.categorias
          .map((c) => {
                'categoria': c.codigo,
                'fecha_vencimiento': c.fechaVencimiento,
                'servicio': c.servicio,
              })
          .toList(),
    });

    await db.insert(
      'licencias',
      {
        'usuario': usuario,
        'datos': datos,
        'fechaValidacion': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ResultadoLicencia?> obtenerLicencia(String usuario) async {
    final db = await database;
    final maps = await db.query(
      'licencias',
      where: 'usuario = ?',
      whereArgs: [usuario],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final json =
        jsonDecode(maps.first['datos'] as String) as Map<String, dynamic>;
    return ResultadoLicencia.fromJson(json);
  }
}