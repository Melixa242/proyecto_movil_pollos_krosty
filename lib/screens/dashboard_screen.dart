import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'clientes_screen.dart';

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

// ----------------------- PALETA DE COLORES -----------------------
class AppColors {
  static const Color primaryRed = Color(0xFFB71C1C); // rojo botones / títulos
  static const Color darkRed = Color(0xFF8E0000); // hover / acento oscuro
  static const Color sidebarBg = Color(0xFFF5EDED); // fondo lateral rosado claro
  static const Color pageBg = Color(0xFFF0EDED); // fondo general
  static const Color textGray = Color(0xFF555555);
  static const Color borderRed = Color(0xFFB71C1C);
}

// ----------------------- MODELO DE MÓDULO LATERAL -----------------------
class SideModule {
  final String title;
  final IconData icon;
  final List<String>? children; // submódulos (si aplica)
  const SideModule({required this.title, required this.icon, this.children});
}

// ----------------------- MODELO DE ACCESO RÁPIDO (botón rojo) -----------------------
class QuickAccess {
  final String label;
  final VoidCallback? onTap;
  const QuickAccess({required this.label, this.onTap});
}

class DashboardScreen extends StatefulWidget {
  final String userName;
  const DashboardScreen({super.key, this.userName = 'USUARIO'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _sidebarOpen = true;

  // ----------------------- DATA: módulos del menú lateral -----------------------
  final List<SideModule> _modules = const [
    SideModule(
      title: 'MODULO DE ACCESO Y SEGURIDAD',
      icon: Icons.shield_outlined,
    ),
    SideModule(
      title: 'MODULO DE PARAMETRIZACION',
      icon: Icons.tune,
    ),
    SideModule(
      title: 'MODULO DE TRANSACCIONALES',
      icon: Icons.shopping_cart_outlined,
    ),
    SideModule(
      title: 'MODULO DE REPORTES',
      icon: Icons.show_chart,
    ),
  ];

  // ----------------------- DATA: accesos rápidos (botones rojos) -----------------------
  List<QuickAccess> get _quickAccess => [
    QuickAccess(label: 'Usuarios', onTap: () => _go('Usuarios')),
    QuickAccess(label: 'Roles', onTap: () => _go('Roles')),
    QuickAccess(label: 'Asignación de roles', onTap: () => _go('Asignación de roles')),
    QuickAccess(
      label: 'Clientes',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ClientesScreen()),
      ),
    ),
    QuickAccess(label: 'Unidades de medida', onTap: () => _go('Unidades de medida')),
    QuickAccess(label: 'Insumos', onTap: () => _go('Insumos')),
    QuickAccess(label: 'Ingresos de insumos', onTap: () => _go('Ingresos de insumos')),
    QuickAccess(label: 'Productos', onTap: () => _go('Productos')),
    QuickAccess(label: 'Producto-Composición', onTap: () => _go('Producto-Composición')),
    QuickAccess(label: 'Reglas de conversión', onTap: () => _go('Reglas de conversión')),
    QuickAccess(label: 'Tipo de productos', onTap: () => _go('Tipo de productos')),
    QuickAccess(label: 'Orden de producción', onTap: () => _go('Orden de producción')),
    QuickAccess(label: 'Producción', onTap: () => _go('Producción')),
    QuickAccess(label: 'Ventas', onTap: () => _go('Ventas')),
  ];

  void _go(String moduleName) {
    // TODO: navegar a la pantalla real del módulo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ir a: $moduleName'), duration: const Duration(seconds: 1)),
    );
  }

  void _logout() {
    // Limpia el token y el estado; AuthWrapper detecta el cambio
    // y vuelve automáticamente a la pantalla de login.
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      drawer: isMobile ? Drawer(child: _Sidebar(modules: _modules)) : null,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              userName: widget.userName,
              isMobile: isMobile,
              onMenuTap: () {
                if (isMobile) {
                  Scaffold.of(context).openDrawer();
                } else {
                  setState(() => _sidebarOpen = !_sidebarOpen);
                }
              },
              onLogout: _logout,
            ),
            const Divider(height: 1, color: AppColors.primaryRed, thickness: 2),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile && _sidebarOpen)
                    SizedBox(
                      width: 260,
                      child: _Sidebar(modules: _modules),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _DashboardBody(
                        quickAccess: _quickAccess,
                        isMobile: isMobile,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primaryRed),
            onPressed: onMenuTap,
          ),
          if (!isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'SISTEMA WEB KROSTY-SADO',
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Dashboard',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
              ],
            ),
          const Spacer(),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Colors.black26),
            ),
            onPressed: () {},
            child: const Text('Dashboard'),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            offset: const Offset(0, 45),
            onSelected: (value) {
              if (value == 'logout') onLogout();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Mi perfil')),
              const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
            ],
            child: Row(
              children: [
                if (!isMobile)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// SIDEBAR (menú lateral con módulos)
// =====================================================================
class _Sidebar extends StatelessWidget {
  final List<SideModule> modules;
  const _Sidebar({required this.modules});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBg,
      height: double.infinity,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'SISTEMA WEB\nKROSTY-SADO',
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final module in modules)
            ListTile(
              leading: Icon(module.icon, color: AppColors.primaryRed, size: 20),
              title: Text(
                module.title,
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              onTap: () {},
            ),
        ],
      ),
    );
  }
}

// =====================================================================
// CUERPO DEL DASHBOARD (tarjeta de bienvenida + grilla de accesos)
// =====================================================================
class _DashboardBody extends StatelessWidget {
  final List<QuickAccess> quickAccess;
  final bool isMobile;
  const _DashboardBody({required this.quickAccess, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Accesos rápidos a los módulos principales del sistema.',
          style: TextStyle(color: AppColors.textGray),
        ),
        const SizedBox(height: 20),

        // ---------- Tarjeta de bienvenida ----------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Bienvenido al panel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Selecciona un módulo para gestionar tu información.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                ),
                onPressed: () {},
                child: const Text('Mi perfil'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ---------- Grilla de accesos rápidos (botones rojos) ----------
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = isMobile ? 1 : (constraints.maxWidth ~/ 320).clamp(1, 3);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickAccess.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 5.2,
              ),
              itemBuilder: (context, index) {
                final item = quickAccess[index];
                return _QuickAccessButton(item: item);
              },
            );
          },
        ),
      ],
    );
  }
}

// =====================================================================
// BOTÓN ROJO DE ACCESO RÁPIDO
// =====================================================================
class _QuickAccessButton extends StatefulWidget {
  final QuickAccess item;
  const _QuickAccessButton({required this.item});

  @override
  State<_QuickAccessButton> createState() => _QuickAccessButtonState();
}

class _QuickAccessButtonState extends State<_QuickAccessButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: _hover ? AppColors.darkRed : AppColors.primaryRed,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: widget.item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}