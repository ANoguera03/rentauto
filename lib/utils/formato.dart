import 'package:intl/intl.dart';

final NumberFormat _miles = NumberFormat('#,###');

String formatoPrecio(num valor) =>
    '\$${_miles.format(valor).replaceAll(',', '.')}';