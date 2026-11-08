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

  List<Vehiculo> get misVehiculos =>
      _vehiculos.where((v) => v.duenoId == uid).toList();

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

  // Devuelve null si salió bien, o el mensaje de error
  Future<String?> eliminarVehiculo(String id) async {
    try {
      await _repo.eliminarVehiculo(id);
      await cargarVehiculos();
      return null;
    } catch (e) {
      debugPrint('Error eliminando vehículo: $e');
      return 'No se pudo eliminar el vehículo. Intenta de nuevo.';
    }
  }
}