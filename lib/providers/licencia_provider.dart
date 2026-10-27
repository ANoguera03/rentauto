import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/resultado_licencia.dart';
import '../services/ai_service.dart';

enum EstadoValidacion { inicial, cargando, exito, error }

class LicenciaProvider extends ChangeNotifier {
  final AIService _ai = AIService();

  EstadoValidacion estado = EstadoValidacion.inicial;
  ResultadoLicencia? resultado;
  String mensajeError = '';
  File? imagen;

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
    debugPrint('Error IA: $e'); // el detalle técnico queda en la consola
    estado = EstadoValidacion.error;
  }

  notifyListeners();
}

  void reiniciar() {
    imagen = null;
    resultado = null;
    mensajeError = '';
    estado = EstadoValidacion.inicial;
    notifyListeners();
  }
}