import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/resultado_licencia.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';

enum EstadoValidacion { inicial, cargando, exito, error }

class LicenciaProvider extends ChangeNotifier {
  final AIService _ai = AIService();
  final DatabaseService _db = DatabaseService();

  String usuario = '';
  ResultadoLicencia? licenciaGuardada; // la que está en SQLite para este usuario

  EstadoValidacion estado = EstadoValidacion.inicial;
  ResultadoLicencia? resultado; // el resultado que se muestra en pantalla
  String mensajeError = '';
  File? imagen;

  // Se llama al entrar con un perfil: carga la licencia guardada de ese usuario
  Future<void> cambiarUsuario(String nombre) async {
    usuario = nombre;
    imagen = null;
    resultado = null;
    mensajeError = '';
    estado = EstadoValidacion.inicial;
    licenciaGuardada = null;
    notifyListeners();

    try {
      licenciaGuardada = await _db.obtenerLicencia(nombre);
    } catch (e) {
      debugPrint('Error leyendo licencia guardada: $e');
    }
    notifyListeners();
  }

  void seleccionarImagen(File archivo) {
    imagen = archivo;
    resultado = null;
    estado = EstadoValidacion.inicial;
    notifyListeners();
  }

  Future<void> analizar() async {
    if (imagen == null) return;

    estado = EstadoValidacion.cargando;
    notifyListeners();

    try {
      resultado = await _ai.analizarLicencia(imagen!);
      estado = EstadoValidacion.exito;

      final r = resultado!;
      if (r.legible && r.categorias.isNotEmpty && usuario.isNotEmpty) {
        // si falla el guardado, el análisis sigue siendo válido
        try {
          await _db.guardarLicencia(usuario, r);
          licenciaGuardada = r;
        } catch (e) {
          debugPrint('Error guardando licencia: $e');
        }
      }
    } on IASaturadaException catch (e) {
      mensajeError = e.mensaje;
      estado = EstadoValidacion.error;
    } on SocketException {
      mensajeError = 'Sin conexión a internet. Revisa tu red e intenta de nuevo.';
      estado = EstadoValidacion.error;
    } on TimeoutException {
      mensajeError = 'La IA tardó demasiado en responder. Intenta de nuevo.';
      estado = EstadoValidacion.error;
    } catch (e) {
      mensajeError = 'No se pudo analizar la licencia. Intenta de nuevo.';
      debugPrint('Error IA: $e');
      estado = EstadoValidacion.error;
    }

    notifyListeners();
  }

  // Borra la licencia guardada de este usuario (control de privacidad)
  Future<void> eliminarGuardada() async {
    try {
      await _db.eliminarLicencia(usuario);
    } catch (e) {
      debugPrint('Error borrando la licencia: $e');
    }
    licenciaGuardada = null;
    resultado = null;
    imagen = null;
    estado = EstadoValidacion.inicial;
    notifyListeners();
  }

  // Se llama al abrir la pantalla de validación. Si ya hay una licencia
  // guardada, se muestra directamente sin pedir una foto nueva.
  void reiniciar() {
    imagen = null;
    mensajeError = '';
    if (licenciaGuardada != null) {
      resultado = licenciaGuardada;
      estado = EstadoValidacion.exito;
    } else {
      resultado = null;
      estado = EstadoValidacion.inicial;
    }
    notifyListeners();
  }
}