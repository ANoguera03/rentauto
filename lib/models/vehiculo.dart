class Vehiculo {
  final int? id;
  final String marca;
  final String modelo;
  final int anio;
  final double precioPorDia;
  final String tipo; // "carro", "moto", "camioneta"
  final String ubicacion;
  final String? fotoPath; // ruta local de la foto
  final bool disponible;

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
  });

  // Convierte el objeto Vehiculo a un Map (lo que sqflite necesita para guardar)
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
      'disponible': disponible ? 1 : 0, // SQLite no tiene booleanos, usa 0/1
    };
  }

  // Convierte un Map (lo que viene de sqflite) de vuelta a un objeto Vehiculo
  factory Vehiculo.fromMap(Map<String, dynamic> map) {
    return Vehiculo(
      id: map['id'],
      marca: map['marca'],
      modelo: map['modelo'],
      anio: map['anio'],
      precioPorDia: map['precioPorDia'],
      tipo: map['tipo'],
      ubicacion: map['ubicacion'],
      fotoPath: map['fotoPath'],
      disponible: map['disponible'] == 1,
    );
  }
}