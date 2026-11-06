import 'dart:io';
import 'package:flutter/material.dart';
import '../models/vehiculo.dart';

/// Muestra la foto del vehículo (desde la nube o local) o un marcador de posición
class FotoVehiculo extends StatelessWidget {
  final Vehiculo vehiculo;
  final double height;
  final double iconSize;

  const FotoVehiculo({
    super.key,
    required this.vehiculo,
    required this.height,
    this.iconSize = 48,
  });

  Widget _marcador(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.15), primary.withOpacity(0.05)],
        ),
      ),
      child: Icon(Icons.directions_car, size: iconSize, color: primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = vehiculo.fotoBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _marcador(context),
      );
    }

    final ruta = vehiculo.fotoPath;
    if (ruta != null && File(ruta).existsSync()) {
      return Image.file(
        File(ruta),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _marcador(context),
      );
    }

    return _marcador(context);
  }
}