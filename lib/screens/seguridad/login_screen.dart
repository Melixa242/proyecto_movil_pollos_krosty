import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/seguridad/auth_provider.dart';
import '../../navigation/app_navigation.dart';
import '../app_colors.dart';
import '../custom_button.dart';
import '../custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo y contraseña.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Error al iniciar sesión')),
      );
    }
    // Si fue exitoso, AuthWrapper detecta isAuthenticated y muestra el Dashboard.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              clipBehavior: Clip.antiAlias,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Franja superior degradada (rojo -> verde), sello de marca.
                  Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryRed, AppColors.accentGreen],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Iniciar sesión',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Accede al sistema de gestión con tu cuenta.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),
                        CustomTextField(
                          label: 'Correo electrónico',
                          hint: 'usuario@correo.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          label: 'Contraseña',
                          hint: 'Tu contraseña',
                          obscureText: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primaryRed,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Recordarme',
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero),
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.accentGreen,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        AppButton(
                          label: _isLoading ? 'Ingresando...' : 'Ingresar',
                          expand: true,
                          onPressed: _isLoading ? null : _handleLogin,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('¿No tienes una cuenta? ',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, AppNavigation.register);
                              },
                              child: const Text(
                                'Regístrate',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.accentGreen,
                                    fontWeight: FontWeight.w700),
                              ),
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
      ),
    );
  }
}
