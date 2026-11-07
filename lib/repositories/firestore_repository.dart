import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reserva.dart';
import '../models/vehiculo.dart';
import 'data_repository.dart';

class FirestoreRepository implements DataRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final CollectionReference<Map<String, dynamic>> _vehiculos =
      _db.collection('vehiculos');
  late final CollectionReference<Map<String, dynamic>> _reservas =
      _db.collection('reservas');
  late final CollectionReference<Map<String, dynamic>> _ocupacion =
      _db.collection('ocupacion');

  static const Duration _espera = Duration(seconds: 15);

  // Un documento de Firestore admite máximo 1 MiB
  static const int _maxBytesFoto = 700 * 1024;

  // ---------- VEHÍCULOS ----------
  @override
  Future<List<Vehiculo>> obtenerVehiculos() async {
    final snap =
        await _vehiculos.orderBy('creado', descending: true).get().timeout(_espera);
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

    await _vehiculos.add(datos).timeout(_espera);
  }

  @override
  Future<void> actualizarVehiculo(Vehiculo vehiculo) async {
    await _vehiculos
        .doc(vehiculo.id)
        .update(vehiculo.toFirestore())
        .timeout(_espera);
  }

  @override
  Future<void> eliminarVehiculo(String id) async {
    await _vehiculos.doc(id).delete().timeout(_espera);
  }

  // ---------- RESERVAS ----------
  @override
  Future<List<Reserva>> obtenerReservas(String usuarioId) async {
    // Dos consultas (como cliente y como dueño). Las reglas exigen que cada
    // consulta filtre por el usuario, así que no se pide "todo" y se filtra después.
    final resultados = await Future.wait([
      _reservas.where('clienteId', isEqualTo: usuarioId).get().timeout(_espera),
      _reservas.where('duenoId', isEqualTo: usuarioId).get().timeout(_espera),
    ]);

    final porId = <String, Reserva>{};
    for (final snap in resultados) {
      for (final d in snap.docs) {
        porId[d.id] = Reserva.fromFirestore(d.id, d.data());
      }
    }

    final lista = porId.values.toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    return lista;
  }

  @override
  Future<bool> crearReservaSiDisponible(Reserva reserva) async {
    // Un documento por cada día de la reserva
    final dias = <DateTime>[];
    var dia = reserva.fechaInicio;
    while (!dia.isAfter(reserva.fechaFin)) {
      dias.add(dia);
      dia = DateTime(dia.year, dia.month, dia.day + 1);
    }

    final refsDias = dias
        .map((d) => _ocupacion
            .doc('${reserva.vehiculoId}_${Reserva.fechaATexto(d)}'))
        .toList();
    final refReserva = _reservas.doc();

    // La transacción es atómica: o se reservan todos los días y se crea la
    // reserva, o no se hace nada. Si dos usuarios compiten por el mismo día,
    // solo uno lo consigue.
    return await _db.runTransaction<bool>((tx) async {
      for (final ref in refsDias) {
        final snap = await tx.get(ref);
        if (snap.exists) return false;
      }

      for (final ref in refsDias) {
        tx.set(ref, {
          'vehiculoId': reserva.vehiculoId,
          'reservaId': refReserva.id,
          'clienteId': reserva.clienteId,
        });
      }

      final datos = reserva.toFirestore();
      datos['creado'] = FieldValue.serverTimestamp();
      tx.set(refReserva, datos);
      return true;
    }).timeout(const Duration(seconds: 20));
  }

  @override
  Future<void> actualizarEstadoReserva(String id, String estado) async {
    await _reservas.doc(id).update({'estado': estado}).timeout(_espera);

    // Si la reserva ya no ocupa el vehículo, se liberan sus días
    if (estado == 'rechazada' || estado == 'finalizada') {
      await _liberarDias(id);
    }
  }

  Future<void> _liberarDias(String reservaId) async {
    try {
      final snap = await _ocupacion
          .where('reservaId', isEqualTo: reservaId)
          .get()
          .timeout(_espera);

      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit().timeout(_espera);
    } catch (e) {
      debugPrint('No se pudieron liberar los días de la reserva: $e');
    }
  }

  @override
  Future<void> calificarReserva(
      String id, int estrellas, String comentario) async {
    await _reservas.doc(id).update({
      'calificacion': estrellas,
      'comentario': comentario,
    }).timeout(_espera);
  }
}