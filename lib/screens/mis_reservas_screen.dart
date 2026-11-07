import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reserva.dart';
import '../providers/reserva_provider.dart';
import '../providers/vehiculo_provider.dart';

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  late bool _comoDueno;
  final _formato = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _comoDueno = context.read<VehiculoProvider>().rolActual == 'dueño';
    Future.microtask(() => context.read<ReservaProvider>().cargarReservas());
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'solicitada':
        return 'Solicitada';
      case 'aceptada':
        return 'Aceptada';
      case 'rechazada':
        return 'Rechazada';
      case 'en_curso':
        return 'En curso';
      case 'finalizada':
        return 'Finalizada';
      default:
        return estado;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'solicitada':
        return Colors.orange.shade700;
      case 'aceptada':
        return Colors.green.shade700;
      case 'rechazada':
        return Colors.red.shade700;
      case 'en_curso':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservaProvider = context.watch<ReservaProvider>();
    final uid = context.watch<VehiculoProvider>().uid;

    final lista = reservaProvider.reservas
        .where((r) => _comoDueno ? r.duenoId == uid : r.clienteId == uid)
        .toList();

    return Scaffold(
        appBar: AppBar(
        title: const Text('Mis reservas'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ReservaProvider>().cargarReservas(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Como cliente')),
                  ButtonSegment(value: true, label: Text('Como dueño')),
                ],
                selected: {_comoDueno},
                onSelectionChanged: (s) => setState(() => _comoDueno = s.first),
              ),
            ),
          ),
          Expanded(
            child: reservaProvider.cargando
                ? const Center(child: CircularProgressIndicator())
                : lista.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_outlined,
                                size: 60, color: Colors.grey[350]),
                            const SizedBox(height: 12),
                            Text(
                              _comoDueno
                                  ? 'Aún no has recibido solicitudes'
                                  : 'Aún no has hecho reservas',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: lista.length,
                        itemBuilder: (context, i) => _tarjeta(context, lista[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(BuildContext context, Reserva r) {
    final color = _colorEstado(r.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(r.vehiculoNombre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_textoEstado(r.estado),
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _comoDueno ? 'Cliente: ${r.cliente}' : 'Dueño: ${r.dueno.isEmpty ? "—" : r.dueno}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_formato.format(r.fechaInicio)} → ${_formato.format(r.fechaFin)}  (${r.dias} días)',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('\$${r.total.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
                    if (r.calificacion != null) _estrellasYComentario(r),
          if (!_comoDueno && r.estado == 'finalizada' && r.calificacion == null)
            _botonUnico('Calificar experiencia', () => _calificar(context, r)),
          if (_comoDueno) _acciones(context, r),
        ],
      ),
    );
  }

  // Los botones dependen del estado actual: cada estado solo permite ciertos pasos
  Widget _acciones(BuildContext context, Reserva r) {
    final provider = context.read<ReservaProvider>();

    switch (r.estado) {
      case 'solicitada':
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => provider.cambiarEstado(r.id!, 'rechazada'),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => provider.cambiarEstado(r.id!, 'aceptada'),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        );
      case 'aceptada':
        return _botonUnico('Entregar vehículo', () => provider.cambiarEstado(r.id!, 'en_curso'));
      case 'en_curso':
        return _botonUnico('Marcar como finalizada', () => provider.cambiarEstado(r.id!, 'finalizada'));
      default:
        return const SizedBox.shrink();
    }
  }

    Widget _estrellasYComentario(Reserva r) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < r.calificacion! ? Icons.star : Icons.star_border,
                size: 18,
                color: Colors.amber.shade700,
              ),
            ),
          ),
          if (r.comentario != null && r.comentario!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('"${r.comentario}"',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ),
        ],
      ),
    );
  }

  Future<void> _calificar(BuildContext context, Reserva r) async {
    final provider = context.read<ReservaProvider>();
    int estrellas = 5;
    final comentarioCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Cómo fue tu experiencia?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    onPressed: () => setModal(() => estrellas = i + 1),
                    icon: Icon(
                      i < estrellas ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                      size: 38,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: comentarioCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await provider.calificar(r.id!, estrellas, comentarioCtrl.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Enviar calificación'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonUnico(String texto, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(onPressed: onPressed, child: Text(texto)),
      ),
    );
  }
}