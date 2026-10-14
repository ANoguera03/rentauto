import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/vehiculo_provider.dart';
import 'screens/selector_perfil_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehiculoProvider()),
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