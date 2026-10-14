import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import 'dart:io';

class DetalleVehiculoScreen extends StatelessWidget {
  final Vehiculo vehiculo;

  const DetalleVehiculoScreen({super.key, required this.vehiculo});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text('${vehiculo.marca} ${vehiculo.modelo}')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Foto" grande (placeholder, luego la cambiamos por la real)
            vehiculo.fotoPath != null
    ? Image.file(
        File(vehiculo.fotoPath!),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      )
    : Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.15), primary.withOpacity(0.05)],
          ),
        ),
        child: Icon(Icons.directions_car, size: 90, color: primary),
      ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.anio})',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(vehiculo.ubicacion, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(vehiculo.tipo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${vehiculo.precioPorDia.toStringAsFixed(0)} / día',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primary),
                  ),
                  const Divider(height: 36),
                  const Text('Requisitos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.badge_outlined, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Licencia de conducción vigente')),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Aquí seguirá la validación de licencia con IA')),
                        );
                      },
                      icon: const Icon(Icons.key),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('Solicitar reserva'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}