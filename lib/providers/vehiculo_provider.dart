import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../services/database_service.dart';




class VehiculoProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Vehiculo> _vehiculos = [];
  bool cargando = false;
  String rolActual = 'cliente'; // 'cliente' o 'dueño'


  List<Vehiculo> get vehiculos => _vehiculos;

 Future<void> cargarVehiculos() async {
  cargando = true;
  notifyListeners();

  try {
    _vehiculos = await _db.obtenerVehiculos();
  } catch (e) {
    debugPrint('Error cargando vehículos: $e'); // esto se ve en la terminal
  }

  cargando = false;
  notifyListeners();
}

  Future<void> agregarVehiculo(Vehiculo vehiculo) async {
    await _db.insertarVehiculo(vehiculo);
    await cargarVehiculos(); // recarga la lista para que se vea el nuevo
  }
}