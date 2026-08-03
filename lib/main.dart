import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cliente_provider.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ClienteProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POLLOS KROSTY-SADO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor:Colors.deepPurple,
          primary: const Color(0xFF007bff),
          secondary: const Color(0xFF343a40),
        ),
          useMaterial3:true,
          scaffoldBackgroundColor: const Color(0xFFf8f9fa),
      ),

    home:const AuthWrapper(),
    );
  }
}
class AuthWrapper extends StatefulWidget{

  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState()=> _AuthWrapperState();
  }
  class _AuthWrapperState extends State<AuthWrapper>{
    @override
   void initState(){
      super.initState();
      Future.microtask((){
        if(!mounted)return;
        Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
      });
    }
    @override
    Widget build(BuildContext context) {
      final authProvider = Provider.of<AuthProvider>(context);

      // Si ya está autenticado (por token guardado), va al Dashboard.
      // Si no, va al Login formal.
      if (authProvider.isAuthenticated) {
        // Pasa el nombre del usuario autenticado al Dashboard.
        return DashboardScreen(
          userName: authProvider.user?['name']?.toString() ?? 'USUARIO',
        );
      } else {
        return const LoginScreen();
      }
    }


}

