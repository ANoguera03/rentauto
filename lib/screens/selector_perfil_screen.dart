import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehiculo_provider.dart';
import 'buscar_vehiculos_screen.dart';

class SelectorPerfilScreen extends StatefulWidget {
  const SelectorPerfilScreen({super.key});

  @override
  State<SelectorPerfilScreen> createState() => _SelectorPerfilScreenState();
}

class _SelectorPerfilScreenState extends State<SelectorPerfilScreen> {
  final _nombreController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car, size: 60, color: Color(0xFF0E8A72)),
              const SizedBox(height: 12),
              const Text('RentAuto', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Tu nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _entrar(context, 'cliente'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Entrar como cliente'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _entrar(context, 'dueño'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Entrar como dueño'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _entrar(BuildContext context, String rol) {
    context.read<VehiculoProvider>().rolActual = rol;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BuscarVehiculosScreen()),
    );
  }
}