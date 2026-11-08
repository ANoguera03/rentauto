import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehiculo_provider.dart';
import '../screens/auth_gate.dart';

/// Vuelve a la elección cliente / dueño sin cerrar la sesión
class BotonCambiarModo extends StatelessWidget {
  const BotonCambiarModo({super.key});

  @override
  Widget build(BuildContext context) {
    final esDueno = context.read<VehiculoProvider>().rolActual == 'dueño';

    return IconButton(
      tooltip: esDueno ? 'Cambiar a modo cliente' : 'Cambiar a modo dueño',
      icon: const Icon(Icons.swap_horiz),
      onPressed: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      ),
    );
  }
}