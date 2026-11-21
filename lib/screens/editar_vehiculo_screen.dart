import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/documento_vehiculo.dart';
import '../models/vehiculo.dart';
import '../providers/publicar_ia_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../utils/contacto.dart';
import '../utils/fechas.dart';
import '../widgets/documentos_vehiculo.dart';
import '../widgets/foto_vehiculo.dart';

class EditarVehiculoScreen extends StatefulWidget {
  final Vehiculo vehiculo;
  const EditarVehiculoScreen({super.key, required this.vehiculo});

  @override
  State<EditarVehiculoScreen> createState() => _EditarVehiculoScreenState();
}

class _EditarVehiculoScreenState extends State<EditarVehiculoScreen> {
  late final TextEditingController _marca =
      TextEditingController(text: widget.vehiculo.marca);
  late final TextEditingController _modelo =
      TextEditingController(text: widget.vehiculo.modelo);
  late final TextEditingController _anio =
      TextEditingController(text: '${widget.vehiculo.anio}');
  late final TextEditingController _precio = TextEditingController(
      text: widget.vehiculo.precioPorDia.toStringAsFixed(0));
  late final TextEditingController _ubicacion =
      TextEditingController(text: widget.vehiculo.ubicacion);
  late final TextEditingController _telefono = TextEditingController(
      text: telefonoParaMostrar(widget.vehiculo.telefono));

