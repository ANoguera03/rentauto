import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Devuelve el celular en formato 57XXXXXXXXXX, o null si no es un
/// celular colombiano válido (10 dígitos que empiezan por 3).
/// Acepta "300 123 4567", "+57 300 123 4567", "300-123-4567", etc.
String? normalizarTelefonoCO(String entrada) {
  var digitos = entrada.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length == 12 && digitos.startsWith('57')) {
    digitos = digitos.substring(2);
  }
  if (digitos.length == 10 && digitos.startsWith('3')) {
    return '57$digitos';
  }
  return null;
}

/// "573001234567" -> "300 123 4567" (vacío si no hay un número válido)
String telefonoParaMostrar(String n57) {
  if (n57.length != 12 || !n57.startsWith('57')) return '';
  final l = n57.substring(2);
  return '${l.substring(0, 3)} ${l.substring(3, 6)} ${l.substring(6)}';
}

/// Abre WhatsApp con el mensaje ya escrito. Devuelve false si no se pudo.
Future<bool> abrirWhatsApp(String telefono, String mensaje) async {
  final uri = Uri.https('wa.me', '/$telefono', {'text': mensaje});
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('No se pudo abrir WhatsApp: $e');
    return false;
  }
}