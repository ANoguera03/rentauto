import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/documento_vehiculo.dart';
import '../models/sugerencias_ia.dart';
import '../services/ai_service.dart';

enum EstadoTarea { inactivo, cargando, exito, error }

/// Una tarea de IA con sus cuatro estados
class TareaIA<T> {
  EstadoTarea estado = EstadoTarea.inactivo;
  T? resultado;
  String mensajeError = '';

  bool get cargando => estado == EstadoTarea.cargando;
  bool get exito => estado == EstadoTarea.exito;
  bool get error => estado == EstadoTarea.error;

  void reiniciar() {
    estado = EstadoTarea.inactivo;
    resultado = null;
    mensajeError = '';
  }
}

class PublicarIAProvider extends ChangeNotifier {
  final AIService _ai = AIService();

  final TareaIA<SugerenciaVehiculo> foto = TareaIA();
  final TareaIA<DocumentoVehiculo> soat = TareaIA();
  final TareaIA<DocumentoVehiculo> tecno = TareaIA();
  final TareaIA<SugerenciaPrecio> precio = TareaIA();

  Future<void> analizarFoto(File imagen) =>
      _ejecutar(foto, () => _ai.analizarFotoVehiculo(imagen));

  Future<void> analizarSoat(File imagen) =>
      _ejecutar(soat, () => _ai.analizarDocumentoVehiculo(imagen));

  Future<void> analizarTecno(File imagen) =>
      _ejecutar(tecno, () => _ai.analizarDocumentoVehiculo(imagen));

  Future<void> sugerirPrecio({
    required String tipo,
    required String marca,
    required String modelo,
    required int anio,
    required String ubicacion,
  }) =>
      _ejecutar(
        precio,
        () => _ai.sugerirPrecio(
          tipo: tipo,
          marca: marca,
          modelo: modelo,
          anio: anio,
          ubicacion: ubicacion,
        ),
      );

  // Manejo común de carga y errores para cualquier tarea de IA
  Future<void> _ejecutar<T>(TareaIA<T> tarea, Future<T> Function() accion) async {
    tarea.estado = EstadoTarea.cargando;
    tarea.resultado = null;
    tarea.mensajeError = '';
    notifyListeners();

    try {
      tarea.resultado = await accion();
      tarea.estado = EstadoTarea.exito;
    } on IASaturadaException catch (e) {
      tarea.mensajeError = e.mensaje;
      tarea.estado = EstadoTarea.error;
    } on SocketException {
      tarea.mensajeError = 'Sin conexión a internet. Revisa tu red e intenta de nuevo.';
      tarea.estado = EstadoTarea.error;
    } on TimeoutException {
      tarea.mensajeError = 'La IA tardó demasiado en responder. Intenta de nuevo.';
      tarea.estado = EstadoTarea.error;
    } catch (e) {
      debugPrint('Error de IA: $e');
      tarea.mensajeError = 'No se pudo completar la acción. Revisa tu conexión e intenta de nuevo.';
      tarea.estado = EstadoTarea.error;
    }

    notifyListeners();
  }

  // ---------- Reglas de negocio: la IA lee, el código decide ----------

  bool get soatOk =>
      soat.exito &&
      soat.resultado != null &&
      soat.resultado!.problema('soat', 'SOAT') == null;

  bool get tecnoOk =>
      tecno.exito &&
      tecno.resultado != null &&
      tecno.resultado!.problema('tecnomecanica', 'tecnomecánica') == null;

  /// Si se subieron los dos documentos válidos, deben ser del mismo vehículo
  String? get problemaPlacas {
    if (!soatOk || !tecnoOk) return null;
    final a = soat.resultado!.placa;
    final b = tecno.resultado!.placa;
    if (a.isNotEmpty && b.isNotEmpty && a != b) {
      return 'La placa del SOAT ($a) no coincide con la de la tecnomecánica ($b).';
    }
    return null;
  }

  void reiniciarFoto() {
    foto.reiniciar();
    notifyListeners();
  }

  void reiniciar() {
    foto.reiniciar();
    soat.reiniciar();
    tecno.reiniciar();
    precio.reiniciar();
    notifyListeners();
  }
}