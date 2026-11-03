import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehiculo.dart';
import '../models/reserva.dart';

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
      version: 4,
      onCreate: (db, version) async {
        await _crearTablaVehiculos(db);
        await _crearTablaReservas(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // la tabla nueva ya trae 'dueno', 'calificacion' y 'comentario'
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

  // ---------- VEHÍCULOS ----------
  Future<int> insertarVehiculo(Vehiculo vehiculo) async {
    final db = await database;
    return await db.insert('vehiculos', vehiculo.toMap());
  }

  Future<List<Vehiculo>> obtenerVehiculos() async {
    final db = await database;
    final maps = await db.query('vehiculos');
    return maps.map((m) => Vehiculo.fromMap(m)).toList();
  }

  Future<int> actualizarVehiculo(Vehiculo vehiculo) async {
    final db = await database;
    return await db.update('vehiculos', vehiculo.toMap(),
        where: 'id = ?', whereArgs: [vehiculo.id]);
  }

  Future<int> eliminarVehiculo(int id) async {
    final db = await database;
    return await db.delete('vehiculos', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- RESERVAS ----------
  Future<int> insertarReserva(Reserva reserva) async {
    final db = await database;
    return await db.insert('reservas', reserva.toMap());
  }

  Future<List<Reserva>> obtenerReservas() async {
    final db = await database;
    final maps = await db.query('reservas', orderBy: 'id DESC');
    return maps.map((m) => Reserva.fromMap(m)).toList();
  }

  Future<int> actualizarEstadoReserva(int id, String estado) async {
    final db = await database;
    return await db.update('reservas', {'estado': estado},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> calificarReserva(int id, int estrellas, String comentario) async {
    final db = await database;
    return await db.update(
      'reservas',
      {'calificacion': estrellas, 'comentario': comentario},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hayCruce(int vehiculoId, DateTime inicio, DateTime fin) async {
    final db = await database;
    final resultado = await db.rawQuery('''
      SELECT COUNT(*) FROM reservas
      WHERE vehiculoId = ?
        AND estado IN ('solicitada', 'aceptada', 'en_curso')
        AND fechaInicio <= ?
        AND fechaFin >= ?
    ''', [vehiculoId, Reserva.fechaATexto(fin), Reserva.fechaATexto(inicio)]);
    return (Sqflite.firstIntValue(resultado) ?? 0) > 0;
  }
}