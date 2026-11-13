import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/documento_vehiculo.dart';
import '../models/vehiculo.dart';
import '../providers/publicar_ia_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../utils/fechas.dart';
import '../utils/formato.dart';

class PublicarVehiculoScreen extends StatefulWidget {
  const PublicarVehiculoScreen({super.key});

  @override
  State<PublicarVehiculoScreen> createState() => _PublicarVehiculoScreenState();
}

class _PublicarVehiculoScreenState extends State<PublicarVehiculoScreen> {
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _precioController = TextEditingController();
  final _ubicacionController = TextEditingController();

  String _tipoSeleccionado = 'carro';
  bool _guardando = false;
  File? _imagenSeleccionada;
  String? _avisoFoto; // lo que la IA reconoció en la foto

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PublicarIAProvider>().reiniciar());
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _precioController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  // ---------- Selección de imágenes ----------
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

    final picked = await ImagePicker().pickImage(
      source: fuente,
      maxWidth: maxWidth,
      imageQuality: calidad,
    );
    return picked == null ? null : File(picked.path);
  }

  // La foto del vehículo va liviana: se guarda dentro del documento de Firestore
  Future<void> _seleccionarFoto() async {
    final archivo = await _elegirImagen(maxWidth: 800, calidad: 60);
    if (archivo == null || !mounted) return;
    context.read<PublicarIAProvider>().reiniciarFoto();
    setState(() {
      _imagenSeleccionada = archivo;
      _avisoFoto = null;
    });
  }

  // ---------- Acciones de IA ----------
  Future<void> _autocompletar() async {
    final ia = context.read<PublicarIAProvider>();
    await ia.analizarFoto(_imagenSeleccionada!);
    if (!mounted) return;

    final s = ia.foto.resultado;
    if (!ia.foto.exito || s == null) return;

    if (!s.legible) {
      setState(() => _avisoFoto =
          'No pudimos identificar un vehículo en la foto. Completa los datos a mano.');
      return;
    }

    setState(() {
      if (s.marca.isNotEmpty) _marcaController.text = s.marca;
      if (s.modelo.isNotEmpty) _modeloController.text = s.modelo;
      if (s.tipo.isNotEmpty) _tipoSeleccionado = s.tipo;

      final partes = [s.marca, s.modelo].where((e) => e.isNotEmpty).join(' ');
      _avisoFoto = partes.isEmpty
          ? 'La IA no pudo reconocer la marca ni el modelo. Completa los datos a mano.'
          : 'La IA sugirió: $partes${s.tipo.isEmpty ? '' : ' (${s.tipo})'}. Revisa que los datos sean correctos.';
    });
  }

  Future<void> _sugerirPrecio() async {
    final marca = _marcaController.text.trim();
    final modelo = _modeloController.text.trim();
    final anio = int.tryParse(_anioController.text.trim());

    if (marca.isEmpty ||
        modelo.isEmpty ||
        anio == null ||
        anio < 1980 ||
        anio > DateTime.now().year + 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa marca, modelo y un año válido para sugerir un precio.'),
        ),
      );
      return;
    }

    await context.read<PublicarIAProvider>().sugerirPrecio(
          tipo: _tipoSeleccionado,
          marca: marca,
          modelo: modelo,
          anio: anio,
          ubicacion: _ubicacionController.text.trim().isEmpty
              ? 'Pasto'
              : _ubicacionController.text.trim(),
        );
  }

  Future<void> _subirDocumento({required bool esSoat}) async {
    final archivo = await _elegirImagen();
    if (archivo == null || !mounted) return;

    final ia = context.read<PublicarIAProvider>();
    if (esSoat) {
      await ia.analizarSoat(archivo);
    } else {
      await ia.analizarTecno(archivo);
    }
  }

  // ---------- Reglas para poder publicar ----------
  String? _motivoBloqueo(PublicarIAProvider ia) {
    if (_marcaController.text.trim().isEmpty ||
        _modeloController.text.trim().isEmpty) {
      return 'Completa la marca y el modelo.';
    }
    final anio = int.tryParse(_anioController.text.trim());
    if (anio == null || anio < 1950 || anio > DateTime.now().year + 1) {
      return 'Indica un año válido.';
    }
    final precio = double.tryParse(_precioController.text.trim());
    if (precio == null || precio <= 0) return 'Indica el precio por día.';
    if (ia.soat.cargando || ia.tecno.cargando) {
      return 'Espera a que la IA termine de leer el documento.';
    }
    if (!ia.soatOk) return 'Sube un SOAT vigente para poder publicar.';
    return ia.problemaPlacas;
  }

  Future<void> _publicar() async {
    setState(() => _guardando = true);

    final sesion = context.read<VehiculoProvider>();
    final ia = context.read<PublicarIAProvider>();

    final vehiculo = Vehiculo(
      marca: _marcaController.text.trim(),
      modelo: _modeloController.text.trim(),
      anio: int.tryParse(_anioController.text.trim()) ?? DateTime.now().year,
      precioPorDia: double.tryParse(_precioController.text.trim()) ?? 0,
      tipo: _tipoSeleccionado,
      ubicacion: _ubicacionController.text.trim().isEmpty
          ? 'Pasto'
          : _ubicacionController.text.trim(),
      fotoPath: _imagenSeleccionada?.path,
      dueno: sesion.nombreUsuario,
      duenoId: sesion.uid,
      // Solo se guardan las fechas de vencimiento de los documentos válidos
      soatVence: ia.soatOk ? ia.soat.resultado!.vencimientoIso : null,
      tecnoVence: ia.tecnoOk ? ia.tecno.resultado!.vencimientoIso : null,
    );

    try {
      await sesion.agregarVehiculo(vehiculo);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error publicando vehículo: $e');
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo publicar. Revisa tu conexión e intenta de nuevo.'),
        ),
      );
    }
  }

  // ---------- Interfaz ----------
  @override
  Widget build(BuildContext context) {
    final ia = context.watch<PublicarIAProvider>();
    final motivo = _motivoBloqueo(ia);

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar vehículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            GestureDetector(
              onTap: _seleccionarFoto,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _imagenSeleccionada == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 32, color: Colors.grey[500]),
                          const SizedBox(height: 8),
                          Text('Agregar foto del vehículo',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imagenSeleccionada!,
                            fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            const SizedBox(height: 10),

            if (_imagenSeleccionada != null) _asistenteFoto(ia),

            const SizedBox(height: 6),
            _campo('Marca', _marcaController),
            _campo('Modelo', _modeloController),
            _campo('Año', _anioController, tipo: TextInputType.number),
            _campo('Ubicación', _ubicacionController),

            const Text('Tipo de vehículo',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['carro', 'moto', 'camioneta'].map((tipo) {
                return ChoiceChip(
                  label: Text(tipo),
                  selected: _tipoSeleccionado == tipo,
                  onSelected: (_) => setState(() => _tipoSeleccionado = tipo),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _campo('Precio por día (COP)', _precioController,
                tipo: TextInputType.number),
            _asistentePrecio(ia),

            const SizedBox(height: 8),
            const Text('Documentos del vehículo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'La IA lee la fecha de vigencia. Solo se guarda la fecha, no la foto.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            _filaDocumento(
              titulo: 'SOAT',
              icono: Icons.shield_outlined,
              tarea: ia.soat,
              tipoEsperado: 'soat',
              etiqueta: 'SOAT',
              esSoat: true,
              opcional: false,
            ),
            _filaDocumento(
              titulo: 'Tecnomecánica',
              icono: Icons.build_circle_outlined,
              tarea: ia.tecno,
              tipoEsperado: 'tecnomecanica',
              etiqueta: 'tecnomecánica',
              esSoat: false,
              opcional: true,
            ),
            if (ia.problemaPlacas != null)
              _aviso(ia.problemaPlacas!, Colors.red.shade700,
                  icono: Icons.error_outline),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (motivo == null && !_guardando) ? _publicar : null,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publicar vehículo'),
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

  Widget _campo(String label, TextEditingController controller,
      {TextInputType? tipo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: tipo,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _aviso(String texto, Color color, {IconData icono = Icons.info_outline}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _asistenteFoto(PublicarIAProvider ia) {
    final t = ia.foto;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: t.cargando ? null : _autocompletar,
            icon: const Icon(Icons.auto_awesome),
            label: Text(t.cargando
                ? 'La IA está mirando tu foto...'
                : 'Autocompletar con IA'),
          ),
        ),
        if (t.cargando)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
        if (t.error) _aviso(t.mensajeError, Colors.red.shade700, icono: Icons.error_outline),
        if (_avisoFoto != null && !t.cargando && !t.error)
          _aviso(_avisoFoto!, primary, icono: Icons.auto_awesome),
      ],
    );
  }

  Widget _asistentePrecio(PublicarIAProvider ia) {
    final t = ia.precio;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: t.cargando ? null : _sugerirPrecio,
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: Text(t.cargando ? 'Calculando...' : 'Sugerir precio con IA'),
        ),
        if (t.error) _aviso(t.mensajeError, Colors.red.shade700, icono: Icons.error_outline),
        if (t.exito && t.resultado != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rango estimado: ${formatoPrecio(t.resultado!.minimo)} – ${formatoPrecio(t.resultado!.maximo)} / día',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (t.resultado!.explicacion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(t.resultado!.explicacion,
                      style: const TextStyle(fontSize: 12.5)),
                ],
                const SizedBox(height: 4),
                Text(
                  'Es una estimación de la IA, no un precio de mercado verificado.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => setState(() {
                    _precioController.text =
                        t.resultado!.sugerido.toStringAsFixed(0);
                  }),
                  child: Text('Usar ${formatoPrecio(t.resultado!.sugerido)}'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _filaDocumento({
    required String titulo,
    required IconData icono,
    required TareaIA<DocumentoVehiculo> tarea,
    required String tipoEsperado,
    required String etiqueta,
    required bool esSoat,
    required bool opcional,
  }) {
    final d = tarea.resultado;
    String subtitulo;
    Color color = Colors.grey.shade600;
    IconData estadoIcono = Icons.radio_button_unchecked;
    String boton = 'Subir foto';

    if (tarea.cargando) {
      subtitulo = 'La IA está leyendo el documento...';
    } else if (tarea.error) {
      subtitulo = tarea.mensajeError;
      color = Colors.red.shade700;
      estadoIcono = Icons.error_outline;
      boton = 'Reintentar';
    } else if (tarea.exito && d != null) {
      final problema = d.problema(tipoEsperado, etiqueta);
      if (problema == null) {
        subtitulo =
            'Vigente hasta ${fechaCorta(d.fechaDate!)}${d.placa.isNotEmpty ? ' · Placa ${d.placa}' : ''}';
        color = Colors.green.shade700;
        estadoIcono = Icons.check_circle;
        boton = 'Cambiar';
      } else {
        subtitulo = problema;
        color = Colors.red.shade700;
        estadoIcono = Icons.warning_amber_rounded;
        boton = 'Subir otra';
      }
    } else {
      subtitulo = opcional
          ? 'Opcional · sube una foto del documento'
          : 'Obligatorio · sube una foto del documento';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icono, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!tarea.cargando) ...[
                      Icon(estadoIcono, size: 14, color: color),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(subtitulo,
                          style: TextStyle(fontSize: 12, color: color)),
                    ),
                  ],
                ),
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
              onPressed: () => _subirDocumento(esSoat: esSoat),
              child: Text(boton),
            ),
        ],
      ),
    );
  }
}