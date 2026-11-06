import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/parametrizacion/cliente_provider.dart';
import '../providers/parametrizacion/producto_provider.dart';
import '../providers/seguridad/auth_provider.dart';
import '../providers/seguridad/usuario_provider.dart';
import '../providers/transaccional/venta_provider.dart';
import './parametrizacion/clientes_screen.dart';
import 'app_colors.dart';
import '../navigation/app_navigation.dart';
import 'sync_status_chip.dart';

/// =====================================================================
/// PANTALLA: DASHBOARD - SISTEMA WEB KROSTY-SADO
/// Pantalla que se muestra inmediatamente después de un login exitoso.
/// =====================================================================
///
/// CÓMO USARLA:
/// Después de validar el login, navega así:
///
///   Navigator.pushReplacement(
///     context,
///     MaterialPageRoute(builder: (_) => const DashboardScreen(userName: 'ANA MELIXA TAPIA')),
///   );
///
/// =====================================================================

// ----------------------- COLORES ESPECÍFICOS DEL DASHBOARD -----------------------
// La paleta principal (rojo, verde, textos) vive en AppColors (app_colors.dart)
// y se comparte con login/register/CRUD. Acá solo van los tonos extra que usa
// este layout (fondo del sidebar, hover, etc.) para no duplicar AppColors.
class _DashPalette {
  static const Color pageBg = Color(0xFFF0EDED);
  static const Color textGray = AppColors.textSecondary;
}

// ----------------------- MODELO DE MÓDULO LATERAL -----------------------
class SideModule {
  final String title;
  final IconData icon;
  final List<SideNavItem> children;
  const SideModule({required this.title, required this.icon, required this.children});
}

class SideNavItem {
  final String label;
  final String description;
  final IconData icon;
  final String? route; // null => navega con un Widget en vez de ruta nombrada
  final WidgetBuilder? builder;
  const SideNavItem({required this.label, required this.description, required this.icon, this.route, this.builder});
}

