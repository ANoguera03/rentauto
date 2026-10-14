import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehiculo_provider.dart';
import 'publicar_vehiculo_screen.dart';
import 'detalle_vehiculo_screen.dart';
import 'dart:io';
class BuscarVehiculosScreen extends StatefulWidget {
  const BuscarVehiculosScreen({super.key});

  @override
  State<BuscarVehiculosScreen> createState() => _BuscarVehiculosScreenState();
}

class _BuscarVehiculosScreenState extends State<BuscarVehiculosScreen> {
  @override
  void initState() {
    super.initState();
    // Apenas se abre la pantalla, pide al provider que cargue los vehículos
    Future.microtask(() =>
        context.read<VehiculoProvider>().cargarVehiculos());
  }

  @override
Widget build(BuildContext context) {
  final provider = context.watch<VehiculoProvider>();

  return Scaffold(
    appBar: AppBar(
      title: const Text('Vehículos disponibles'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    ),
    body: provider.cargando
        ? const Center(child: CircularProgressIndicator())
        : provider.vehiculos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[350]),
                    const SizedBox(height: 12),
                    Text(
                      'Aún no hay vehículos publicados',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.vehiculos.length,
                itemBuilder: (context, index) {
                  final v = provider.vehiculos[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: v.fotoPath != null
                              ? Image.file(
                                  File(v.fotoPath!),
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Icon(Icons.directions_car,
                                      size: 48, color: Theme.of(context).colorScheme.primary),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${v.marca} ${v.modelo}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(v.ubicacion, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(v.tipo,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${v.precioPorDia.toStringAsFixed(0)} / día',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary),
                                  ),
                                  TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleVehiculoScreen(vehiculo: v)),
    );
  },
  child: const Text('Ver más'),
),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    floatingActionButton: provider.rolActual == 'dueño'
    ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PublicarVehiculoScreen()),
          );
          if (mounted) context.read<VehiculoProvider>().cargarVehiculos();
        },
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      )
    : null,
  );
}
}