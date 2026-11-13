import 'dart:math' as math;

/// Lo que la IA reconoce en la foto de un vehículo
class SugerenciaVehiculo {
  final String marca;
  final String modelo;
  final String tipo; // carro, moto, camioneta o '' si no se supo
  final bool legible;

  SugerenciaVehiculo({
    required this.marca,
    required this.modelo,
    required this.tipo,
    required this.legible,
  });

  factory SugerenciaVehiculo.fromJson(Map<String, dynamic> json) {
    String limpiar(dynamic v) {
      final t = (v ?? '').toString().trim();
      return t.length > 30 ? t.substring(0, 30) : t;
    }

    const validos = ['carro', 'moto', 'camioneta'];
    final tipoCrudo = (json['tipo'] ?? '').toString().toLowerCase().trim();

    return SugerenciaVehiculo(
      marca: limpiar(json['marca']),
      modelo: limpiar(json['modelo']),
      tipo: validos.contains(tipoCrudo) ? tipoCrudo : '',
      legible: json['legible'] == true,
    );
  }
}

/// Precio de alquiler por día que propone la IA (siempre es una estimación)
class SugerenciaPrecio {
  final double minimo;
  final double maximo;
  final double sugerido;
  final String explicacion;

  SugerenciaPrecio({
    required this.minimo,
    required this.maximo,
    required this.sugerido,
    required this.explicacion,
  });

  factory SugerenciaPrecio.fromJson(Map<String, dynamic> json) {
    double? leer(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), ''));
      return null;
    }

    final sug = leer(json['precio_sugerido']);
    if (sug == null || sug <= 0) {
      throw const FormatException('La IA no devolvió un precio sugerido');
    }

    // Se redondea a $5.000 y se limita al rango que maneja la app
    double ajustar(double v) {
      final r = (v / 5000).round() * 5000.0;
      return r.clamp(30000.0, 500000.0).toDouble();
    }

    final s = ajustar(sug);
    final lo = math.min(ajustar(leer(json['precio_min']) ?? sug), s);
    final hi = math.max(ajustar(leer(json['precio_max']) ?? sug), s);

    return SugerenciaPrecio(
      minimo: lo,
      maximo: hi,
      sugerido: s,
      explicacion: (json['explicacion'] ?? '').toString().trim(),
    );
  }
}