class DashboardScreen extends StatefulWidget {
  final String userName;
  const DashboardScreen({super.key, this.userName = 'USUARIO'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarOpen = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<UsuarioProvider>().fetchUsuarios();
      context.read<ClienteProvider>().fetchClientes();
      context.read<ProductoProvider>().fetchProductos();
      context.read<VentaProvider>().fetchVentas();
    });
  }

  // ----------------------- DATA: módulos del menú lateral -----------------------
  // Cada módulo se puede desplegar y cada ítem navega a su ruta real
  // registrada en AppNavigation. Las mismas tarjetas se usan en el cuerpo
  // del dashboard (una sección por módulo).
  List<SideModule> get _modules => [
        SideModule(
          title: 'Acceso y seguridad',
          icon: Icons.shield_outlined,
          children: [
            SideNavItem(
              label: 'Usuarios',
              description: 'Gestiona los usuarios del sistema y sus accesos.',
              icon: Icons.people_outline,
              route: AppNavigation.usuarios,
            ),
            SideNavItem(
              label: 'Roles',
              description: 'Define los roles y permisos disponibles.',
              icon: Icons.badge_outlined,
              route: AppNavigation.roles,
            ),
            SideNavItem(
              label: 'Asignación de roles',
              description: 'Asigna roles a cada usuario del sistema.',
              icon: Icons.assignment_ind_outlined,
              route: AppNavigation.asignacionRoles,
            ),
          ],
        ),
        SideModule(
          title: 'Parametrización',
          icon: Icons.tune,
          children: [
            SideNavItem(
              label: 'Clientes',
              description: 'Gestiona la información de los clientes.',
              icon: Icons.person_pin_outlined,
              builder: (_) => const ClientesScreen(),
            ),
            SideNavItem(
              label: 'Productos',
              description: 'Catálogo de productos disponibles para la venta.',
              icon: Icons.shopping_bag_outlined,
              route: AppNavigation.productos,
            ),
            SideNavItem(
              label: 'Insumos',
              description: 'Controla el inventario de insumos.',
              icon: Icons.inventory_2_outlined,
              route: AppNavigation.insumos,
            ),
            SideNavItem(
              label: 'Unidades de medida',
              description: 'Configura las unidades de medida del sistema.',
              icon: Icons.rule_outlined,
              route: AppNavigation.unidadesMedida,
            ),
            SideNavItem(
              label: 'Tipos de producto',
              description: 'Clasifica los productos por categoría.',
              icon: Icons.category_outlined,
              route: AppNavigation.tiposProducto,
            ),
            SideNavItem(
              label: 'Producto-Composición',
              description: 'Define la composición de cada producto.',
              icon: Icons.layers_outlined,
              route: AppNavigation.productoComposicion,
            ),
            SideNavItem(
              label: 'Reglas de conversión',
              description: 'Configura las reglas de conversión de insumos.',
              icon: Icons.transform,
              route: AppNavigation.reglasConversion,
            ),
          ],
        ),
        SideModule(
          title: 'Transacciones',
          icon: Icons.shopping_cart_outlined,
          children: [
            SideNavItem(
              label: 'Ingresos de bebidas',
              description: 'Registra el ingreso de bebidas al inventario.',
              icon: Icons.local_drink_outlined,
              route: AppNavigation.ingresosBebidas,
            ),
            SideNavItem(
              label: 'Ingresos de insumos',
              description: 'Registra el ingreso de insumos al inventario.',
              icon: Icons.move_to_inbox_outlined,
              route: AppNavigation.ingresosInsumos,
            ),
            SideNavItem(
              label: 'Orden de producción',
              description: 'Gestiona las órdenes de producción.',
              icon: Icons.receipt_long_outlined,
              route: AppNavigation.ordenesProduccion,
            ),
            SideNavItem(
              label: 'Producción',
              description: 'Registra la producción realizada.',
              icon: Icons.outdoor_grill_outlined,
              route: AppNavigation.producciones,
            ),
            SideNavItem(
              label: 'Mermas',
              description: 'Registra las mermas del inventario.',
              icon: Icons.delete_outline,
              route: AppNavigation.mermas,
            ),
            SideNavItem(
              label: 'Ventas',
              description: 'Punto de venta y registro de ventas.',
              icon: Icons.point_of_sale_outlined,
              route: AppNavigation.ventas,
            ),
            SideNavItem(
              label: 'Historial de ventas',
              description: 'Consulta las ventas realizadas y su detalle.',
              icon: Icons.receipt_long,
              route: AppNavigation.historialVentas,
            ),
          ],
        ),
        SideModule(
          title: 'Reportes',
          icon: Icons.show_chart,
          children: [
            SideNavItem(
              label: 'Reporte de ventas',
              description: 'Ventas por día, semana, mes y año.',
              icon: Icons.bar_chart,
              route: AppNavigation.reporteVentas,
            ),
          ],
        ),
      ];

  void _openItem(SideNavItem item) {
    if (item.route != null) {
      Navigator.pushNamed(context, item.route!);
    } else if (item.builder != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: item.builder!));
    }
  }

  Future<void> _logout() async {
    // Limpia el token y el estado; AuthWrapper detecta el cambio
    // y vuelve automáticamente a la pantalla de login.
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await auth.logout()) {
      messenger.showSnackBar(SnackBar(content: Text(auth.error ?? 'No se pudo cerrar sesión')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;
    final sidebar = _Sidebar(
      modules: _modules,
      onSelect: _openItem,
      userName: widget.userName,
      onLogout: _logout,
    );

    return Scaffold(
      // La key permite abrir el drawer desde aquí: el context de este State
      // está por encima del Scaffold, así que Scaffold.of(context) no lo encuentra.
      key: _scaffoldKey,
      backgroundColor: _DashPalette.pageBg,
      drawer: isMobile ? Drawer(width: 300, child: sidebar) : null,
      body: Column(
        children: [
          _TopBar(
            userName: widget.userName,
            isMobile: isMobile,
            onMenuTap: () {
              if (isMobile) {
                _scaffoldKey.currentState?.openDrawer();
              } else {
                setState(() => _sidebarOpen = !_sidebarOpen);
              }
            },
            onLogout: _logout,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile && _sidebarOpen) SizedBox(width: 270, child: sidebar),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: _DashboardBody(
                        modules: _modules,
                        onSelect: _openItem,
                        isMobile: isMobile,
                        userName: widget.userName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Iniciales del usuario en un círculo (cabecera del menú y barra superior).
class _Avatar extends StatelessWidget {
  final String name;
  final double radius;
  const _Avatar({required this.name, this.radius = 16});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Text(
        _initials,
        style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: radius * 0.75),
      ),
    );
  }
}

// =====================================================================
// BARRA SUPERIOR
// =====================================================================
class _TopBar extends StatelessWidget {
  final String userName;
  final bool isMobile;
  final VoidCallback onMenuTap;
  final VoidCallback onLogout;

  const _TopBar({
    required this.userName,
    required this.isMobile,
    required this.onMenuTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryRed,
      elevation: 3,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Menú',
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: onMenuTap,
              ),
              const SizedBox(width: 4),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.restaurant_menu, color: AppColors.primaryRed, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'KROSTY-SADO',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.6),
                    ),
                    if (!isMobile)
                      const Text('Sistema de gestión', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SyncStatusChip(),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'Cuenta',
                offset: const Offset(0, 48),
                onSelected: (value) {
                  if (value == 'logout') onLogout();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(userName,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: AppColors.primaryRed),
                        SizedBox(width: 10),
                        Text('Cerrar sesión'),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: [
                      _Avatar(name: userName),
                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// SIDEBAR (menú lateral con módulos desplegables y navegación real)
// =====================================================================
class _Sidebar extends StatelessWidget {
  final List<SideModule> modules;
  final ValueChanged<SideNavItem> onSelect;
  final String userName;
  final VoidCallback onLogout;
  const _Sidebar({
    required this.modules,
    required this.onSelect,
    required this.userName,
    required this.onLogout,
  });

  // En mobile el sidebar vive dentro de un Drawer: hay que cerrarlo
  // antes de navegar para no dejarlo abierto sobre la nueva pantalla.
  void _closeDrawer(BuildContext context) {
    if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inDrawer = Scaffold.of(context).hasDrawer;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.rowDivider)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryRed, AppColors.primaryRedDark],
              ),
            ),
            child: SafeArea(
              bottom: false,
              // Dentro del drawer la cabecera llega hasta la barra de estado;
              // en escritorio queda debajo de la barra superior.
              top: inDrawer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(name: userName, radius: 26),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    const Text('Sesión activa', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text('MÓDULOS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: _DashPalette.textGray)),
                ),
                for (final module in modules)
                  module.children.isEmpty
                      ? ListTile(
                          leading: Icon(module.icon, color: _DashPalette.textGray, size: 22),
                          title: Text(module.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _DashPalette.textGray)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Pronto', style: TextStyle(fontSize: 11, color: _DashPalette.textGray)),
                          ),
                          enabled: false,
                        )
                      : ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: Icon(module.icon, color: AppColors.primaryRed, size: 22),
                          iconColor: AppColors.primaryRed,
                          collapsedIconColor: _DashPalette.textGray,
                          textColor: AppColors.primaryRed,
                          collapsedTextColor: AppColors.textPrimary,
                          title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          children: [
                            for (final item in module.children)
                              ListTile(
                                contentPadding: const EdgeInsets.only(left: 56, right: 16),
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: Icon(item.icon, size: 19, color: _DashPalette.textGray),
                                title: Text(item.label, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
                                onTap: () {
                                  _closeDrawer(context);
                                  onSelect(item);
                                },
                              ),
                          ],
                        ),
              ],
            ),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.primaryRed),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
              onTap: () {
                _closeDrawer(context);
                onLogout();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// CUERPO DEL DASHBOARD (tarjetas de resumen + secciones por módulo)
// =====================================================================
class _DashboardBody extends StatelessWidget {
  final List<SideModule> modules;
  final ValueChanged<SideNavItem> onSelect;
  final bool isMobile;
  final String userName;
  const _DashboardBody({
    required this.modules,
    required this.onSelect,
    required this.isMobile,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final usuarios = context.watch<UsuarioProvider>().usuarios;
    final clientes = context.watch<ClienteProvider>().clientes;
    final productos = context.watch<ProductoProvider>().productos;
    final ventas = context.watch<VentaProvider>().ventas;

    final now = DateTime.now();
    double totalMes(int mesOffset) {
      final target = DateTime(now.year, now.month + mesOffset, 1);
      return ventas
          .where((v) {
            final fecha = DateTime.tryParse(v.fechaVenta);
            return fecha != null && fecha.year == target.year && fecha.month == target.month;
          })
          .fold(0.0, (sum, v) => sum + v.total);
    }

    final ventasEsteMes = totalMes(0);
    final ventasMesAnterior = totalMes(-1);
    String? variacionVentas;
    bool variacionPositiva = true;
    if (ventasMesAnterior > 0) {
      final delta = ((ventasEsteMes - ventasMesAnterior) / ventasMesAnterior) * 100;
      variacionPositiva = delta >= 0;
      variacionVentas = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}% vs mes anterior';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, ${userName.split(' ').first}',
          style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Resumen general del sistema.',
          style: TextStyle(color: _DashPalette.textGray),
        ),
        SizedBox(height: isMobile ? 16 : 20),

        // ---------- Tarjetas de resumen ----------
        LayoutBuilder(builder: (context, constraints) {
          final crossAxisCount = isMobile ? 2 : (constraints.maxWidth ~/ 240).clamp(1, 4);
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: isMobile ? 12 : 16,
            crossAxisSpacing: isMobile ? 12 : 16,
            childAspectRatio: isMobile ? 1.05 : 1.7,
            children: [
              _StatCard(
                icon: Icons.people_outline,
                title: 'Usuarios',
                value: '${usuarios.length}',
                subtitle: 'Total registrados',
                highlighted: true,
              ),
              _StatCard(
                icon: Icons.person_pin_outlined,
                title: 'Clientes',
                value: '${clientes.length}',
                subtitle: 'Total registrados',
                iconColor: AppColors.primaryRed,
              ),
              _StatCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Productos',
                value: '${productos.length}',
                subtitle: 'En catálogo',
                iconColor: AppColors.accentGreen,
              ),
              _StatCard(
                icon: Icons.payments_outlined,
                title: 'Ventas del mes',
                value: 'Bs ${ventasEsteMes.toStringAsFixed(2)}',
                subtitle: variacionVentas ?? 'Sin datos del mes anterior',
                subtitleColor: variacionVentas == null
                    ? _DashPalette.textGray
                    : (variacionPositiva ? AppColors.accentGreen : AppColors.primaryRed),
                iconColor: const Color(0xFFB8860B),
              ),
            ],
          );
        }),
        const SizedBox(height: 28),

        // ---------- Secciones por módulo ----------
        for (final module in modules.where((m) => m.children.isNotEmpty)) ...[
          _SectionHeader(title: module.title, icon: module.icon),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = isMobile ? 2 : (constraints.maxWidth ~/ 260).clamp(1, 4);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: isMobile ? 12 : 14,
              crossAxisSpacing: isMobile ? 12 : 14,
              childAspectRatio: isMobile ? 0.85 : 2.4,
              children: [
                for (final item in module.children)
                  _ModuleCard(item: item, compact: isMobile, onTap: () => onSelect(item)),
              ],
            );
          }),
          SizedBox(height: isMobile ? 24 : 28),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: AppColors.primaryRed, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final SideNavItem item;
  final VoidCallback onTap;
  /// En mobile la tarjeta es vertical (ícono arriba) para caber en dos columnas.
  final bool compact;
  const _ModuleCard({required this.item, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(item.icon, color: AppColors.primaryRed, size: 22),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        // Flexible: la descripción usa sólo el alto que sobra y se recorta,
        // así un título de 2 líneas o letra grande no provocan overflow.
        Flexible(
          child: Text(
            item.description,
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.3, color: _DashPalette.textGray),
          ),
        ),
      ],
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.rowDivider),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [iconBox, const SizedBox(height: 10), Expanded(child: texts)],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconBox,
                    const SizedBox(width: 12),
                    Expanded(child: texts),
                    const Icon(Icons.chevron_right, color: _DashPalette.textGray),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color? subtitleColor;
  final Color iconColor;
  final bool highlighted;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.subtitleColor,
    this.iconColor = AppColors.primaryRed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted ? AppColors.primaryRed : Colors.white;
    final fg = highlighted ? Colors.white : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: highlighted ? null : Border.all(color: AppColors.rowDivider),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: highlighted ? Colors.white.withValues(alpha: 0.2) : iconColor.withValues(alpha: 0.12),
                child: Icon(icon, size: 18, color: highlighted ? Colors.white : iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: fg)),
              ),
            ],
          ),
          // FittedBox: montos largos ("Bs 12345.00") se achican en vez de desbordar.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg)),
          ),
          Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: subtitleColor ?? (highlighted ? Colors.white70 : _DashPalette.textGray))),
        ],
      ),
    );
  }
}
