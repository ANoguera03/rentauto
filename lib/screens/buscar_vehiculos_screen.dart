import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/filtros_busqueda.dart';
import '../models/vehiculo.dart';
import '../providers/busqueda_ia_provider.dart';
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
  static const double _precioTope = FiltrosBusqueda.precioTope;
  static const double _precioMinimo = FiltrosBusqueda.precioMinimo;

  final _busquedaCtrl = TextEditingController();
  String _tipo = 'todos';
  double _precioMax = _precioTope;
  String? _explicacionIA; // lo que la IA entendió de la búsqueda

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
      _explicacionIA = null;
    });
  }

  void _aplicarFiltrosIA(FiltrosBusqueda f) {
    setState(() {
      _tipo = f.tipo;
      _precioMax = f.precioMax ?? _precioTope;
      _busquedaCtrl.text = f.texto;
      _explicacionIA = f.explicacion.isEmpty ? null : f.explicacion;
    });
  }

  void _abrirBusquedaIA() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HojaBusquedaIA(onAplicar: _aplicarFiltrosIA),
    );
  }

  List<Vehiculo> _filtrar(List<Vehiculo> todos, String uid) {
    final q = _busquedaCtrl.text.trim().toLowerCase();

    return todos.where((v) {
      if (!v.disponible) return false;
      if (uid.isNotEmpty && v.duenoId == uid) return false;
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
    final colores = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _busquedaCtrl,
            onChanged: (_) => setState(() => _explicacionIA = null),
            decoration: InputDecoration(
              hintText: 'Buscar por marca, modelo o lugar',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busquedaCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _busquedaCtrl.clear();
                        _explicacionIA = null;
                      }),
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
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(Icons.auto_awesome,
                        size: 18, color: colores.onPrimaryContainer),
                    label: const Text('Buscar con IA'),
                    backgroundColor: colores.primaryContainer,
                    onPressed: _abrirBusquedaIA,
                  ),
                ),
                ...tipos.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _tipo == e.key,
                      onSelected: (_) => setState(() {
                        _tipo = e.key;
                        _explicacionIA = null;
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_explicacionIA != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colores.primaryContainer.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: colores.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_explicacionIA!,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
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
                  onChanged: (v) => setState(() {
                    _precioMax = v;
                    _explicacionIA = null;
                  }),
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

/// Hoja inferior donde el usuario describe lo que necesita con sus palabras
class _HojaBusquedaIA extends StatefulWidget {
  final void Function(FiltrosBusqueda) onAplicar;
  const _HojaBusquedaIA({required this.onAplicar});

  @override
  State<_HojaBusquedaIA> createState() => _HojaBusquedaIAState();
}

class _HojaBusquedaIAState extends State<_HojaBusquedaIA> {
  final _ctrl = TextEditingController();

  static const _ejemplos = [
    'Un carro económico para ir a Ipiales el fin de semana',
    'Camioneta para un viaje en familia a la Laguna de la Cocha',
    'Una moto barata para moverme por Pasto',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BusquedaIAProvider>().reiniciar());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final consulta = _ctrl.text.trim();
    if (consulta.isEmpty) return;

    final provider = context.read<BusquedaIAProvider>();
    await provider.buscar(consulta);
    if (!mounted) return;

    if (provider.estado == EstadoBusquedaIA.exito && provider.filtros != null) {
      widget.onAplicar(provider.filtros!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BusquedaIAProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final cargando = p.estado == EstadoBusquedaIA.cargando;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: primary),
              const SizedBox(width: 8),
              const Text('Cuéntame qué necesitas',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Escríbelo con tus palabras y la IA ajusta los filtros por ti.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            enabled: !cargando,
            maxLines: 2,
            maxLength: 200,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Ej: un carro barato para ir a Túquerres',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: _ejemplos
                .map((e) => ActionChip(
                      label: Text(e, style: const TextStyle(fontSize: 11.5)),
                      onPressed: cargando ? null : () => setState(() => _ctrl.text = e),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          if (cargando)
            const Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 12),
                Text('La IA está interpretando tu búsqueda...'),
              ],
            ),
          if (p.estado == EstadoBusquedaIA.error)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.mensajeError,
                        style:
                            TextStyle(color: Colors.red.shade800, fontSize: 13)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cargando ? null : _enviar,
              icon: Icon(p.estado == EstadoBusquedaIA.error
                  ? Icons.refresh
                  : Icons.search),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(p.estado == EstadoBusquedaIA.error
                    ? 'Reintentar'
                    : 'Buscar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}