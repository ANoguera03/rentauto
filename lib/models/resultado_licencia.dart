class CategoriaLicencia {
  final String codigo; // A1, A2, B1, B2, B3, C1, C2, C3
  final String fechaVencimiento; // dd/mm/aaaa
  final String servicio; // PARTICULAR o PÚBLICO

  CategoriaLicencia({
    required this.codigo,
    required this.fechaVencimiento,
    this.servicio = '',
  });

  factory CategoriaLicencia.fromJson(Map<String, dynamic> json) {
    return CategoriaLicencia(
      codigo: (json['categoria'] ?? '')
          .toString()
          .toUpperCase()
          .replaceAll(RegExp(r'\s+'), ''),
      fechaVencimiento: (json['fecha_vencimiento'] ?? '').toString(),
      servicio: (json['servicio'] ?? '').toString(),
    );
  }

  // Acepta 27/02/2035, 27-02-2035 y 27.02.2035
  DateTime? get fechaVencimientoDate {
    final partes = fechaVencimiento.trim().split(RegExp(r'[\/\-\.\s]+'));
    if (partes.length != 3) return null;

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final anio = int.tryParse(partes[2]);

    if (dia == null || mes == null || anio == null) return null;
    if (mes < 1 || mes > 12 || dia < 1 || dia > 31 || anio < 1900) return null;

    return DateTime(anio, mes, dia);
  }

  bool get fechaInterpretable => fechaVencimientoDate != null;

  bool get vigente {
    final fecha = fechaVencimientoDate;
    if (fecha == null) return false;
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    return !fecha.isBefore(hoySinHora); // el último día de vigencia aún cuenta
  }
}

enum EstadoAutorizacion {
  autorizada,
  categoriaVencida,
  categoriaNoCorresponde,
  fechaNoInterpretable,
}

class EvaluacionLicencia {
  final EstadoAutorizacion estado;
  final String mensaje;

  EvaluacionLicencia({required this.estado, required this.mensaje});

  bool get aprobada => estado == EstadoAutorizacion.autorizada;
}

class ResultadoLicencia {
  final String nombre;
  final List<CategoriaLicencia> categorias;
  final bool legible;

  ResultadoLicencia({
    required this.nombre,
    required this.categorias,
    required this.legible,
  });

  factory ResultadoLicencia.fromJson(Map<String, dynamic> json) {
    final lista = <CategoriaLicencia>[];
    final crudo = json['categorias'];

    if (crudo is List) {
      for (final item in crudo) {
        if (item is Map) {
          lista.add(CategoriaLicencia.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if ((json['categoria'] ?? '').toString().isNotEmpty) {
      // por si la IA responde con el formato antiguo (una sola categoría)
      lista.add(CategoriaLicencia.fromJson(json));
    }

    return ResultadoLicencia(
      nombre: (json['nombre'] ?? '').toString(),
      categorias: lista,
      legible: json['legible'] ?? false,
    );
  }

  // REGLA DE NEGOCIO: qué categorías permiten conducir cada tipo de vehículo
  static const Map<String, List<String>> _requeridas = {
    'moto': ['A1', 'A2'],
    'carro': ['B1', 'B2', 'B3', 'C1', 'C2', 'C3'],
    'camioneta': ['B1', 'B2', 'B3', 'C1', 'C2', 'C3'],
  };

  static String requisitoTexto(String tipo) {
    final lista = _requeridas[tipo];
    if (lista == null || lista.isEmpty) return 'una categoría válida';
    if (lista.length == 1) return lista.first;
    return '${lista.sublist(0, lista.length - 1).join(', ')} o ${lista.last}';
  }

  // La IA solo lee la tabla; esta función es la que decide
  EvaluacionLicencia evaluarPara(String tipoVehiculo) {
    final requeridas = _requeridas[tipoVehiculo] ?? const <String>[];
    final candidatas =
        categorias.where((c) => requeridas.contains(c.codigo)).toList();

    if (candidatas.isEmpty) {
      final tiene = categorias.map((c) => c.codigo).join(', ');
      return EvaluacionLicencia(
        estado: EstadoAutorizacion.categoriaNoCorresponde,
        mensaje: 'Tu licencia tiene categoría $tiene, pero para este vehículo '
            '($tipoVehiculo) se requiere ${requisitoTexto(tipoVehiculo)}.',
      );
    }

    for (final c in candidatas) {
      if (c.vigente) {
        return EvaluacionLicencia(
          estado: EstadoAutorizacion.autorizada,
          mensaje:
              'Autorizado: categoría ${c.codigo} vigente hasta ${c.fechaVencimiento}.',
        );
      }
    }

    if (candidatas.any((c) => c.fechaInterpretable)) {
      final c = candidatas.firstWhere((c) => c.fechaInterpretable);
      return EvaluacionLicencia(
        estado: EstadoAutorizacion.categoriaVencida,
        mensaje:
            'Tu categoría ${c.codigo} está vencida (${c.fechaVencimiento}).',
      );
    }

    return EvaluacionLicencia(
      estado: EstadoAutorizacion.fechaNoInterpretable,
      mensaje:
          'Encontramos la categoría ${candidatas.first.codigo}, pero no pudimos '
          'leer su fecha de vigencia. Intenta con una foto más clara.',
    );
  }
}