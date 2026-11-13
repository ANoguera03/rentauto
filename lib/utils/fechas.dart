/// Convierte "27/02/2035", "27-02-2035" o "27.02.2035" en fecha.
/// Devuelve null si no se entiende.
DateTime? parsearFecha(String texto) {
  final partes = texto.trim().split(RegExp(r'[\/\-\.\s]+'));
  if (partes.length != 3) return null;

  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final anio = int.tryParse(partes[2]);

  if (dia == null || mes == null || anio == null) return null;
  if (mes < 1 || mes > 12 || dia < 1 || dia > 31 || anio < 1900) return null;

  return DateTime(anio, mes, dia);
}

/// aaaa-mm-dd
String fechaAIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// dd/mm/aaaa
String fechaCorta(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// El último día de vigencia todavía cuenta
bool fechaVigente(DateTime? fecha) {
  if (fecha == null) return false;
  final hoy = DateTime.now();
  final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
  return !fecha.isBefore(hoySinHora);
}