class ResultadoLicencia {
  final String nombre;
  final String categoria;
  final String fechaVencimiento;
  final bool legible;

  ResultadoLicencia({
    required this.nombre,
    required this.categoria,
    required this.fechaVencimiento,
    required this.legible,
  });

  factory ResultadoLicencia.fromJson(Map<String, dynamic> json) {
    return ResultadoLicencia(
      nombre: json['nombre'] ?? '',
      categoria: json['categoria'] ?? '',
      fechaVencimiento: json['fecha_vencimiento'] ?? '',
      legible: json['legible'] ?? false,
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
    if (mes < 1 || mes > 12 || dia < 1 || dia > 31) return null;

    return DateTime(anio, mes, dia);
  }

  bool get fechaInterpretable => fechaVencimientoDate != null;

  // La vigencia la decide el código, no la IA
  bool get vigente {
    final fecha = fechaVencimientoDate;
    if (fecha == null) return false;

    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    return !fecha.isBefore(hoySinHora); // el último día de vigencia aún cuenta
  }
}