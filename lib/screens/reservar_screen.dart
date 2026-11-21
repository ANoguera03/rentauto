import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/vehiculo.dart';
import '../providers/reserva_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../utils/contacto.dart';
import '../utils/formato.dart';
import '../providers/perfil_provider.dart';

class ReservarScreen extends StatefulWidget {
  final Vehiculo vehiculo;
  const ReservarScreen({super.key, required this.vehiculo});

  @override
  State<ReservarScreen> createState() => _ReservarScreenState();
}

class _ReservarScreenState extends State<ReservarScreen> {
  DateTimeRange? _rango;
  bool _guardando = false;
  final _formato = DateFormat('dd/MM/yyyy');
  final _telefonoCtrl = TextEditingController();
  String? _errorTelefono;


    @override
  void initState() {
    super.initState();
    _telefonoCtrl.text =
        telefonoParaMostrar(context.read<PerfilProvider>().telefono);
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFechas() async {
    final hoy = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 365)),
      initialDateRange: _rango,
    );
    if (rango != null) setState(() => _rango = rango);
  }

  int get _dias =>
      _rango == null ? 0 : _rango!.end.difference(_rango!.start).inDays + 1;
  double get _total => _dias * widget.vehiculo.precioPorDia;

  Future<void> _confirmar() async {
    final telefono = normalizarTelefonoCO(_telefonoCtrl.text);
    if (telefono == null) {
      setState(() => _errorTelefono =
          'Escribe un celular válido de 10 dígitos (ej: 300 123 4567).');
      return;
    }

    final cliente = context.read<VehiculoProvider>().nombreUsuario;
    setState(() {
      _errorTelefono = null;
      _guardando = true;
    });

    final error = await context.read<ReservaProvider>().crearReserva(
          vehiculo: widget.vehiculo,
          cliente: cliente,
          clienteTelefono: telefono,
          inicio: _rango!.start,
          fin: _rango!.end,
        );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reserva solicitada. El dueño debe aceptarla.')),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehiculo;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Reservar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 36, color: primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${v.marca} ${v.modelo}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${formatoPrecio(v.precioPorDia)} / día',
                            style: TextStyle(
                                color: primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('¿Cuándo lo necesitas?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _elegirFechas,
              icon: const Icon(Icons.date_range),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_rango == null
                    ? 'Elegir fechas'
                    : '${_formato.format(_rango!.start)}  →  ${_formato.format(_rango!.end)}'),
              ),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
            if (_rango != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _fila('Días', '$_dias'),
                    _fila('Precio por día', formatoPrecio(v.precioPorDia)),
                    const Divider(height: 24),
                    _fila('Total', formatoPrecio(_total), destacado: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Tu WhatsApp',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '300 123 4567',
                  helperText: 'El dueño lo usará para coordinar la entrega.',
                  errorText: _errorTelefono,
                  prefixIcon: const Icon(Icons.chat_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _confirmar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Confirmar reserva'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fila(String label, String valor, {bool destacado = false}) {
    final estilo = TextStyle(
      fontSize: destacado ? 17 : 14,
      fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: estilo), Text(valor, style: estilo)],
      ),
    );
  }
}