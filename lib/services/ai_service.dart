import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/resultado_licencia.dart';

// Error propio para cuando la IA está saturada
class IASaturadaException implements Exception {
  final String mensaje;
  IASaturadaException(this.mensaje);

  @override
  String toString() => mensaje;
}

class AIService {
  static const String _modeloPrincipal = 'gemini-flash-latest';
  static const String _modeloRespaldo = 'gemini-flash-lite-latest';

    static const String _prompt = '''
Analiza esta imagen. Debe ser una licencia de conducción colombiana (puede ser el frente o el reverso, y la foto puede estar girada).

Extrae los datos y responde SOLO con un JSON válido, sin texto adicional, con exactamente este formato:
{"nombre": "...", "categoria": "...", "fecha_vencimiento": "dd/mm/aaaa", "legible": true}

Reglas:
- Escribe la fecha SIEMPRE con barras en formato dd/mm/aaaa, aunque en el documento aparezca con guiones o puntos.
- Si hay varias categorías con distintas fechas de vigencia, devuelve la categoría y la fecha de la primera fila de la tabla.
- Si un dato no aparece en la imagen (por ejemplo el nombre en el reverso), déjalo como cadena vacía "".
- No inventes datos: si no estás seguro de un valor, déjalo vacío.

Si la imagen no es una licencia de conducción o no se puede leer, responde exactamente:
{"nombre": "", "categoria": "", "fecha_vencimiento": "", "legible": false}
''';

  Future<ResultadoLicencia> analizarLicencia(File imagen) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Falta la API key en el archivo .env');
    }

    final bytes = await imagen.readAsBytes();
    final imagenBase64 = base64Encode(bytes);
    final ruta = imagen.path.toLowerCase();
    final mime = ruta.endsWith('.png') ? 'image/png' : 'image/jpeg';

    // Se prueba primero el modelo principal y, si falla, el de respaldo
    for (final modelo in [_modeloPrincipal, _modeloRespaldo]) {
      for (var intento = 1; intento <= 2; intento++) {
        http.Response response;

        try {
          response = await _llamar(modelo, apiKey, imagenBase64, mime);
        } on TimeoutException {
          // Si este modelo no responde a tiempo, pasamos directo al siguiente
          break;
        }

        if (response.statusCode == 200) {
          return _procesarRespuesta(response.body);
        }

        // 503 = saturado, 429 = demasiadas peticiones: vale la pena reintentar
        if (response.statusCode == 503 || response.statusCode == 429) {
          await Future.delayed(Duration(seconds: intento * 2));
          continue;
        }

        // Cualquier otro código es un error real, no tiene sentido reintentar
        throw Exception('Error de la IA (código ${response.statusCode})');
      }
    }

    throw IASaturadaException(
      'La IA está muy ocupada en este momento. Espera un minuto e intenta de nuevo.',
    );
  }

  Future<http.Response> _llamar(
    String modelo,
    String apiKey,
    String imagenBase64,
    String mime,
  ) {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelo:generateContent?key=$apiKey',
    );

    return http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': _prompt},
                  {
                    'inline_data': {'mime_type': mime, 'data': imagenBase64},
                  },
                ],
              },
            ],
            'generationConfig': {'response_mime_type': 'application/json'},
          }),
        )
        .timeout(const Duration(seconds: 40));
  }

  ResultadoLicencia _procesarRespuesta(String body) {
    final data = jsonDecode(body);
    final texto = data['candidates'][0]['content']['parts'][0]['text'];
    final limpio =
        texto.toString().replaceAll('```json', '').replaceAll('```', '').trim();
    return ResultadoLicencia.fromJson(jsonDecode(limpio));
  }
}