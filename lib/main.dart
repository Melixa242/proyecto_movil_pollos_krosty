import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:poyectocrosty/providers/parametrizacion/insumo_provider.dart';
import 'screens/seguridad/login_screen.dart';
import 'package:provider/provider.dart';
import 'providers/seguridad/auth_provider.dart';
import 'providers/parametrizacion/cliente_provider.dart';
import 'screens/dashboard_screen.dart';
import 'providers/transaccional/ingreso_bebida_provider.dart';
import 'providers/transaccional/ingreso_bebida_producto_provider.dart';
import 'providers/transaccional/ingreso_insumo_provider.dart';
import 'providers/transaccional/ingreso_insumo_detalle_provider.dart';
import 'providers/transaccional/merma_provider.dart';
import 'providers/transaccional/orden_produccion_provider.dart';
import 'providers/transaccional/orden_produccion_insumo_provider.dart';
import 'providers/transaccional/produccion_provider.dart';
import 'providers/transaccional/venta_provider.dart';
import 'providers/transaccional/detalle_venta_provider.dart';
import 'providers/transaccional/venta_pago_provider.dart';
import 'providers/seguridad/usuario_provider.dart';
import 'providers/seguridad/rol_provider.dart';
import 'providers/seguridad/asignacion_rol_provider.dart';
import 'providers/parametrizacion/unidad_medida_provider.dart';
import 'providers/parametrizacion/tipo_product_provider.dart';
import 'providers/parametrizacion/producto_provider.dart';
import 'providers/parametrizacion/produc_composicion_provider.dart';
import 'providers/parametrizacion/regla_provider.dart';
import 'navigation/app_navigation.dart';
import 'screens/app_theme.dart';
import 'services/local_db.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  // debugPrint también escribe en release (visible con logcat); se silencia para no exponer datos.
  if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.despertarServidores();
  await LocalDb.init();
  await SyncService.instance.iniciar();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SyncService.instance),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ClienteProvider()),
        ChangeNotifierProvider(create:(context) => InsumoProvider()),
        ChangeNotifierProvider(create: (_) => IngresoBebidaProvider()),
        ChangeNotifierProvider(create: (_) => IngresoBebidaProductoProvider()),
        ChangeNotifierProvider(create: (_) => IngresoInsumoProvider()),
        ChangeNotifierProvider(create: (_) => IngresoInsumoDetalleProvider()),
        ChangeNotifierProvider(create: (_) => MermaProvider()),
        ChangeNotifierProvider(create: (_) => OrdenProduccionProvider()),
        ChangeNotifierProvider(create: (_) => OrdenProduccionInsumoProvider()),
        ChangeNotifierProvider(create: (_) => ProduccionProvider()),
        ChangeNotifierProvider(create: (_) => VentaProvider()),
        ChangeNotifierProvider(create: (_) => DetalleVentaProvider()),
        ChangeNotifierProvider(create: (_) => VentaPagoProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => RolProvider()),
        ChangeNotifierProvider(create: (_) => AsignacionRolProvider()),
        ChangeNotifierProvider(create: (_) => UnidadMedidaProvider()),
        ChangeNotifierProvider(create: (_) => TipoProductProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => ProductoComposicionProvider()),
        ChangeNotifierProvider(create: (_) => ReglaConversionProvider()),

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
      theme: AppTheme.light,

    home:const AuthWrapper(),
      routes: AppNavigation.getRoutes(context),
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

