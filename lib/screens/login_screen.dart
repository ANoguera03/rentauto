import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _registro = false;
  bool _cargando = false;
  bool _ocultarPass = true;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Revisa tu red.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      default:
        return 'No se pudo completar la acción ($codigo).';
    }
  }

  Future<void> _enviar() async {
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty || (_registro && nombre.isEmpty)) {
      setState(() => _error = 'Completa todos los campos.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      if (_registro) {
        final cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        await cred.user?.updateDisplayName(nombre);
        await cred.user?.reload();
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: pass);
      }
      // No hay que navegar: AuthGate detecta la sesión y cambia de pantalla solo
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _mensajeError(e.code));
    } catch (e) {
      debugPrint('Error de autenticación: $e');
      if (mounted) setState(() => _error = 'Ocurrió un error. Intenta de nuevo.');
    }

    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.directions_car, size: 44, color: primary),
                ),
                const SizedBox(height: 14),
                const Text('RentAuto',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  _registro ? 'Crea tu cuenta' : 'Inicia sesión para continuar',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 28),

                if (_registro) ...[
                  TextField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Tu nombre',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.mail_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passCtrl,
                  obscureText: _ocultarPass,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarPass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _ocultarPass = !_ocultarPass),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 18, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Colors.red.shade800, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _enviar,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_registro ? 'Crear cuenta' : 'Iniciar sesión'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _cargando
                      ? null
                      : () => setState(() {
                            _registro = !_registro;
                            _error = null;
                          }),
                  child: Text(_registro
                      ? '¿Ya tienes cuenta? Inicia sesión'
                      : '¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}