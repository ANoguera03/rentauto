import 'dart:convert';
import 'dart:typed_data';

class Vehiculo {
  final String? id;
  final String marca;
  final String modelo;
  final int anio;
  final double precioPorDia;
  final String tipo; // "carro", "moto", "camioneta"
  final String ubicacion;
  final String? fotoPath; // ruta local (solo para la copia en SQLite)
  final bool disponible;
  final String dueno; // nombre del dueño, para mostrar
  final String duenoId; // uid de la cuenta del dueño
  final String? fotoBase64; // foto comprimida guardada en Firestore

  Vehiculo({
    this.id,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.precioPorDia,
    required this.tipo,
    required this.ubicacion,
    this.fotoPath,
    this.disponible = true,
    this.dueno = '',
    this.duenoId = '',
    this.fotoBase64,
  });

  // La foto se decodifica una sola vez por vehículo
  late final Uint8List? fotoBytes = _decodificar(fotoBase64);

  static Uint8List? _decodificar(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  // ---------- SQLite ----------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'precioPorDia': precioPorDia,
      'tipo': tipo,
      'ubicacion': ubicacion,
      'fotoPath': fotoPath,
      'disponible': disponible ? 1 : 0,
      'dueno': dueno,
    };
  }

  factory Vehiculo.fromMap(Map<String, dynamic> map) {
    return Vehiculo(
      id: map['id']?.toString(),
      marca: map['marca'],
      modelo: map['modelo'],
      anio: map['anio'],
      precioPorDia: (map['precioPorDia'] as num).toDouble(),
      tipo: map['tipo'],
      ubicacion: map['ubicacion'],
      fotoPath: map['fotoPath'],
      disponible: map['disponible'] == 1,
      dueno: map['dueno'] ?? '',
    );
  }

  // ---------- Firestore ----------
  Map<String, dynamic> toFirestore() {
    return {
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'precioPorDia': precioPorDia,
      'tipo': tipo,
      'ubicacion': ubicacion,
      'disponible': disponible,
      'dueno': dueno,
      'duenoId': duenoId,
      'fotoBase64': fotoBase64,
    };
  }

  factory Vehiculo.fromFirestore(String id, Map<String, dynamic> d) {
    return Vehiculo(
      id: id,
      marca: d['marca'] ?? '',
      modelo: d['modelo'] ?? '',
      anio: (d['anio'] as num?)?.toInt() ?? 0,
      precioPorDia: (d['precioPorDia'] as num?)?.toDouble() ?? 0,
      tipo: d['tipo'] ?? 'carro',
      ubicacion: d['ubicacion'] ?? '',
      disponible: d['disponible'] ?? true,
      dueno: d['dueno'] ?? '',
      duenoId: d['duenoId'] ?? '',
      fotoBase64: d['fotoBase64'],
    );
  }
}