import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/vehiculo_provider.dart';
import 'screens/selector_perfil_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/licencia_provider.dart';
import 'providers/reserva_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Firebase listo: ${Firebase.app().options.projectId}');
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehiculoProvider()),
        ChangeNotifierProvider(create: (_) => VehiculoProvider()),
        ChangeNotifierProvider(create: (_) => LicenciaProvider()),
        ChangeNotifierProvider(create: (_) => ReservaProvider()),
      ],
      child: MaterialApp(
        title: 'RentAuto',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0E8A72),
          useMaterial3: true,
        ),
        home: const SelectorPerfilScreen(),
      ),
    );
  }
}