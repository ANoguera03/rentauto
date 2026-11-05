import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/licencia_provider.dart';
import '../providers/vehiculo_provider.dart';
import 'buscar_vehiculos_screen.dart';

class SelectorPerfilScreen extends StatelessWidget {
  final User usuario;
  const SelectorPerfilScreen({super.key, required this.usuario});

  String get _nombre {
    final n = usuario.displayName?.trim() ?? '';
    return n.isNotEmpty ? n : (usuario.email ?? 'Usuario');
  }

  void _entrar(BuildContext context, String rol) {
    final vehiculos = context.read<VehiculoProvider>();
    vehiculos.rolActual = rol;
    vehiculos.uid = usuario.uid;
    vehiculos.nombreUsuario = _nombre;

    // La licencia guardada se asocia al id de la cuenta, no al nombre
    context.read<LicenciaProvider>().cambiarUsuario(usuario.uid);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BuscarVehiculosScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.directions_car, size: 44, color: primary),
              ),
              const SizedBox(height: 14),
              const Text('RentAuto',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Hola, $_nombre',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('¿Cómo quieres usar la app hoy?',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _entrar(context, 'cliente'),
                  icon: const Icon(Icons.search),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Buscar y alquilar vehículos'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _entrar(context, 'dueño'),
                  icon: const Icon(Icons.key_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Publicar mis vehículos'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}