// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/vehiculo_provider.dart';
// import 'buscar_vehiculos_screen.dart';

// class SelectorPerfilScreen extends StatefulWidget {
//   const SelectorPerfilScreen({super.key});

//   @override
//   State<SelectorPerfilScreen> createState() => _SelectorPerfilScreenState();
// }

// class _SelectorPerfilScreenState extends State<SelectorPerfilScreen> {
//   final _nombreController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.directions_car, size: 60, color: Color(0xFF0E8A72)),
//               const SizedBox(height: 12),
//               const Text('RentAuto', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 24),
//               TextField(
//                 controller: _nombreController,
//                 decoration: const InputDecoration(
//                   labelText: 'Tu nombre',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => _entrar(context, 'cliente'),
//                   child: const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     child: Text('Entrar como cliente'),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton(
//                   onPressed: () => _entrar(context, 'dueño'),
//                   child: const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     child: Text('Entrar como dueño'),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _entrar(BuildContext context, String rol) {
//     context.read<VehiculoProvider>().rolActual = rol;
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const BuscarVehiculosScreen()),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehiculo_provider.dart';
import 'buscar_vehiculos_screen.dart';

// Definición de colores profesionales
class AppColors {
  static const Color primaryBlue = Color(0xFF1E3A8A); // Azul intenso profesional
  static const Color secondaryBlue = Color(0xFF007BFF); // Azul más brillante para destaques
  static const Color backgroundLight = Color(0xFFF8F9FA); // Gris muy claro para fondo
  static const Color textDark = Color(0xFF333333); // Gris oscuro para texto principal
  static const Color textLight = Color(0xFFFFFFFF); // Blanco para texto en botones oscuros
  static const Color borderGray = Color(0xFFE0E0E0); // Gris medio para bordes sutiles
}

class SelectorPerfilScreen extends StatefulWidget {
  const SelectorPerfilScreen({super.key});

  @override
  State<SelectorPerfilScreen> createState() => _SelectorPerfilScreenState();
}

class _SelectorPerfilScreenState extends State<SelectorPerfilScreen> {
  final _nombreController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Definimos el estilo de texto global para esta pantalla
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Nuevo Logotipo RentAuto Profesional ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.borderGray,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on, // Un icono que combina ubicación/viaje
                      size: 48,
                      color: AppColors.secondaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.directions_car, // El icono de coche
                      size: 56,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Rent',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                      fontSize: 32,
                    ),
                  ),
                  Text(
                    'Auto',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryBlue,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
              // const Text(
              //   'Tu viaje, tu coche.', // Slogan opcional
              //   style: TextStyle(color: AppColors.textDark, fontSize: 14),
              // ),
              const SizedBox(height: 56),

              // --- Encabezado de Bienvenida ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '¡Bienvenido a RentAuto!',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Introduce tu nombre y selecciona tu perfil para comenzar.',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark.withOpacity(0.8),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // --- Campo de Texto del Nombre ---
              TextField(
                controller: _nombreController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Tu nombre completo',
                  labelStyle: const TextStyle(color: AppColors.primaryBlue, fontSize: 16),
                  hintText: 'Ej. Juan Pérez',
                  prefixIcon: const Icon(Icons.person, color: AppColors.secondaryBlue, size: 28,),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.secondaryBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- Botones de Selección de Perfil ---
              // Botón Principal: Cliente
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _entrar(context, 'cliente'),
                  icon: const Icon(Icons.shopping_bag, size: 28),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Entrar como Cliente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botón Secundario: Dueño
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _entrar(context, 'dueño'),
                  icon: const Icon(Icons.business_center, size: 28, color: AppColors.secondaryBlue),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Entrar como Dueño de Vehículo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryBlue,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.textLight,
                    side: const BorderSide(color: AppColors.secondaryBlue, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Texto de ayuda opcional ---
              // Text(
              //   '¿Necesitas ayuda? Contáctanos.',
              //   style: textTheme.bodySmall?.copyWith(color: AppColors.textDark.withOpacity(0.6)),
              // )
            ],
          ),
        ),
      ),
    );
  }

  void _entrar(BuildContext context, String rol) {
    // Mantengo tu lógica intacta
    context.read<VehiculoProvider>().rolActual = rol;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BuscarVehiculosScreen()),
    );
  }
}