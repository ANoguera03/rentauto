import '../models/vehiculo.dart';
import '../models/reserva.dart';

/// Contrato de acceso a los datos compartidos (vehículos y reservas).
abstract class DataRepository {
  Future<List<Vehiculo>> obtenerVehiculos();
  Future<void> insertarVehiculo(Vehiculo vehiculo);
  Future<void> actualizarVehiculo(Vehiculo vehiculo);
  Future<void> eliminarVehiculo(String id);

  /// Reservas en las que participa el usuario, como cliente o como dueño.
  Future<List<Reserva>> obtenerReservas(String usuarioId);

  /// Crea la reserva solo si ninguno de sus días está ocupado.
  /// Devuelve false si hay cruce de fechas.
  Future<bool> crearReservaSiDisponible(Reserva reserva);

  Future<void> actualizarEstadoReserva(String id, String estado);
  Future<void> calificarReserva(String id, int estrellas, String comentario);
}