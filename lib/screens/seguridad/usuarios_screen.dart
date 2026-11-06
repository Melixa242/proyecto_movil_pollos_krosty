import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/seguridad/usuario.dart';
import '../../providers/seguridad/usuario_provider.dart';
import '../pretty_crud_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<UsuarioProvider>().fetchUsuarios();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<UsuarioProvider>();
    final usuario = await _showUsuarioFormDialog(context);
    if (usuario == null || !mounted) return;
    final ok = await provider.createUsuario(usuario);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Usuario creado' : 'Error al crear usuario')));
  }

  Future<void> _editar(Usuario usuario) async {
    final provider = context.read<UsuarioProvider>();
    final updated = await _showUsuarioFormDialog(context, usuario: usuario);
    if (updated == null || !mounted) return;
    final ok = await provider.updateUsuario(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Usuario actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(Usuario usuario) async {
    if (!await confirmDelete(context, entity: 'este usuario') || !mounted) return;
    final ok = await context.read<UsuarioProvider>().deleteUsuario(usuario.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Usuario eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();
    return PrettyCrudScreen<Usuario>(
      title: 'Usuarios',
      subtitle: 'Listado de usuarios registrados.',
      searchHint: 'Buscar por nombre o correo',
      newButtonLabel: 'Nuevo usuario',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<UsuarioProvider>().fetchUsuarios(),
      items: provider.usuarios,
      matches: (item, query) => '${item.nombre} ${item.email}'.toLowerCase().contains(query),
      columns: [
        PrettyColumn(label: 'Nombre', flex: 2, value: (u) => u.nombre),
        PrettyColumn(label: 'Correo', flex: 2, value: (u) => u.email),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<Usuario?> _showUsuarioFormDialog(BuildContext context, {Usuario? usuario}) {
  final isEditing = usuario != null;
  final nombreCtrl = TextEditingController(text: usuario?.nombre ?? '');
  final emailCtrl = TextEditingController(text: usuario?.email ?? '');
  final passwordCtrl = TextEditingController();

  return showDialog<Usuario>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(isEditing ? 'Editar usuario' : 'Nuevo usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: isEditing ? 'Contraseña (opcional)' : 'Contraseña'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              final email = emailCtrl.text.trim();
              final password = passwordCtrl.text;
              if (nombre.isEmpty || email.isEmpty) return;
              if (!isEditing && password.isEmpty) return;
              Navigator.of(context).pop(Usuario(id: usuario?.id, nombre: nombre, email: email, password: password));
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
