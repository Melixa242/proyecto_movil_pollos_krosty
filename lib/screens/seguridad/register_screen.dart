import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/seguridad/auth_provider.dart';
import '../app_colors.dart';
import '../custom_button.dart';
import '../custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMessage('Completa todos los campos.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Ingresa un correo electrónico válido.');
      return;
    }
    if (password.length < 8) {
      _showMessage('La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (password != confirm) {
      _showMessage('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(name, email, password, confirm);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (authProvider.isAuthenticated) {
        // El backend devolvió token: AuthWrapper detecta el cambio y
        // te lleva directo al Dashboard. Solo salimos de esta pantalla.
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // El backend registró pero no devolvió sesión: volvemos al login
        // para que el usuario ingrese con sus nuevas credenciales.
        _showMessage('Cuenta creada. Ahora puedes iniciar sesión.');
        Navigator.of(context).pop();
      }
    } else {
      _showMessage(authProvider.error ?? 'No se pudo completar el registro.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'POLLOS KROSTY SADO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Crear cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Registra un nuevo usuario en el sistema.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 26),
                      CustomTextField(label: 'Nombre', controller: _nameController),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Correo electrónico',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Contraseña',
                        obscureText: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Confirmar contraseña',
                        obscureText: true,
                        controller: _confirmController,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text(
                              '¿Ya tienes cuenta?',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          AppButton(
                            label: _isLoading ? 'Registrando...' : 'Registrarse',
                            onPressed: _isLoading ? null : _handleRegister,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
