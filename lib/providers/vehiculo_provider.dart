import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../repositories/data_repository.dart';

class VehiculoProvider extends ChangeNotifier {
  final DataRepository _repo;
  VehiculoProvider(this._repo);

  List<Vehiculo> _vehiculos = [];
  bool cargando = false;
  String rolActual = 'cliente'; // 'cliente' o 'dueño'
  String nombreUsuario = 'Usuario';
  String uid = '';

  List<Vehiculo> get vehiculos => _vehiculos;

  Future<void> cargarVehiculos() async {
    cargando = true;
    notifyListeners();

    try {
      _vehiculos = await _repo.obtenerVehiculos();
    } catch (e) {
      debugPrint('Error cargando vehículos: $e');
    }

    cargando = false;
    notifyListeners();
  }

  Future<void> agregarVehiculo(Vehiculo vehiculo) async {
    await _repo.insertarVehiculo(vehiculo);
    await cargarVehiculos();
  }
}