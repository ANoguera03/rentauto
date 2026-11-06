import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehiculo.dart';
import '../providers/vehiculo_provider.dart';
import '../widgets/foto_vehiculo.dart';
import 'auth_gate.dart';
import 'detalle_vehiculo_screen.dart';
import 'mis_reservas_screen.dart';
import 'perfil_screen.dart';
import 'publicar_vehiculo_screen.dart';

class BuscarVehiculosScreen extends StatefulWidget {
  const BuscarVehiculosScreen({super.key});

  @override
  State<BuscarVehiculosScreen> createState() => _BuscarVehiculosScreenState();
}

class _BuscarVehiculosScreenState extends State<BuscarVehiculosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<VehiculoProvider>().cargarVehiculos());
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
        actions: [
          IconButton(
            tooltip: 'Mis reservas',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MisReservasScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Cambiar de perfil',
            icon: const Icon(Icons.switch_account_outlined),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthGate()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: provider.cargando && provider.vehiculos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<VehiculoProvider>().cargarVehiculos(),
              child: provider.vehiculos.isEmpty
                  ? _vacio()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.vehiculos.length,
                      itemBuilder: (context, index) =>
                          _tarjeta(context, provider.vehiculos[index]),
                    ),
            ),
      floatingActionButton: provider.rolActual == 'dueño'
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PublicarVehiculoScreen()),
                );
                if (mounted) context.read<VehiculoProvider>().cargarVehiculos();
              },
              icon: const Icon(Icons.add),
              label: const Text('Publicar'),
            )
          : null,
    );
  }

  Widget _vacio() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Center(
          child: Icon(Icons.directions_car_outlined,
              size: 64, color: Colors.grey[350]),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Aún no hay vehículos publicados',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Desliza hacia abajo para actualizar',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _tarjeta(BuildContext context, Vehiculo v) {
    final primary = Theme.of(context).colorScheme.primary;

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
            child: FotoVehiculo(vehiculo: v, height: 120),
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
                    Text(v.ubicacion,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        v.tipo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
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
                        color: primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetalleVehiculoScreen(vehiculo: v),
                          ),
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
  }
}