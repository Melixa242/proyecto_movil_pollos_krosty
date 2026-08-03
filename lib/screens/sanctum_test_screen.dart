import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SanctumTestScreen extends StatelessWidget {
  const SanctumTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba Sanctum (AdminLTE Style)'),
        backgroundColor: const Color(0xFF343a40), // Color oscuro de AdminLTE
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: const Color(0xFFf4f6f9), // Color de fondo gris claro de AdminLTE
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Estado de Autenticación',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      authProvider.isAuthenticated ? Icons.check_circle : Icons.error,
                      color: authProvider.isAuthenticated ? Colors.green : Colors.red,
                      size: 50,
                    ),
                    Text(
                      authProvider.isAuthenticated ? 'Autenticado' : 'No Autenticado',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!authProvider.isAuthenticated)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007bff), // Azul de AdminLTE
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  bool success = await authProvider.login('test@example.com', 'password');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Login Exitoso' : 'Error: ${authProvider.error}')),
                  );
                },
                child: const Text('Probar Login (test@example.com)'),
              ),
            if (authProvider.isAuthenticated) ...[
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos del Usuario (Sanctum Profile)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Text('Nombre: ${authProvider.user?['name']}'),
                      Text('Email: ${authProvider.user?['email']}'),
                      Text('Roles: ${authProvider.user?['roles']?.join(', ')}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFdc3545), // Rojo de AdminLTE
                  foregroundColor: Colors.white,
                ),
                onPressed: () => authProvider.logout(),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
