import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehiculo.dart';
import '../providers/licencia_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../widgets/foto_vehiculo.dart';
import 'validar_licencia_screen.dart';
import '../widgets/documentos_vehiculo.dart';

class DetalleVehiculoScreen extends StatelessWidget {
  final Vehiculo vehiculo;

  const DetalleVehiculoScreen({super.key, required this.vehiculo});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final uid = context.read<VehiculoProvider>().uid;
    final esMio = vehiculo.duenoId.isNotEmpty && vehiculo.duenoId == uid;

    return Scaffold(
      appBar: AppBar(title: Text('${vehiculo.marca} ${vehiculo.modelo}')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FotoVehiculo(vehiculo: vehiculo, height: 220, iconSize: 90),
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
                      Text(vehiculo.ubicacion,
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 10),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(vehiculo.tipo),
                      ),
                    ],
                  ),
                  if (vehiculo.dueno.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('Publicado por ${vehiculo.dueno}',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '\$${vehiculo.precioPorDia.toStringAsFixed(0)} / día',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: primary),
                  ),
                                    const SizedBox(height: 14),
                  DocumentosVehiculo(vehiculo: vehiculo),
                  const Divider(height: 36),
                  const Text('Requisitos',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Licencia de conducción vigente')),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (esMio)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Este vehículo es tuyo, no puedes reservarlo.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<LicenciaProvider>().reiniciar();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ValidarLicenciaScreen(vehiculo: vehiculo),
                            ),
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