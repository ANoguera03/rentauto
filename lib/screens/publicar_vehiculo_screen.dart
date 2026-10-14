import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehiculo.dart';
import '../providers/vehiculo_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  File? _imagenSeleccionada;
  
  String _tipoSeleccionado = 'carro';
  bool _guardando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar vehículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
  onTap: _seleccionarImagen,
  child: Container(
    height: 140,
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: _imagenSeleccionada == null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text('Agregar foto del vehículo', style: TextStyle(color: Colors.grey[600])),
            ],
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover, width: double.infinity),
          ),
  ),
),
            _campo('Marca', _marcaController),
            _campo('Modelo', _modeloController),
            _campo('Año', _anioController, tipo: TextInputType.number),
            _campo('Precio por día (COP)', _precioController, tipo: TextInputType.number),
            _campo('Ubicación', _ubicacionController),
            const SizedBox(height: 8),
            const Text('Tipo de vehículo', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['carro', 'moto', 'camioneta'].map((tipo) {
                final seleccionado = _tipoSeleccionado == tipo;
                return ChoiceChip(
                  label: Text(tipo),
                  selected: seleccionado,
                  onSelected: (_) => setState(() => _tipoSeleccionado = tipo),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : _publicar,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _guardando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publicar vehículo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController controller, {TextInputType? tipo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Future<void> _publicar() async {
    if (_marcaController.text.isEmpty || _modeloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa al menos marca y modelo')),
      );
      return;
    }

    setState(() => _guardando = true);

    final vehiculo = Vehiculo(
      marca: _marcaController.text,
      modelo: _modeloController.text,
      anio: int.tryParse(_anioController.text) ?? 2020,
      precioPorDia: double.tryParse(_precioController.text) ?? 0,
      tipo: _tipoSeleccionado,
      ubicacion: _ubicacionController.text.isEmpty ? 'Pasto' : _ubicacionController.text,
      fotoPath: _imagenSeleccionada?.path, // <-- esto es lo nuevo
    );

    

    await context.read<VehiculoProvider>().agregarVehiculo(vehiculo);

    setState(() => _guardando = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _seleccionarImagen() async {
  final picker = ImagePicker();
  final XFile? imagen = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    imageQuality: 80,
  );
  if (imagen != null) {
    setState(() => _imagenSeleccionada = File(imagen.path));
  }
}
}