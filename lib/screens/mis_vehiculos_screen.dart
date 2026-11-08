import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehiculo.dart';
import '../providers/vehiculo_provider.dart';
import '../utils/formato.dart';
import '../widgets/boton_cambiar_modo.dart';
import '../widgets/foto_vehiculo.dart';
import 'detalle_vehiculo_screen.dart';
import 'publicar_vehiculo_screen.dart';

class MisVehiculosScreen extends StatefulWidget {
  const MisVehiculosScreen({super.key});

  @override
  State<MisVehiculosScreen> createState() => _MisVehiculosScreenState();
}

class _MisVehiculosScreenState extends State<MisVehiculosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<VehiculoProvider>().cargarVehiculos());
  }

  Future<void> _publicar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PublicarVehiculoScreen()),
    );
    if (mounted) context.read<VehiculoProvider>().cargarVehiculos();
  }

  Future<void> _confirmarEliminar(Vehiculo v) async {
    final provider = context.read<VehiculoProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text('¿Seguro que quieres eliminar ${v.marca} ${v.modelo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final error = await provider.eliminarVehiculo(v.id!);
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Vehículo eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehiculoProvider>();
    final mios = provider.misVehiculos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis vehículos'),
        centerTitle: true,
        actions: const [BotonCambiarModo()],
      ),
      body: provider.cargando && provider.vehiculos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<VehiculoProvider>().cargarVehiculos(),
              child: mios.isEmpty
                  ? _vacio()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: mios.length,
                      itemBuilder: (context, i) => _tarjeta(context, mios[i]),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publicar,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
    );
  }

  Widget _vacio() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Icon(Icons.directions_car_outlined,
              size: 64, color: Colors.grey[350]),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('Aún no has publicado vehículos',
              style: TextStyle(color: Colors.grey[600])),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: _publicar,
            icon: const Icon(Icons.add),
            label: const Text('Publicar mi primer vehículo'),
          ),
        ),
      ],
    );
  }

  Widget _tarjeta(BuildContext context, Vehiculo v) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalleVehiculoScreen(vehiculo: v)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
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
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FotoVehiculo(vehiculo: v, height: 92, iconSize: 32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${v.marca} ${v.modelo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('${v.tipo} · ${v.anio} · ${v.ubicacion}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(
                    '${formatoPrecio(v.precioPorDia)} / día',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () => _confirmarEliminar(v),
            ),
          ],
        ),
      ),
    );
  }
}