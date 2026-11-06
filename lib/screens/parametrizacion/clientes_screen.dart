import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parametrizacion/cliente.dart';
import '../../providers/parametrizacion/cliente_provider.dart';
import '../pretty_crud_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  @override
  void initState() {
    super.initState();
    // Carga los clientes desde la API al abrir la pantalla.
    Future.microtask(() {
      if (!mounted) return;
      context.read<ClienteProvider>().fetchClientes();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<ClienteProvider>();
    final cliente = await showClienteFormDialog(context);
    if (cliente == null || !mounted) return;
    final ok = await provider.createCliente(cliente);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Cliente creado' : 'Error al crear cliente')));
  }

  Future<void> _editar(Cliente cliente) async {
    final provider = context.read<ClienteProvider>();
    final updated = await showClienteFormDialog(context, cliente: cliente);
    if (updated == null || !mounted) return;
    final ok = await provider.updateCliente(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Cliente actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(Cliente cliente) async {
    if (!await confirmDelete(context, entity: 'este cliente') || !mounted) return;
    final ok = await context.read<ClienteProvider>().deleteCliente(cliente.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Cliente eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteProvider>();
    return PrettyCrudScreen<Cliente>(
      title: 'Clientes',
      subtitle: 'Listado de clientes registrados.',
      searchHint: 'Buscar por nombre o teléfono',
      newButtonLabel: 'Nuevo cliente',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<ClienteProvider>().fetchClientes(),
      items: provider.clientes,
      matches: (c, query) => c.nombre.toLowerCase().contains(query) || c.telefono.contains(query),
      columns: [
        PrettyColumn(label: 'Nombre', flex: 3, value: (c) => c.nombre),
        PrettyColumn(label: 'Teléfono', flex: 2, value: (c) => c.telefono),
        PrettyColumn(label: 'Estado', flex: 1, value: (c) => c.estado),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
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
