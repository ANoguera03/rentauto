import 'package:flutter/material.dart';
import '../services/database_service.dart';

class PerfilProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  String usuario = '';
  String telefono = ''; // formato 57XXXXXXXXXX, vacío si no hay

  // Se llama al entrar con una cuenta
  Future<void> cargar(String uid) async {
    usuario = uid;
    telefono = '';
    notifyListeners();
    try {
      telefono = await _db.obtenerTelefono(uid) ?? '';
    } catch (e) {
      debugPrint('Error leyendo el perfil: $e');
    }
    notifyListeners();
  }

  Future<void> guardarTelefono(String telefonoNormalizado) async {
    await _db.guardarTelefono(usuario, telefonoNormalizado);
    telefono = telefonoNormalizado;
    notifyListeners();
  }
}