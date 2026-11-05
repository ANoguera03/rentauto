import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/licencia_provider.dart';
import '../providers/reserva_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../models/resultado_licencia.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_gate.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ReservaProvider>().cargarReservas());
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ').where((p) => p.isNotEmpty).take(2);
    if (partes.isEmpty) return '?';
    return partes.map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final vehiculos = context.watch<VehiculoProvider>();
    final reservas = context.watch<ReservaProvider>();
    final licencia = context.watch<LicenciaProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    final nombre = vehiculos.nombreUsuario;
    final hechas = reservas.reservas.where((r) => r.cliente == nombre).length;
    final recibidas = reservas.reservas.where((r) => r.dueno == nombre).length;
    final promedio = reservas.promedioRecibido(nombre);
    final opiniones = reservas.calificacionesRecibidas(nombre);

    return Scaffold(
            appBar: AppBar(
        title: const Text('Mi perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: primary.withOpacity(0.15),
              child: Text(_iniciales(nombre),
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold, color: primary)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(nombre,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(
              vehiculos.rolActual == 'dueño' ? 'Dueño de vehículos' : 'Cliente',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _stat(context, '$hechas', 'Reservas hechas')),
              const SizedBox(width: 10),
              Expanded(child: _stat(context, '$recibidas', 'Solicitudes recibidas')),
              const SizedBox(width: 10),
              Expanded(
                child: _stat(
                  context,
                  promedio == null ? '—' : promedio.toStringAsFixed(1),
                  'Calificación',
                  icono: Icons.star,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Documentos',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _documentoLicencia(licencia),
          const SizedBox(height: 24),

          const Text('Calificaciones recibidas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (opiniones.isEmpty)
            Text('Aún no tienes calificaciones.',
                style: TextStyle(color: Colors.grey[600]))
          else
            ...opiniones.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < r.calificacion! ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('de ${r.cliente}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    if (r.comentario != null && r.comentario!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('"${r.comentario}"'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String valor, String label, {IconData? icono}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(valor,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
              if (icono != null)
                Icon(icono, size: 18, color: Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

    Widget _documentoLicencia(LicenciaProvider licencia) {
    final r = licencia.resultado;
    final cats = r?.categorias ?? const <CategoriaLicencia>[];
    final validada = r != null && r.legible && cats.isNotEmpty;

    String subtitulo;
    String chip;
    Color color;

    if (!validada) {
      subtitulo = 'Aún no has validado tu licencia';
      chip = 'Sin validar';
      color = Colors.grey.shade600;
    } else {
      final hayVigente = cats.any((c) => c.vigente);
      subtitulo = cats.map((c) => '${c.codigo} · ${c.fechaVencimiento}').join('   ');
      chip = hayVigente ? 'Vigente' : 'Vencida';
      color = hayVigente ? Colors.green.shade700 : Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Licencia de conducción',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitulo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(chip,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}