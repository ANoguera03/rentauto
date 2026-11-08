import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/filtros_busqueda.dart';
import '../services/ai_service.dart';

enum EstadoBusquedaIA { inicial, cargando, exito, error }

class BusquedaIAProvider extends ChangeNotifier {
  final AIService _ai = AIService();

  EstadoBusquedaIA estado = EstadoBusquedaIA.inicial;
  FiltrosBusqueda? filtros;
  String mensajeError = '';

  Future<void> buscar(String consulta) async {
    estado = EstadoBusquedaIA.cargando;
    mensajeError = '';
    notifyListeners();

    try {
      filtros = await _ai.interpretarBusqueda(consulta);
      estado = EstadoBusquedaIA.exito;
    } on IASaturadaException catch (e) {
      mensajeError = e.mensaje;
      estado = EstadoBusquedaIA.error;
    } on SocketException {
      mensajeError = 'Sin conexión a internet. Revisa tu red e intenta de nuevo.';
      estado = EstadoBusquedaIA.error;
    } on TimeoutException {
      mensajeError = 'La IA tardó demasiado en responder. Intenta de nuevo.';
      estado = EstadoBusquedaIA.error;
    } catch (e) {
      debugPrint('Error en búsqueda con IA: $e');
      mensajeError = 'No se pudo interpretar tu búsqueda. Revisa tu conexión e intenta de nuevo.';
      estado = EstadoBusquedaIA.error;
    }

    notifyListeners();
  }

  void reiniciar() {
    estado = EstadoBusquedaIA.inicial;
    filtros = null;
    mensajeError = '';
    notifyListeners();
  }
}