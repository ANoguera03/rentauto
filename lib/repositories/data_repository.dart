import '../models/vehiculo.dart';
import '../models/reserva.dart';

/// Contrato de acceso a los datos compartidos (vehículos y reservas).
/// Hoy lo implementa SQLite; luego lo implementará Firestore.
abstract class DataRepository {
  Future<List<Vehiculo>> obtenerVehiculos();
  Future<void> insertarVehiculo(Vehiculo vehiculo);
  Future<void> actualizarVehiculo(Vehiculo vehiculo);
  Future<void> eliminarVehiculo(String id);

  Future<List<Reserva>> obtenerReservas();

  /// Crea la reserva solo si no se cruza con otra del mismo vehículo.
  /// La comprobación y la inserción ocurren juntas (de forma atómica).
  /// Devuelve false si hay cruce de fechas.
  Future<bool> crearReservaSiDisponible(Reserva reserva);

  Future<void> actualizarEstadoReserva(String id, String estado);
  Future<void> calificarReserva(String id, int estrellas, String comentario);
}