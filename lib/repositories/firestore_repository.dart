import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reserva.dart';
import '../models/vehiculo.dart';
import 'data_repository.dart';

/// Vehículos en Firestore. Las reservas se delegan temporalmente a SQLite
/// (se migran en la siguiente sesión).
class FirestoreRepository implements DataRepository {
  final DataRepository _local;
  FirestoreRepository(this._local);

  final CollectionReference<Map<String, dynamic>> _vehiculos =
      FirebaseFirestore.instance.collection('vehiculos');

  // Límite de la foto: un documento de Firestore admite máximo 1 MiB
  static const int _maxBytesFoto = 700 * 1024;

  // ---------- VEHÍCULOS (nube) ----------
  @override
  Future<List<Vehiculo>> obtenerVehiculos() async {
    final snap = await _vehiculos
        .orderBy('creado', descending: true)
        .get()
        .timeout(const Duration(seconds: 15));

    return snap.docs
        .map((d) => Vehiculo.fromFirestore(d.id, d.data()))
        .toList();
  }

  @override
  Future<void> insertarVehiculo(Vehiculo vehiculo) async {
    String? foto = vehiculo.fotoBase64;
    final ruta = vehiculo.fotoPath;

    if (foto == null && ruta != null) {
      try {
        final bytes = await File(ruta).readAsBytes();
        if (bytes.length <= _maxBytesFoto) {
          foto = base64Encode(bytes);
        } else {
          debugPrint('Foto demasiado pesada (${bytes.length} bytes), se omite');
        }
      } catch (e) {
        debugPrint('No se pudo leer la foto: $e');
      }
    }

    final datos = vehiculo.toFirestore();
    datos['fotoBase64'] = foto;
    datos['creado'] = FieldValue.serverTimestamp();

    await _vehiculos.add(datos).timeout(const Duration(seconds: 15));
  }

  @override
  Future<void> actualizarVehiculo(Vehiculo vehiculo) async {
    await _vehiculos
        .doc(vehiculo.id)
        .update(vehiculo.toFirestore())
        .timeout(const Duration(seconds: 15));
  }

  @override
  Future<void> eliminarVehiculo(String id) async {
    await _vehiculos.doc(id).delete().timeout(const Duration(seconds: 15));
  }

  // ---------- RESERVAS (por ahora locales) ----------
  @override
  Future<List<Reserva>> obtenerReservas() => _local.obtenerReservas();

  @override
  Future<bool> crearReservaSiDisponible(Reserva reserva) =>
      _local.crearReservaSiDisponible(reserva);

  @override
  Future<void> actualizarEstadoReserva(String id, String estado) =>
      _local.actualizarEstadoReserva(id, estado);

  @override
  Future<void> calificarReserva(String id, int estrellas, String comentario) =>
      _local.calificarReserva(id, estrellas, comentario);
}