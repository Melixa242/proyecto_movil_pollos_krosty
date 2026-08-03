import 'package:flutter/material.dart';
import '../screens/app_colors.dart';
import '../screens/custom_button.dart';

class _UsuarioRow {
  final int numero;
  final String nombre;
  final String correo;
  final String telefono;
  final String? rol;
  const _UsuarioRow({
    required this.numero,
    required this.nombre,
    required this.correo,
    required this.telefono,
    this.rol,
  });
}

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _searchController = TextEditingController();

  // TODO: reemplazar por la lista que devuelva tu ApiService.getUsuarios().
  final List<_UsuarioRow> _allUsuarios = const [
    _UsuarioRow(
        numero: 1,
        nombre: 'ana melixa tapia',
        correo: 'melixaspotify@gmail.com',
        telefono: '73641022',
        rol: 'administrador'),
    _UsuarioRow(
        numero: 2,
        nombre: 'Test Registro',
        correo: 'test1778380818@example.com',
        telefono: 'N/A',
        rol: null),
    _UsuarioRow(
        numero: 3,
        nombre: 'ana melixa tapia',
        correo: 'melixa21eclipse@gmail.com',
        telefono: 'N/A',
        rol: 'administrador'),
  ];

  List<_UsuarioRow> _visible = const [];

  @override
  void initState() {
    super.initState();
    _visible = _allUsuarios;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _visible = query.isEmpty
          ? _allUsuarios
          : _allUsuarios
              .where((u) =>
                  u.nombre.toLowerCase().contains(query) ||
                  u.correo.toLowerCase().contains(query) ||
                  u.telefono.toLowerCase().contains(query))
              .toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _visible = _allUsuarios);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Administrar Usuario',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary)),
                            SizedBox(height: 4),
                            Text('Administración de cuentas del sistema.',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      AppButton(
                        label: 'Nuevo usuario',
                        icon: Icons.person_add_alt,
                        onPressed: () {
                          // TODO: Navigator.pushNamed(context, '/usuarios/nuevo');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SearchBar(
                    hint: 'Buscar por nombre, correo o teléfono',
                    controller: _searchController,
                    onSearch: _runSearch,
                    onClear: _clearSearch,
                  ),
                  const SizedBox(height: 20),
                  _UsuariosTable(rows: _visible),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _SearchBar({
    required this.hint,
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buscar',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              final field = TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Color(0xFFA1A6B0)),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.borderLight)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.borderLight)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.primaryRed, width: 1.6)),
                ),
              );
              final buttons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(label: 'Buscar', onPressed: onSearch),
                  const SizedBox(width: 10),
                  AppButton(
                      label: 'Limpiar',
                      variant: ButtonVariant.outline,
                      onPressed: onClear),
                ],
              );
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [field, const SizedBox(height: 10), buttons],
                );
              }
              return Row(children: [
                Expanded(child: field),
                const SizedBox(width: 10),
                buttons
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class _UsuariosTable extends StatelessWidget {
  final List<_UsuarioRow> rows;
  const _UsuariosTable({required this.rows});

  static const TextStyle _headerStyle = TextStyle(
      fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 920),
            child: Column(
              children: [
                _headerRow(),
                if (rows.isEmpty) _emptyRow() else ...rows.map(_dataRow),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.tableHeaderBg,
        border: Border(bottom: BorderSide(color: AppColors.rowDivider)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 36, child: Text('#', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Nombre', style: _headerStyle)),
          Expanded(flex: 4, child: Text('Correo', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Teléfono', style: _headerStyle)),
          SizedBox(width: 120, child: Text('Roles', style: _headerStyle)),
          SizedBox(
              width: 160,
              child:
                  Text('Acciones', textAlign: TextAlign.right, style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _dataRow(_UsuarioRow u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.rowDivider))),
      child: Row(
        children: [
          SizedBox(
              width: 36,
              child: Text('${u.numero}',
                  style: const TextStyle(color: AppColors.textPrimary))),
          Expanded(
              flex: 3,
              child: Text(u.nombre,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
          Expanded(
              flex: 4,
              child: Text(u.correo,
                  style: const TextStyle(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(u.telefono,
                  style: const TextStyle(color: AppColors.textSecondary))),
          SizedBox(width: 120, child: _RoleBadge(rol: u.rol)),
          SizedBox(
            width: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                    label: 'Editar',
                    variant: ButtonVariant.outlineGreen,
                    onPressed: () {}),
                const SizedBox(width: 8),
                AppButton(
                    label: 'Eliminar',
                    variant: ButtonVariant.danger,
                    onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text('No se encontraron usuarios para esa búsqueda.',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String? rol;
  const _RoleBadge({required this.rol});

  @override
  Widget build(BuildContext context) {
    if (rol == null) {
      return const Text('Sin rol',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.badgeBackground, borderRadius: BorderRadius.circular(20)),
      child: Text(rol!,
          style: const TextStyle(
              color: AppColors.badgeText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600)),
    );
  }
}
