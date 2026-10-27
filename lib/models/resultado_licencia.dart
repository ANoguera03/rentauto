class ResultadoLicencia {
  final String nombre;
  final String categoria;
  final String fechaVencimiento; // formato dd/mm/aaaa
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

  // La vigencia la calcula TU código, no la IA
  bool get vigente {
    try {
      final partes = fechaVencimiento.split('/');
      final fecha = DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );
      return fecha.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}