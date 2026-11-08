/// Filtros de búsqueda que la IA propone a partir de una frase.
/// La IA sugiere; este modelo valida y corrige todo antes de usarlo.
class FiltrosBusqueda {
  static const List<String> tiposValidos = ['todos', 'carro', 'moto', 'camioneta'];
  static const double precioMinimo = 30000;
  static const double precioTope = 500000; // en el tope = "sin límite"

  final String tipo;
  final double? precioMax; // null = sin límite
  final String texto;
  final String explicacion;

  FiltrosBusqueda({
    required this.tipo,
    required this.precioMax,
    required this.texto,
    required this.explicacion,
  });

  factory FiltrosBusqueda.fromJson(Map<String, dynamic> json) {
    // Tipo: solo se acepta uno de los valores conocidos
    final tipoCrudo = (json['tipo'] ?? 'todos').toString().toLowerCase().trim();
    final tipo = tiposValidos.contains(tipoCrudo) ? tipoCrudo : 'todos';

    // Precio: se acepta número o texto, y se ajusta al rango del deslizador
    double? precio;
    final crudo = json['precio_max'];
    if (crudo is num) {
      precio = crudo.toDouble();
    } else if (crudo is String) {
      precio = double.tryParse(crudo.replaceAll(RegExp(r'[^0-9.]'), ''));
    }

    if (precio != null) {
      if (precio >= precioTope) {
        precio = null;
      } else {
        final redondeado = (precio / 10000).round() * 10000.0;
        precio = redondeado.clamp(precioMinimo, precioTope).toDouble();
      }
    }

    var texto = (json['texto'] ?? '').toString().trim();
    if (texto.length > 40) texto = texto.substring(0, 40);

    return FiltrosBusqueda(
      tipo: tipo,
      precioMax: precio,
      texto: texto,
      explicacion: (json['explicacion'] ?? '').toString().trim(),
    );
  }
}