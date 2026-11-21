import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/resultado_licencia.dart';

/// Almacenamiento local (SQLite): licencia validada y teléfono del perfil.
/// Son datos personales y se quedan en el celular.
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
      version: 6,
      onCreate: (db, version) async => _crearTablas(db),
      onUpgrade: (db, oldVersion, newVersion) async => _crearTablas(db),
    );
  }

  Future<void> _crearTablas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS licencias(
        usuario TEXT PRIMARY KEY,
        datos TEXT NOT NULL,
        fechaValidacion TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS perfil(
        usuario TEXT PRIMARY KEY,
        telefono TEXT NOT NULL
      )
    ''');
  }

  // ---------- LICENCIA ----------
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

  Future<void> eliminarLicencia(String usuario) async {
    final db = await database;
    await db.delete('licencias', where: 'usuario = ?', whereArgs: [usuario]);
  }

  // ---------- TELÉFONO DEL PERFIL ----------
  Future<void> guardarTelefono(String usuario, String telefono) async {
    final db = await database;
    await db.insert(
      'perfil',
      {'usuario': usuario, 'telefono': telefono},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> obtenerTelefono(String usuario) async {
    final db = await database;
    final maps = await db.query(
      'perfil',
      where: 'usuario = ?',
      whereArgs: [usuario],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['telefono'] as String;
  }
}