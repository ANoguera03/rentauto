import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../models/vehiculo.dart';
import '../repositories/data_repository.dart';

class ReservaProvider extends ChangeNotifier {
  final DataRepository _repo;
  ReservaProvider(this._repo);

  static const int maxDias = 14;

  String usuarioId = '';
  List<Reserva> _reservas = [];
  bool cargando = false;

  List<Reserva> get reservas => _reservas;

  // Se llama al entrar con una cuenta: limpia lo del usuario anterior
  void cambiarUsuario(String uid) {
    usuarioId = uid;
    _reservas = [];
    notifyListeners();
  }

  Future<void> cargarReservas() async {
    if (usuarioId.isEmpty) return;

    cargando = true;
    notifyListeners();
    try {
      _reservas = await _repo.obtenerReservas(usuarioId);
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

    if (dias > maxDias) {
      return 'Una reserva no puede superar $maxDias días.';
    }

    final reserva = Reserva(
      vehiculoId: vehiculo.id!,
      vehiculoNombre: '${vehiculo.marca} ${vehiculo.modelo}',
      cliente: cliente,
      clienteId: usuarioId,
      dueno: vehiculo.dueno,
      duenoId: vehiculo.duenoId,
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
      return 'No se pudo crear la reserva. Revisa tu conexión e intenta de nuevo.';
    }
  }

  Future<void> cambiarEstado(String id, String nuevoEstado) async {
    try {
      await _repo.actualizarEstadoReserva(id, nuevoEstado);
    } catch (e) {
      debugPrint('Error cambiando estado: $e');
    }
    await cargarReservas();
  }

  Future<void> calificar(String id, int estrellas, String comentario) async {
    try {
      await _repo.calificarReserva(id, estrellas, comentario.trim());
    } catch (e) {
      debugPrint('Error calificando: $e');
    }
    await cargarReservas();
  }

  // Calificaciones que ha recibido un dueño (por id de cuenta)
  List<Reserva> calificacionesRecibidas(String duenoId) {
    return _reservas
        .where((r) => r.duenoId == duenoId && r.calificacion != null)
        .toList();
  }

  double? promedioRecibido(String duenoId) {
    final lista = calificacionesRecibidas(duenoId);
    if (lista.isEmpty) return null;
    final suma = lista.map((r) => r.calificacion!).reduce((a, b) => a + b);
    return suma / lista.length;
  }
}