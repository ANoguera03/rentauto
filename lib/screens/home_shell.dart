import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehiculo_provider.dart';
import 'buscar_vehiculos_screen.dart';
import 'mis_reservas_screen.dart';
import 'mis_vehiculos_screen.dart';
import 'perfil_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final esDueno = context.read<VehiculoProvider>().rolActual == 'dueño';

    final paginas = <Widget>[
      esDueno ? const MisVehiculosScreen() : const BuscarVehiculosScreen(),
      const MisReservasScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      // IndexedStack mantiene el estado de cada pestaña al cambiar entre ellas
      body: IndexedStack(index: _indice, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: [
          NavigationDestination(
            icon: Icon(esDueno ? Icons.directions_car_outlined : Icons.search),
            selectedIcon:
                Icon(esDueno ? Icons.directions_car : Icons.search),
            label: esDueno ? 'Mis vehículos' : 'Explorar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Reservas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}