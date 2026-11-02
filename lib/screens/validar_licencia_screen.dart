import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/licencia_provider.dart';

class ValidarLicenciaScreen extends StatelessWidget {
  const ValidarLicenciaScreen({super.key});

  Future<void> _elegir(BuildContext context, ImageSource fuente) async {
    final picked = await ImagePicker().pickImage(
      source: fuente,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked != null && context.mounted) {
      context.read<LicenciaProvider>().seleccionarImagen(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LicenciaProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Validar licencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para tu seguridad y la del dueño, sube una foto clara de tu licencia de conducción.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            // Vista previa de la imagen
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withOpacity(0.3)),
              ),
              child: p.imagen == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 44, color: primary),
                        const SizedBox(height: 8),
                        Text('Aún no has subido tu licencia',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(p.imagen!, fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _elegir(context, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _elegir(context, ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Cámara'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (p.imagen != null && p.estado == EstadoValidacion.inicial)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<LicenciaProvider>().analizar(),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Analizar con IA'),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            _contenidoSegunEstado(context, p),
          ],
        ),
      ),
    );
  }

  Widget _contenidoSegunEstado(BuildContext context, LicenciaProvider p) {
    switch (p.estado) {
      case EstadoValidacion.inicial:
        return const SizedBox.shrink();

      case EstadoValidacion.cargando:
        return _tarjeta(
          color: Colors.blueGrey.shade50,
          child: const Row(
            children: [
              SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 14),
              Expanded(child: Text('La IA está leyendo tu licencia...')),
            ],
          ),
        );

      case EstadoValidacion.error:
        return _tarjeta(
          color: Colors.red.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Text('Algo salió mal', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(p.mensajeError),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => context.read<LicenciaProvider>().analizar(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        );

      case EstadoValidacion.exito:
        final r = p.resultado!;
        if (!r.fechaInterpretable) {
          return _tarjeta(
            color: Colors.orange.shade50,
            child: Text(
              'Pudimos leer el documento, pero no la fecha de vigencia ("${r.fechaVencimiento}"). '
              'Intenta con una foto donde se vea claramente.',
            ),
          );
        }
        final aprobada = r.vigente;
        return Column(
          children: [
            _tarjeta(
              color: aprobada ? Colors.green.shade50 : Colors.red.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 18),
                      const SizedBox(width: 6),
                      const Text('Análisis de la IA',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _fila('Nombre', r.nombre),
                  _fila('Categoría', r.categoria),
                  _fila('Vence', r.fechaVencimiento),
                  const SizedBox(height: 6),
                  Text(
                    aprobada ? 'Licencia vigente' : 'Licencia vencida',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: aprobada ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: aprobada
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Licencia verificada. Aquí seguirá la reserva.')),
                        )
                    : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Continuar con la reserva'),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _tarjeta({required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: Colors.grey[700]))),
          Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}