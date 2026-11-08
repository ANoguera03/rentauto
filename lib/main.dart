import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/licencia_provider.dart';
import 'providers/reserva_provider.dart';
import 'providers/vehiculo_provider.dart';
import 'repositories/data_repository.dart';
import 'screens/auth_gate.dart';
import 'repositories/firestore_repository.dart';
import 'providers/busqueda_ia_provider.dart';

// Único lugar donde se decide qué base de datos usa la app.
// Más adelante aquí se cambiará por la implementación de Firestore.
// Para volver a la versión 100% local, cambiar por: DatabaseService()
final DataRepository repositorio = FirestoreRepository();

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
        ChangeNotifierProvider(create: (_) => VehiculoProvider(repositorio)),
        ChangeNotifierProvider(create: (_) => ReservaProvider(repositorio)),
        ChangeNotifierProvider(create: (_) => LicenciaProvider()),
        ChangeNotifierProvider(create: (_) => BusquedaIAProvider()),
      ],
      child: MaterialApp(
        title: 'RentAuto',
        debugShowCheckedModeBanner: false,
                theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0E8A72),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F8F7),
        ),
                home: const AuthGate(),
      ),
    );
  }
}