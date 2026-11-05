import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../models/vehiculo.dart';
import '../repositories/data_repository.dart';

class ReservaProvider extends ChangeNotifier {
  final DataRepository _repo;
  ReservaProvider(this._repo);

  List<Reserva> _reservas = [];
  bool cargando = false;

  List<Reserva> get reservas => _reservas;

  Future<void> cargarReservas() async {
    cargando = true;
    notifyListeners();
    try {
      _reservas = await _repo.obtenerReservas();
    } catch (e) {
      debugPrint('Error cargando reservas: $e');
    }
    cargando = false;
    notifyListeners();
  }

  // Devuelve null si todo salió bien, o el mensaje de error para mostrarlo
  Future<String?> crearReserva({
    required Vehiculo vehiculo,
    required String cliente,
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final ini = DateTime(inicio.year, inicio.month, inicio.day);
    final f = DateTime(fin.year, fin.month, fin.day);
    final dias = f.difference(ini).inDays + 1;

    final reserva = Reserva(
      vehiculoId: vehiculo.id!,
      vehiculoNombre: '${vehiculo.marca} ${vehiculo.modelo}',
      cliente: cliente,
      dueno: vehiculo.dueno,
      fechaInicio: ini,
      fechaFin: f,
      total: dias * vehiculo.precioPorDia,
    );

    try {
      final creada = await _repo.crearReservaSiDisponible(reserva);
      if (!creada) {
        return 'Ese vehículo ya está reservado en alguna de esas fechas. Elige otro rango.';
      }
      await cargarReservas();
      return null;
    } catch (e) {
      debugPrint('Error creando reserva: $e');
      return 'No se pudo crear la reserva. Intenta de nuevo.';
    }
  }

  Future<void> cambiarEstado(String id, String nuevoEstado) async {
    await _repo.actualizarEstadoReserva(id, nuevoEstado);
    await cargarReservas();
  }

  Future<void> calificar(String id, int estrellas, String comentario) async {
    await _repo.calificarReserva(id, estrellas, comentario.trim());
    await cargarReservas();
  }

  // Calificaciones que ha recibido un dueño
  List<Reserva> calificacionesRecibidas(String dueno) {
    return _reservas
        .where((r) => r.dueno == dueno && r.calificacion != null)
        .toList();
  }

  double? promedioRecibido(String dueno) {
    final lista = calificacionesRecibidas(dueno);
    if (lista.isEmpty) return null;
    final suma = lista.map((r) => r.calificacion!).reduce((a, b) => a + b);
    return suma / lista.length;
  }
}