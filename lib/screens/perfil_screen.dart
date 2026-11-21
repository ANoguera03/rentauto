import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/resultado_licencia.dart';
import '../providers/licencia_provider.dart';
import '../providers/perfil_provider.dart';
import '../providers/reserva_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../utils/contacto.dart';
import 'auth_gate.dart';
import 'validar_licencia_screen.dart';

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

  // ---------- Acciones ----------
  Future<void> _editarNombre() async {
    final vehiculos = context.read<VehiculoProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: vehiculos.nombreUsuario);

    final nuevo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Tu nombre',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevo == null || nuevo.isEmpty || nuevo == vehiculos.nombreUsuario) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName(nuevo);
      await user?.reload();
      vehiculos.actualizarNombre(nuevo);
      messenger.showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
    } catch (e) {
      debugPrint('Error actualizando nombre: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar. Revisa tu conexión.')),
      );
    }
  }

  Future<void> _editarTelefono() async {
    final perfil = context.read<PerfilProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final controller =
        TextEditingController(text: telefonoParaMostrar(perfil.telefono));

    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tu WhatsApp'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '300 123 4567',
            helperText: 'Se usa para autocompletar al publicar y reservar.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (texto == null) return;

    final telefono = normalizarTelefonoCO(texto);
    if (telefono == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe un celular válido de 10 dígitos.')),
      );
      return;
    }

    await perfil.guardarTelefono(telefono);
    messenger.showSnackBar(const SnackBar(content: Text('WhatsApp guardado')));
  }

  Future<void> _abrirValidacion() async {
    context.read<LicenciaProvider>().reiniciar();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ValidarLicenciaScreen()),
    );
  }

  Future<void> _borrarLicencia() async {
    final licencia = context.read<LicenciaProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar licencia guardada'),
        content: const Text(
            'Se eliminarán de este celular las categorías y fechas guardadas. '
            'Tendrás que validarla de nuevo para reservar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    await licencia.eliminarGuardada();
    messenger.showSnackBar(const SnackBar(content: Text('Licencia eliminada')));
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  // ---------- Interfaz ----------
  @override
  Widget build(BuildContext context) {
    final vehiculos = context.watch<VehiculoProvider>();
    final reservas = context.watch<ReservaProvider>();
    final licencia = context.watch<LicenciaProvider>();
    final perfil = context.watch<PerfilProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    final nombre = vehiculos.nombreUsuario;
    final uid = vehiculos.uid;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final esDueno = vehiculos.rolActual == 'dueño';

    final hechas = reservas.reservas.where((r) => r.clienteId == uid).length;
    final recibidas = reservas.reservas.where((r) => r.duenoId == uid).length;
    final promedio = reservas.promedioRecibido(uid);
    final opiniones = reservas.calificacionesRecibidas(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          // Cabecera
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: primary.withOpacity(0.15),
              child: Text(_iniciales(nombre),
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: primary)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(nombre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                tooltip: 'Editar nombre',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: _editarNombre,
              ),
            ],
          ),
          if (email.isNotEmpty)
            Center(
              child: Text(email,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(esDueno ? Icons.key_outlined : Icons.search,
                      size: 16, color: primary),
                  const SizedBox(width: 6),
                  Text(esDueno ? 'Modo dueño' : 'Modo cliente',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primary)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthGate()),
                      (route) => false,
                    ),
                    child: Text('Cambiar',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: primary,
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Estadísticas
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
          const SizedBox(height: 26),

          // Contacto
          _titulo('Contacto'),
          const SizedBox(height: 8),
          _tarjeta(
            child: Row(
              children: [
                const Icon(Icons.chat_outlined, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        perfil.telefono.isEmpty
                            ? 'Sin registrar'
                            : '+57 ${telefonoParaMostrar(perfil.telefono)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar WhatsApp',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _editarTelefono,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // Licencia
          _titulo('Licencia de conducción'),
          const SizedBox(height: 4),
          Text(
            'La validas una sola vez: se guarda en tu celular y se usa en todas '
            'tus reservas para confirmar que tu categoría sirve para el vehículo. '
            'Solo se guardan las categorías y fechas, nunca la foto.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 10),
          _tarjetaLicencia(licencia),
          const SizedBox(height: 26),

          // Calificaciones
          _titulo('Calificaciones recibidas'),
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
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
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

          const SizedBox(height: 26),
          OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titulo(String texto) => Text(texto,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));

  Widget _tarjeta({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _stat(BuildContext context, String valor, String label,
      {IconData? icono}) {
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

  Widget _tarjetaLicencia(LicenciaProvider licencia) {
    final r = licencia.licenciaGuardada;
    final cats = r?.categorias ?? const <CategoriaLicencia>[];
    final validada = r != null && r.legible && cats.isNotEmpty;

    String chip;
    Color color;

    if (!validada) {
      chip = 'Sin validar';
      color = Colors.grey.shade600;
    } else if (cats.any((c) => c.vigente)) {
      chip = 'Vigente';
      color = Colors.green.shade700;
    } else {
      chip = 'Vencida';
      color = Colors.red.shade700;
    }

    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Licencia de conducción',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
          if (validada) ...[
            const SizedBox(height: 10),
            ...cats.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(c.codigo,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text('vence ${c.fechaVencimiento}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    const Spacer(),
                    Text(c.vigente ? 'Vigente' : 'Vencida',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: c.vigente
                                ? Colors.green.shade700
                                : Colors.red.shade700)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _abrirValidacion,
                  icon: Icon(validada ? Icons.refresh : Icons.upload_file),
                  label: Text(validada ? 'Actualizar' : 'Validar ahora'),
                ),
              ),
              if (validada) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _borrarLicencia,
                  child: Text('Borrar',
                      style: TextStyle(color: Colors.red.shade600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}