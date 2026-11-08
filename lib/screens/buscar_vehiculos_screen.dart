import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehiculo.dart';
import '../providers/vehiculo_provider.dart';
import '../utils/formato.dart';
import '../widgets/boton_cambiar_modo.dart';
import '../widgets/foto_vehiculo.dart';
import 'detalle_vehiculo_screen.dart';

class BuscarVehiculosScreen extends StatefulWidget {
  const BuscarVehiculosScreen({super.key});

  @override
  State<BuscarVehiculosScreen> createState() => _BuscarVehiculosScreenState();
}

class _BuscarVehiculosScreenState extends State<BuscarVehiculosScreen> {
  static const double _precioTope = 500000; // en el tope = "sin límite"
  static const double _precioMinimo = 30000;

  final _busquedaCtrl = TextEditingController();
  String _tipo = 'todos';
  double _precioMax = _precioTope;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<VehiculoProvider>().cargarVehiculos());
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  bool get _hayFiltros =>
      _busquedaCtrl.text.trim().isNotEmpty ||
      _tipo != 'todos' ||
      _precioMax < _precioTope;

  void _limpiarFiltros() {
    setState(() {
      _busquedaCtrl.clear();
      _tipo = 'todos';
      _precioMax = _precioTope;
    });
  }

  List<Vehiculo> _filtrar(List<Vehiculo> todos, String uid) {
    final q = _busquedaCtrl.text.trim().toLowerCase();

    return todos.where((v) {
      if (!v.disponible) return false;
      if (uid.isNotEmpty && v.duenoId == uid) return false; // no mostrar los propios
      if (_tipo != 'todos' && v.tipo != _tipo) return false;
      if (_precioMax < _precioTope && v.precioPorDia > _precioMax) return false;
      if (q.isNotEmpty) {
        final texto =
            '${v.marca} ${v.modelo} ${v.ubicacion} ${v.tipo}'.toLowerCase();
        if (!texto.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehiculoProvider>();
    final resultados = _filtrar(provider.vehiculos, provider.uid);
    final hayPublicados = provider.vehiculos
        .any((v) => v.disponible && v.duenoId != provider.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        centerTitle: true,
        actions: const [BotonCambiarModo()],
      ),
      body: Column(
        children: [
          _cabecera(resultados.length),
          Expanded(
            child: provider.cargando && provider.vehiculos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () =>
                        context.read<VehiculoProvider>().cargarVehiculos(),
                    child: resultados.isEmpty
                        ? _vacio(hayPublicados)
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: resultados.length,
                            itemBuilder: (context, i) =>
                                _tarjeta(context, resultados[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cabecera(int total) {
    const tipos = {
      'todos': 'Todos',
      'carro': 'Carros',
      'moto': 'Motos',
      'camioneta': 'Camionetas',
    };
    final sinLimite = _precioMax >= _precioTope;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _busquedaCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar por marca, modelo o lugar',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busquedaCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _busquedaCtrl.clear()),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tipos.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: _tipo == e.key,
                        onSelected: (_) => setState(() => _tipo = e.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 6),
              SizedBox(
                width: 150,
                child: Text(
                  sinLimite
                      ? 'Precio: sin límite'
                      : 'Hasta ${formatoPrecio(_precioMax)} / día',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[800]),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _precioMax,
                  min: _precioMinimo,
                  max: _precioTope,
                  divisions: 47, // pasos de $10.000
                  onChanged: (v) => setState(() => _precioMax = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                total == 1 ? '1 vehículo' : '$total vehículos',
                style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
              ),
              const Spacer(),
              if (_hayFiltros)
                TextButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Limpiar filtros'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vacio(bool hayPublicados) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Icon(
            hayPublicados ? Icons.search_off : Icons.directions_car_outlined,
            size: 64,
            color: Colors.grey[350],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            hayPublicados
                ? 'Ningún vehículo coincide con tu búsqueda'
                : 'Aún no hay vehículos publicados',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 12),
        if (hayPublicados && _hayFiltros)
          Center(
            child: FilledButton.tonal(
              onPressed: _limpiarFiltros,
              child: const Text('Limpiar filtros'),
            ),
          )
        else
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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalleVehiculoScreen(vehiculo: v)),
      ),
      child: Container(
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: FotoVehiculo(vehiculo: v, height: 140),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${v.marca} ${v.modelo}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          v.tipo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(v.ubicacion,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${v.anio}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formatoPrecio(v.precioPorDia)} / día',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      Row(
                        children: [
                          Text('Ver más',
                              style: TextStyle(
                                  color: primary, fontWeight: FontWeight.w600)),
                          Icon(Icons.chevron_right, color: primary),
                        ],
                      ),
                    ],
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