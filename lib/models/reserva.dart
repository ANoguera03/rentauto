class Reserva {
  final String? id;
  final String vehiculoId;
  final String vehiculoNombre;
  final String cliente;
  final String dueno;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double total;
  final String estado; // solicitada, aceptada, rechazada, en_curso, finalizada
  final int? calificacion; // 1 a 5, null si aún no se califica
  final String? comentario;

  Reserva({
    this.id,
    required this.vehiculoId,
    required this.vehiculoNombre,
    required this.cliente,
    required this.dueno,
    required this.fechaInicio,
    required this.fechaFin,
    required this.total,
    this.estado = 'solicitada',
    this.calificacion,
    this.comentario,
  });

  static String fechaATexto(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get dias => fechaFin.difference(fechaInicio).inDays + 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehiculoId': vehiculoId,
      'vehiculoNombre': vehiculoNombre,
      'cliente': cliente,
      'dueno': dueno,
      'fechaInicio': fechaATexto(fechaInicio),
      'fechaFin': fechaATexto(fechaFin),
      'total': total,
      'estado': estado,
      'calificacion': calificacion,
      'comentario': comentario,
    };
  }

  factory Reserva.fromMap(Map<String, dynamic> map) {
    return Reserva(
      id: map['id']?.toString(),
      vehiculoId: map['vehiculoId'].toString(),
      vehiculoNombre: map['vehiculoNombre'],
      cliente: map['cliente'],
      dueno: map['dueno'] ?? '',
      fechaInicio: DateTime.parse(map['fechaInicio']),
      fechaFin: DateTime.parse(map['fechaFin']),
      total: (map['total'] as num).toDouble(),
      estado: map['estado'],
      calificacion: map['calificacion'],
      comentario: map['comentario'],
    );
  }
}