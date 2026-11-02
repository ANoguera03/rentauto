import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../models/vehiculo.dart';
import '../services/database_service.dart';

class ReservaProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Reserva> _reservas = [];
  bool cargando = false;

  List<Reserva> get reservas => _reservas;

  Future<void> cargarReservas() async {
    cargando = true;
    notifyListeners();
    try {
      _reservas = await _db.obtenerReservas();
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

    try {
      if (await _db.hayCruce(vehiculo.id!, ini, f)) {
        return 'Ese vehículo ya está reservado en alguna de esas fechas. Elige otro rango.';
      }

      final dias = f.difference(ini).inDays + 1;
      final reserva = Reserva(
        vehiculoId: vehiculo.id!,
        vehiculoNombre: '${vehiculo.marca} ${vehiculo.modelo}',
        cliente: cliente,
        fechaInicio: ini,
        fechaFin: f,
        total: dias * vehiculo.precioPorDia,
      );

      await _db.insertarReserva(reserva);
      await cargarReservas();
      return null;
    } catch (e) {
      debugPrint('Error creando reserva: $e');
      return 'No se pudo crear la reserva. Intenta de nuevo.';
    }
  }

  Future<void> cambiarEstado(int id, String nuevoEstado) async {
    await _db.actualizarEstadoReserva(id, nuevoEstado);
    await cargarReservas();
  }
}