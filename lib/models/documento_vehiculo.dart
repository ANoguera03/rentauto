import '../utils/fechas.dart';

class DocumentoVehiculo {
  final bool legible;
  final String tipo; // soat, tecnomecanica u otro
  final String placa; // normalizada: mayúsculas, sin espacios ni guiones
  final String fechaVencimiento; // como la leyó la IA

  DocumentoVehiculo({
    required this.legible,
    required this.tipo,
    required this.placa,
    required this.fechaVencimiento,
  });

  factory DocumentoVehiculo.fromJson(Map<String, dynamic> json) {
    final crudo = (json['tipo'] ?? '').toString().toLowerCase();
    var tipo = 'otro';
    if (crudo.contains('soat')) {
      tipo = 'soat';
    } else if (crudo.contains('tecno') || crudo.contains('revisi')) {
      tipo = 'tecnomecanica';
    }

    return DocumentoVehiculo(
      legible: json['legible'] == true,
      tipo: tipo,
      placa: (json['placa'] ?? '')
          .toString()
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), ''),
      fechaVencimiento: (json['fecha_vencimiento'] ?? '').toString(),
    );
  }

  DateTime? get fechaDate => parsearFecha(fechaVencimiento);

  String? get vencimientoIso =>
      fechaDate == null ? null : fechaAIso(fechaDate!);

  /// Devuelve el motivo por el que el documento no sirve, o null si está bien.
  /// [esperado] es 'soat' o 'tecnomecanica'; [etiqueta] se muestra al usuario.
  String? problema(String esperado, String etiqueta) {
    if (!legible) {
      return 'No pudimos leer el documento. Intenta con una foto más clara y bien iluminada.';
    }
    if (tipo != esperado) {
      return 'Esta imagen no parece ser un documento de tipo $etiqueta.';
    }
    final fecha = fechaDate;
    if (fecha == null) {
      return 'No pudimos leer la fecha de vigencia. Intenta con otra foto.';
    }
    if (!fechaVigente(fecha)) {
      return 'Documento vencido el ${fechaCorta(fecha)}.';
    }
    return null;
  }
}