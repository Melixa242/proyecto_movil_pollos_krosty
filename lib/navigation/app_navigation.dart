import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poyectocrosty/providers/parametrizacion/cliente_provider.dart';
import 'package:poyectocrosty/providers/parametrizacion/producto_provider.dart';
import 'package:poyectocrosty/providers/parametrizacion/tipo_product_provider.dart';
import 'package:poyectocrosty/services/api_service.dart';
import 'package:poyectocrosty/screens/parametrizacion/clientes_screen.dart';
import 'package:poyectocrosty/screens/parametrizacion/productos_screen.dart';
import 'package:poyectocrosty/screens/parametrizacion/insumos_screen.dart';
import 'package:poyectocrosty/screens/parametrizacion/unidades_medida_screen.dart';
import 'package:poyectocrosty/screens/parametrizacion/tipos_producto_screen.dart';
import 'package:poyectocrosty/screens/parametrizacion/producto_composicion_screen.dart';
import 'package:poyectocrosty/screens/parametrizacion/reglas_conversion_screen.dart';
import 'package:poyectocrosty/screens/transaccional/ingreso_bebida_screen.dart';
import 'package:poyectocrosty/screens/transaccional/ingreso_insumo_screen.dart';
import 'package:poyectocrosty/screens/transaccional/merma_screen.dart';
import 'package:poyectocrosty/screens/transaccional/orden_produccion_screen.dart';
import 'package:poyectocrosty/screens/transaccional/produccion_screen.dart';
import 'package:poyectocrosty/screens/transaccional/venta_screen.dart';
import 'package:poyectocrosty/screens/transaccional/historial_ventas_screen.dart';
import 'package:poyectocrosty/screens/reportes/reporte_ventas_screen.dart';
import 'package:poyectocrosty/screens/seguridad/usuarios_screen.dart';
import 'package:poyectocrosty/screens/seguridad/roles_screen.dart';
import 'package:poyectocrosty/screens/seguridad/asignacion_roles_screen.dart';
import 'package:poyectocrosty/screens/seguridad/register_screen.dart';

class AppNavigation {
  static const String register = '/register';
  static const String clientes = '/clientes';
  static const String productos = '/productos';
  static const String insumos = '/insumos';
  static const String unidadesMedida = '/unidades-medida';
  static const String tiposProducto = '/tipos-producto';
  static const String productoComposicion = '/producto-composicion';
  static const String reglasConversion = '/reglas-conversion';
  static const String ingresosBebidas = '/ingreso-bebidas';
  static const String ingresosInsumos = '/ingreso-insumos';
  static const String ordenesProduccion = '/orden-producciones';
  static const String producciones = '/producciones';
  static const String mermas = '/mermas';
  static const String ventas = '/ventas';
  static const String historialVentas = '/historial-ventas';
  static const String reporteVentas = '/reporte-ventas';
  static const String usuarios = '/usuarios';
  static const String roles = '/roles';
  static const String asignacionRoles = '/asignacion-roles';

  static Map<String, WidgetBuilder> getRoutes(BuildContext context) {
    return {
      register: (context) => const RegisterScreen(),
      clientes: (context) => const ClientesScreen(),
      productos: (context) => const ProductosScreen(),
      insumos: (context) => const InsumosScreen(),
      unidadesMedida: (context) => const UnidadesMedidaScreen(),
      tiposProducto: (context) => const TiposProductoScreen(),
      productoComposicion: (context) => const ProductoComposicionScreen(),
      reglasConversion: (context) => const ReglasConversionScreen(),
      ingresosBebidas: (context) => const IngresoBebidaScreen(),
      ingresosInsumos: (context) => const IngresoInsumoScreen(),
      ordenesProduccion: (context) => const OrdenProduccionScreen(),
      producciones: (context) => const ProduccionScreen(),
      mermas: (context) => const MermaScreen(),
      // Ventas toma productos, tipos y clientes de Laravel: la API Dart no los expone.
      ventas: (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ProductoProvider(api: ApiService.web)),
              ChangeNotifierProvider(create: (_) => TipoProductProvider(api: ApiService.web)),
              ChangeNotifierProvider(create: (_) => ClienteProvider(api: ApiService.web)),
            ],
            child: const VentaScreen(),
          ),
      historialVentas: (context) => const HistorialVentasScreen(),
      reporteVentas: (context) => const ReporteVentasScreen(),
      usuarios: (context) => const UsuariosScreen(),
      roles: (context) => const RolesScreen(),
      asignacionRoles: (context) => const AsignacionRolesScreen(),
    };
  }

  // Nota: la lista de providers de la app vive únicamente en main.dart
  // (MultiProvider). Antes existía un getProviders() acá que nadie llamaba
  // y quedaba desactualizado respecto a la lista real; se eliminó para
  // evitar que alguien lo edite pensando que tiene efecto.
}