  late String _tipo = widget.vehiculo.tipo;
  late bool _disponible = widget.vehiculo.disponible;
  File? _nuevaFoto;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PublicarIAProvider>().reiniciar());
  }

  @override
  void dispose() {
    _marca.dispose();
    _modelo.dispose();
    _anio.dispose();
    _precio.dispose();
    _ubicacion.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<File?> _elegirImagen({double maxWidth = 1280, int calidad = 80}) async {
    final fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (fuente == null) return null;

    final picked = await ImagePicker()
        .pickImage(source: fuente, maxWidth: maxWidth, imageQuality: calidad);
    return picked == null ? null : File(picked.path);
  }

  Future<void> _cambiarFoto() async {
    final archivo = await _elegirImagen(maxWidth: 800, calidad: 60);
    if (archivo == null || !mounted) return;
    setState(() => _nuevaFoto = archivo);
  }

  Future<void> _renovar({required bool esSoat}) async {
    final archivo = await _elegirImagen();
    if (archivo == null || !mounted) return;
    final ia = context.read<PublicarIAProvider>();
    if (esSoat) {
      await ia.analizarSoat(archivo);
    } else {
      await ia.analizarTecno(archivo);
    }
  }

  String? _motivoBloqueo(PublicarIAProvider ia) {
    if (_marca.text.trim().isEmpty || _modelo.text.trim().isEmpty) {
      return 'Completa la marca y el modelo.';
    }
    final anio = int.tryParse(_anio.text.trim());
    if (anio == null || anio < 1950 || anio > DateTime.now().year + 1) {
      return 'Indica un año válido.';
    }
    final precio = double.tryParse(_precio.text.trim());
    if (precio == null || precio <= 0) return 'Indica el precio por día.';
    if (normalizarTelefonoCO(_telefono.text) == null) {
      return 'Indica un celular de WhatsApp válido (10 dígitos).';
    }
    if (ia.soat.cargando || ia.tecno.cargando) {
      return 'Espera a que la IA termine de leer el documento.';
    }
    if (ia.soat.exito && !ia.soatOk) {
      return 'El SOAT que subiste no es válido: ${ia.soat.resultado?.problema('soat', 'SOAT') ?? ''}';
    }
    if (ia.tecno.exito && !ia.tecnoOk) {
      return 'La tecnomecánica que subiste no es válida: ${ia.tecno.resultado?.problema('tecnomecanica', 'tecnomecánica') ?? ''}';
    }
    return ia.problemaPlacas;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);

    final ia = context.read<PublicarIAProvider>();
    final provider = context.read<VehiculoProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final actualizado = widget.vehiculo.copyWith(
      marca: _marca.text.trim(),
      modelo: _modelo.text.trim(),
      anio: int.tryParse(_anio.text.trim()),
      precioPorDia: double.tryParse(_precio.text.trim()),
      tipo: _tipo,
      ubicacion: _ubicacion.text.trim().isEmpty ? 'Pasto' : _ubicacion.text.trim(),
      telefono: normalizarTelefonoCO(_telefono.text),
      disponible: _disponible,
      fotoPath: _nuevaFoto?.path,
      // Si se subió un documento nuevo y es válido, se actualiza su fecha
      soatVence: ia.soatOk ? ia.soat.resultado!.vencimientoIso : null,
      tecnoVence: ia.tecnoOk ? ia.tecno.resultado!.vencimientoIso : null,
    );

    final error = await provider.actualizarVehiculo(actualizado);
    if (!mounted) return;

    if (error != null) {
      setState(() => _guardando = false);
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    messenger.showSnackBar(const SnackBar(content: Text('Cambios guardados')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ia = context.watch<PublicarIAProvider>();
    final motivo = _motivoBloqueo(ia);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar vehículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            GestureDetector(
              onTap: _cambiarFoto,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: _nuevaFoto != null
                          ? Image.file(_nuevaFoto!, fit: BoxFit.cover)
                          : FotoVehiculo(vehiculo: widget.vehiculo, height: 160),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Cambiar foto',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disponible para alquilar'),
              subtitle: const Text('Si lo pausas, no aparece en el explorador.'),
              value: _disponible,
              onChanged: (v) => setState(() => _disponible = v),
            ),
            const SizedBox(height: 8),

            _campo('Marca', _marca),
            _campo('Modelo', _modelo),
            _campo('Año', _anio, tipo: TextInputType.number),
            _campo('Ubicación', _ubicacion),
            const Text('Tipo de vehículo',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['carro', 'moto', 'camioneta'].map((t) {
                return ChoiceChip(
                  label: Text(t),
                  selected: _tipo == t,
                  onSelected: (_) => setState(() => _tipo = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            _campo('Precio por día (COP)', _precio, tipo: TextInputType.number),
            _campo('WhatsApp de contacto', _telefono, tipo: TextInputType.phone),

            const SizedBox(height: 6),
            const Text('Documentos',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DocumentosVehiculo(vehiculo: widget.vehiculo),
            const SizedBox(height: 10),
            _filaRenovar('SOAT', ia.soat, 'soat', 'SOAT', true),
            _filaRenovar(
                'Tecnomecánica', ia.tecno, 'tecnomecanica', 'tecnomecánica', false),

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (motivo == null && !_guardando) ? _guardar : null,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar cambios'),
              ),
            ),
            if (motivo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(motivo,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController c, {TextInputType? tipo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: tipo,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _filaRenovar(String titulo, TareaIA<DocumentoVehiculo> tarea,
      String tipoEsperado, String etiqueta, bool esSoat) {
    final d = tarea.resultado;
    String texto = 'Sube una foto para renovarlo';
    Color color = Colors.grey.shade600;

    if (tarea.cargando) {
      texto = 'La IA está leyendo el documento...';
    } else if (tarea.error) {
      texto = tarea.mensajeError;
      color = Colors.red.shade700;
    } else if (tarea.exito && d != null) {
      final problema = d.problema(tipoEsperado, etiqueta);
      if (problema == null) {
        texto = 'Nuevo vencimiento: ${fechaCorta(d.fechaDate!)}';
        color = Colors.green.shade700;
      } else {
        texto = problema;
        color = Colors.red.shade700;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actualizar $titulo',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(texto, style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (tarea.cargando)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            OutlinedButton(
              onPressed: () => _renovar(esSoat: esSoat),
              child: const Text('Subir foto'),
            ),
        ],
      ),
    );
  }
}