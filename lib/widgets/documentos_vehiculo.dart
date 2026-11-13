import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../utils/fechas.dart';

/// Insignias con el estado del SOAT y la tecnomecánica de un vehículo
class DocumentosVehiculo extends StatelessWidget {
  final Vehiculo vehiculo;
  const DocumentosVehiculo({super.key, required this.vehiculo});

  Widget _chip(String texto, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 5),
          Text(texto,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _chipDocumento(String nombre, DateTime? fecha) {
    if (fecha == null) {
      return _chip('$nombre sin verificar', Icons.help_outline, Colors.grey.shade700);
    }
    if (fechaVigente(fecha)) {
      return _chip('$nombre vigente hasta ${fechaCorta(fecha)}',
          Icons.verified_outlined, Colors.green.shade700);
    }
    return _chip('$nombre vencido (${fechaCorta(fecha)})',
        Icons.warning_amber_rounded, Colors.red.shade700);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chipDocumento('SOAT', vehiculo.soatFecha),
        _chipDocumento('Tecnomecánica', vehiculo.tecnoFecha),
      ],
    );
  }
}