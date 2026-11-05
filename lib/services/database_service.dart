import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehiculo.dart';
import '../models/reserva.dart';
import '../models/resultado_licencia.dart';
import '../repositories/data_repository.dart';

class DatabaseService implements DataRepository {
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
      onCreate: (db, version) async {
        await _crearTablaVehiculos(db);
        await _crearTablaReservas(db);
        await _crearTablaLicencias(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _crearTablaReservas(db);
        }
        if (oldVersion < 3) {
          await db.execute(
              "ALTER TABLE vehiculos ADD COLUMN dueno TEXT NOT NULL DEFAULT ''");
          if (oldVersion >= 2) {
            await db.execute(
                "ALTER TABLE reservas ADD COLUMN dueno TEXT NOT NULL DEFAULT ''");
          }
        }
        if (oldVersion >= 2 && oldVersion < 4) {
          await db.execute('ALTER TABLE reservas ADD COLUMN calificacion INTEGER');
          await db.execute('ALTER TABLE reservas ADD COLUMN comentario TEXT');
        }
        if (oldVersion < 5) {
          await _crearTablaLicencias(db);
        }
      },
    );
  }

  Future<void> _crearTablaVehiculos(Database db) async {
    await db.execute('''
      CREATE TABLE vehiculos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        marca TEXT NOT NULL,
        modelo TEXT NOT NULL,
        anio INTEGER NOT NULL,
        precioPorDia REAL NOT NULL,
        tipo TEXT NOT NULL,
        ubicacion TEXT NOT NULL,
        fotoPath TEXT,
        disponible INTEGER NOT NULL,
        dueno TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _crearTablaReservas(Database db) async {
    await db.execute('''
      CREATE TABLE reservas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehiculoId INTEGER NOT NULL,
        vehiculoNombre TEXT NOT NULL,
        cliente TEXT NOT NULL,
        dueno TEXT NOT NULL DEFAULT '',
        fechaInicio TEXT NOT NULL,
        fechaFin TEXT NOT NULL,
        total REAL NOT NULL,
        estado TEXT NOT NULL,
        calificacion INTEGER,
        comentario TEXT
      )
    ''');
  }

  Future<void> _crearTablaLicencias(Database db) async {
    await db.execute('''
      CREATE TABLE licencias(
        usuario TEXT PRIMARY KEY,
        datos TEXT NOT NULL,
        fechaValidacion TEXT NOT NULL
      )
    ''');
  }

  // Los modelos usan ids de texto; la tabla local usa enteros
  int _aInt(String id) => int.tryParse(id) ?? -1;

  // ---------- VEHÍCULOS ----------
  @override
  Future<List<Vehiculo>> obtenerVehiculos() async {
    final db = await database;
    final maps = await db.query('vehiculos');
    return maps.map((m) => Vehiculo.fromMap(m)).toList();
  }

  @override
  Future<void> insertarVehiculo(Vehiculo vehiculo) async {
    final db = await database;
    await db.insert('vehiculos', vehiculo.toMap());
  }

  @override
  Future<void> actualizarVehiculo(Vehiculo vehiculo) async {
    final db = await database;
    final datos = vehiculo.toMap()..remove('id');
    await db.update('vehiculos', datos,
        where: 'id = ?', whereArgs: [_aInt(vehiculo.id ?? '')]);
  }

  @override
  Future<void> eliminarVehiculo(String id) async {
    final db = await database;
    await db.delete('vehiculos', where: 'id = ?', whereArgs: [_aInt(id)]);
  }

  // ---------- RESERVAS ----------
  @override
  Future<List<Reserva>> obtenerReservas() async {
    final db = await database;
    final maps = await db.query('reservas', orderBy: 'id DESC');
    return maps.map((m) => Reserva.fromMap(m)).toList();
  }

  @override
  Future<bool> crearReservaSiDisponible(Reserva reserva) async {
    final db = await database;

    // La transacción garantiza que la verificación y la inserción
    // ocurren juntas, sin que nada se cuele en medio
    return await db.transaction<bool>((txn) async {
      final resultado = await txn.rawQuery('''
        SELECT COUNT(*) FROM reservas
        WHERE vehiculoId = ?
          AND estado IN ('solicitada', 'aceptada', 'en_curso')
          AND fechaInicio <= ?
          AND fechaFin >= ?
      ''', [
        _aInt(reserva.vehiculoId),
        Reserva.fechaATexto(reserva.fechaFin),
        Reserva.fechaATexto(reserva.fechaInicio),
      ]);

      if ((Sqflite.firstIntValue(resultado) ?? 0) > 0) return false;

      final datos = reserva.toMap()
        ..remove('id')
        ..['vehiculoId'] = _aInt(reserva.vehiculoId);
      await txn.insert('reservas', datos);
      return true;
    });
  }

  @override
  Future<void> actualizarEstadoReserva(String id, String estado) async {
    final db = await database;
    await db.update('reservas', {'estado': estado},
        where: 'id = ?', whereArgs: [_aInt(id)]);
  }

  @override
  Future<void> calificarReserva(
      String id, int estrellas, String comentario) async {
    final db = await database;
    await db.update(
      'reservas',
      {'calificacion': estrellas, 'comentario': comentario},
      where: 'id = ?',
      whereArgs: [_aInt(id)],
    );
  }

  // ---------- LICENCIAS (se quedan siempre en el celular) ----------
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