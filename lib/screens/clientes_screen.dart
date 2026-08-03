import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cliente.dart';
import '../providers/cliente_provider.dart';
import '../screens/app_colors.dart';
import '../screens/custom_button.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}
//

class _ClientesScreenState extends State<ClientesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Carga los clientes desde la API al abrir la pantalla.
    Future.microtask(() {
      if (!mounted) return;
      context.read<ClienteProvider>().fetchClientes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  List<Cliente> _filter(List<Cliente> clientes) {
    if (_query.isEmpty) return clientes;
    return clientes
        .where((c) =>
    c.nombre.toLowerCase().contains(_query) ||
        c.telefono.contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteProvider>();
    final visible = _filter(provider.clientes);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botón para volver al Dashboard.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Volver'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Clientes',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary)),
                            SizedBox(height: 4),
                            Text('Listado de clientes registrados.',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      AppButton(
                        label: 'Nuevo cliente',
                        icon: Icons.add,
                        onPressed: () async {
                          final provider = context.read<ClienteProvider>();
                          final Cliente? created = await showClienteFormDialog(context);
                          if (created != null) {
                            final ok = await provider.createCliente(created);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ok ? 'Cliente creado' : 'Error al crear cliente')));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SearchCard(
                    hint: 'Buscar por nombre o teléfono',
                    controller: _searchController,
                    onSearch: _runSearch,
                    onClear: _clearSearch,
                  ),
                  const SizedBox(height: 20),
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (provider.error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryRed),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.primaryRed),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(provider.error!,
                                style: const TextStyle(
                                    color: AppColors.primaryRed)),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.read<ClienteProvider>().fetchClientes(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  else
                    _ClientesTable(rows: visible),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _SearchCard({
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
                onSubmitted: (_) => onSearch(),
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

Future<Cliente?> showClienteFormDialog(BuildContext context, {Cliente? cliente}) {
  final nombreCtrl = TextEditingController(text: cliente?.nombre ?? '');
  final telefonoCtrl = TextEditingController(text: cliente?.telefono ?? '');
  final estadoCtrl = TextEditingController(text: cliente?.estado ?? '');
  return showDialog<Cliente>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(cliente == null ? 'Nuevo cliente' : 'Editar cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 8),
              TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 8),
              TextField(controller: estadoCtrl, decoration: const InputDecoration(labelText: 'Estado')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              final telefono = telefonoCtrl.text.trim();
              final estado = estadoCtrl.text.trim();
              if (nombre.isEmpty) return;
              Navigator.of(context).pop(Cliente(id: cliente?.id, nombre: nombre, telefono: telefono, estado: estado));
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}

class _ClientesTable extends StatelessWidget {
  final List<Cliente> rows;
  const _ClientesTable({required this.rows});

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

          child: SizedBox(
            width: 880,
            child: Column(
              children: [
                _headerRow(),
                if (rows.isEmpty)
                  _emptyRow()
                else
                  ...List.generate(
                      rows.length, (i) => _dataRow(context, i + 1, rows[i])),
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
          Expanded(flex: 2, child: Text('Teléfono', style: _headerStyle)),
          SizedBox(
              width: 230,
              child:
              Text('Acciones', textAlign: TextAlign.right, style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _dataRow(BuildContext context, int numero, Cliente c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.rowDivider))),
      child: Row(
        children: [
          SizedBox(
              width: 36,
              child: Text('$numero',
                  style: const TextStyle(color: AppColors.textPrimary))),
          Expanded(
              flex: 3,
              child: Text(c.nombre,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
          Expanded(
              flex: 2,
              child: Text(c.telefono,
                  style: const TextStyle(color: AppColors.textSecondary))),
          SizedBox(
            width: 230,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                    label: 'Ver', variant: ButtonVariant.outline, onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cliente'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nombre: ${c.nombre}'),
                              Text('Teléfono: ${c.telefono}'),
                              Text('Estado: ${c.estado}'),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))
                          ],
                        ),
                      );
                    }),
                const SizedBox(width: 8),
                AppButton(
                    label: 'Editar',
                    variant: ButtonVariant.outlineGreen,
                    onPressed: () async {
                      final provider = context.read<ClienteProvider>();
                      final Cliente? updated = await showClienteFormDialog(context, cliente: c);
                      if (updated != null) {
                        final ok = await provider.updateCliente(updated);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Cliente actualizado' : 'Error al actualizar')));
                      }
                    }),
                const SizedBox(width: 8),
                AppButton(
                    label: 'Eliminar',
                    variant: ButtonVariant.danger,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirmar'),
                          content: const Text('¿Eliminar este cliente?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sí')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final ok = await context.read<ClienteProvider>().deleteCliente(c.id!);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Cliente eliminado' : 'Error al eliminar')));
                      }
                    }),
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
        child: Text('No se encontraron clientes.',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}