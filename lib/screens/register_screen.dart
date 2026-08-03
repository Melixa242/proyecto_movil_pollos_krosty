import 'package:flutter/material.dart';
import '../screens/app_colors.dart';
import '../screens/custom_button.dart';
import '../screens/custom_text_field.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    // TODO: conectar con AuthProvider.register(...) / ApiService real.
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
                        color: Colors.black.withOpacity(0.06),
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
                            onTap: () {
                              // TODO: Navigator.pushNamed(context, '/login');
                            },
                            child: const Text(
                              '¿Ya tienes cuenta?',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          AppButton(
                              label: 'Registrarse', onPressed: _handleRegister),
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
