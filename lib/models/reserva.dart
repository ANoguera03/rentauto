class Reserva {
  final String? id;
  final String vehiculoId;
  final String vehiculoNombre;
  final String cliente; // nombre, para mostrar
  final String clienteId; // uid de la cuenta
  final String dueno; // nombre, para mostrar
  final String duenoId; // uid de la cuenta
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
    required this.clienteId,
    required this.dueno,
    required this.duenoId,
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

  Map<String, dynamic> toFirestore() {
    return {
      'vehiculoId': vehiculoId,
      'vehiculoNombre': vehiculoNombre,
      'cliente': cliente,
      'clienteId': clienteId,
      'dueno': dueno,
      'duenoId': duenoId,
      'fechaInicio': fechaATexto(fechaInicio),
      'fechaFin': fechaATexto(fechaFin),
      'total': total,
      'estado': estado,
      'calificacion': calificacion,
      'comentario': comentario,
    };
  }

  factory Reserva.fromFirestore(String id, Map<String, dynamic> d) {
    return Reserva(
      id: id,
      vehiculoId: d['vehiculoId'] ?? '',
      vehiculoNombre: d['vehiculoNombre'] ?? '',
      cliente: d['cliente'] ?? '',
      clienteId: d['clienteId'] ?? '',
      dueno: d['dueno'] ?? '',
      duenoId: d['duenoId'] ?? '',
      fechaInicio: DateTime.parse(d['fechaInicio']),
      fechaFin: DateTime.parse(d['fechaFin']),
      total: (d['total'] as num?)?.toDouble() ?? 0,
      estado: d['estado'] ?? 'solicitada',
      calificacion: (d['calificacion'] as num?)?.toInt(),
      comentario: d['comentario'],
    );
  }
}