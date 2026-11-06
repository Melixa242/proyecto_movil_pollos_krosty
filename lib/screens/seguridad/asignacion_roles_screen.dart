import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/seguridad/asignacion_rol.dart';
import '../../providers/seguridad/asignacion_rol_provider.dart';
import '../pretty_crud_screen.dart';
import '../selector_api.dart';

class AsignacionRolesScreen extends StatefulWidget {
  const AsignacionRolesScreen({super.key});

  @override
  State<AsignacionRolesScreen> createState() => _AsignacionRolesScreenState();
}

class _AsignacionRolesScreenState extends State<AsignacionRolesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AsignacionRolProvider>().fetchAsignaciones();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<AsignacionRolProvider>();
    final asignacion = await _showAsignacionRolFormDialog(context);
    if (asignacion == null || !mounted) return;
    final ok = await provider.createAsignacion(asignacion);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Asignación creada' : 'Error al crear asignación')));
  }

  Future<void> _editar(AsignacionRol asignacion) async {
    final provider = context.read<AsignacionRolProvider>();
    final updated = await _showAsignacionRolFormDialog(context, asignacion: asignacion);
    if (updated == null || !mounted) return;
    final ok = await provider.updateAsignacion(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Asignación actualizada' : 'Error al actualizar')));
  }

  Future<void> _eliminar(AsignacionRol asignacion) async {
    if (!await confirmDelete(context, entity: 'esta asignación') || !mounted) return;
    final ok = await context.read<AsignacionRolProvider>().deleteAsignacion(asignacion.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Asignación eliminada' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AsignacionRolProvider>();
    return PrettyCrudScreen<AsignacionRol>(
      title: 'Asignación de roles',
      subtitle: 'Listado de asignaciones de roles registradas.',
      searchHint: 'Buscar por usuario o rol',
      newButtonLabel: 'Nueva asignación',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<AsignacionRolProvider>().fetchAsignaciones(),
      items: provider.asignaciones,
      matches: (item, query) =>
          item.userDisplay.toLowerCase().contains(query.toLowerCase()) ||
          item.roleDisplay.toLowerCase().contains(query.toLowerCase()),
      columns: [
        PrettyColumn(label: 'Usuario', value: (a) => a.userDisplay),
        PrettyColumn(label: 'Rol', value: (a) => a.roleDisplay),
        PrettyColumn(label: 'Asignado por', value: (a) => a.assignedByDisplay),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<AsignacionRol?> _showAsignacionRolFormDialog(BuildContext context,
    {AsignacionRol? asignacion}) async {
  final opciones = await Future.wait([
    cargarOpciones('/usuarios'),
    cargarOpciones('/roles'),
  ]);
  if (!context.mounted) return null;
  final usuarios = opciones[0], roles = opciones[1];
  if (usuarios.isEmpty || roles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar usuarios o roles')));
    return null;
  }

  int? userId = asignacion?.userId;
  int? roleId = asignacion?.roleId;
  String? error;

  return showDialog<AsignacionRol>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(asignacion == null ? 'Nueva asignación' : 'Editar asignación'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectorApi(
                      label: 'Usuario',
                      opciones: usuarios,
                      valor: userId,
                      onChanged: (v) => setState(() => userId = v)),
                  const SizedBox(height: 8),
                  SelectorApi(
                      label: 'Rol',
                      opciones: roles,
                      valor: roleId,
                      onChanged: (v) => setState(() => roleId = v)),
                  const SizedBox(height: 12),
                  const Text(
                    'Al guardar, el usuario deberá volver a iniciar sesión para que se apliquen los permisos.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (userId == null || roleId == null) {
                  setState(() => error = 'Seleccioná el usuario y el rol.');
                  return;
                }
                Navigator.of(context).pop(AsignacionRol(
                  id: asignacion?.id,
                  userId: userId!,
                  roleId: roleId!,
                ));
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      });
    },
  );
}
