import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehiculo.dart';

class DatabaseService {
  // Patrón Singleton: una sola instancia de la base de datos en toda la app
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
      version: 1,
      onCreate: (db, version) async {
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
            disponible INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // CREATE: insertar un vehículo nuevo
  Future<int> insertarVehiculo(Vehiculo vehiculo) async {
    final db = await database;
    return await db.insert('vehiculos', vehiculo.toMap());
  }

  // READ: obtener todos los vehículos
  Future<List<Vehiculo>> obtenerVehiculos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vehiculos');
    return maps.map((map) => Vehiculo.fromMap(map)).toList();
  }

  // UPDATE: actualizar un vehículo (ej. marcarlo no disponible)
  Future<int> actualizarVehiculo(Vehiculo vehiculo) async {
    final db = await database;
    return await db.update(
      'vehiculos',
      vehiculo.toMap(),
      where: 'id = ?',
      whereArgs: [vehiculo.id],
    );
  }

  // DELETE: eliminar un vehículo
  Future<int> eliminarVehiculo(int id) async {
    final db = await database;
    return await db.delete(
      'vehiculos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}