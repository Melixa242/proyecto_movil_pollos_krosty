import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/seguridad/rol.dart';
import '../../providers/seguridad/rol_provider.dart';
import '../pretty_crud_screen.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<RolProvider>().fetchRoles();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<RolProvider>();
    final rol = await _showRolFormDialog(context);
    if (rol == null || !mounted) return;
    final ok = await provider.createRol(rol);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Rol creado' : 'Error al crear rol')));
  }

  Future<void> _editar(Rol rol) async {
    final provider = context.read<RolProvider>();
    final updated = await _showRolFormDialog(context, rol: rol);
    if (updated == null || !mounted) return;
    final ok = await provider.updateRol(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Rol actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(Rol rol) async {
    if (!await confirmDelete(context, entity: 'este rol') || !mounted) return;
    final ok = await context.read<RolProvider>().deleteRol(rol.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Rol eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RolProvider>();
    return PrettyCrudScreen<Rol>(
      title: 'Roles',
      subtitle: 'Listado de roles registrados.',
      searchHint: 'Buscar por nombre',
      newButtonLabel: 'Nuevo rol',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<RolProvider>().fetchRoles(),
      items: provider.roles,
      matches: (item, query) => item.nombre.toLowerCase().contains(query),
      columns: [
        PrettyColumn(label: 'Nombre', flex: 2, value: (r) => r.nombre),
        PrettyColumn(label: 'Guard', flex: 1, value: (r) => r.guardName),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<Rol?> _showRolFormDialog(BuildContext context, {Rol? rol}) {
  final nombreCtrl = TextEditingController(text: rol?.nombre ?? '');
  final guardCtrl = TextEditingController(text: rol?.guardName ?? 'web');

  return showDialog<Rol>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(rol == null ? 'Nuevo rol' : 'Editar rol'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 8),
              TextField(controller: guardCtrl, decoration: const InputDecoration(labelText: 'Guard name')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              if (nombre.isEmpty) return;
              Navigator.of(context).pop(Rol(id: rol?.id, nombre: nombre, guardName: guardCtrl.text.trim()));
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
