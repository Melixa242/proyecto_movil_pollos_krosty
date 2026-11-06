import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parametrizacion/tipo_producto.dart';
import '../../providers/parametrizacion/tipo_product_provider.dart';
import '../pretty_crud_screen.dart';

class TiposProductoScreen extends StatefulWidget {
  const TiposProductoScreen({super.key});

  @override
  State<TiposProductoScreen> createState() => _TiposProductoScreenState();
}

class _TiposProductoScreenState extends State<TiposProductoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<TipoProductProvider>().fetchTiposProducto();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<TipoProductProvider>();
    final tipo = await showTipoProductoFormDialog(context);
    if (tipo == null || !mounted) return;
    final ok = await provider.createTipoProducto(tipo);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Tipo de producto creado' : 'Error al crear tipo')));
  }

  Future<void> _editar(TipoProducto tipo) async {
    final provider = context.read<TipoProductProvider>();
    final updated = await showTipoProductoFormDialog(context, tipoProducto: tipo);
    if (updated == null || !mounted) return;
    final ok = await provider.updateTipoProducto(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Tipo actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(TipoProducto tipo) async {
    if (!await confirmDelete(context, entity: 'este tipo de producto') || !mounted) return;
    final ok = await context.read<TipoProductProvider>().deleteTipoProducto(tipo.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Tipo eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TipoProductProvider>();
    return PrettyCrudScreen<TipoProducto>(
      title: 'Tipos de Producto',
      subtitle: 'Listado de tipos de producto registrados.',
      searchHint: 'Buscar por nombre o descripción',
      newButtonLabel: 'Nuevo tipo',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<TipoProductProvider>().fetchTiposProducto(),
      items: provider.tiposProducto,
      matches: (t, query) =>
          t.nombre.toLowerCase().contains(query) || t.descripcion.toLowerCase().contains(query),
      columns: [
        PrettyColumn(label: 'Nombre', flex: 2, value: (t) => t.nombre),
        PrettyColumn(label: 'Descripción', flex: 3, value: (t) => t.descripcion),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<TipoProducto?> showTipoProductoFormDialog(BuildContext context,
    {TipoProducto? tipoProducto}) {
  final nombreCtrl = TextEditingController(text: tipoProducto?.nombre ?? '');
  final descripcionCtrl =
      TextEditingController(text: tipoProducto?.descripcion ?? '');

  return showDialog<TipoProducto>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(tipoProducto == null
            ? 'Nuevo tipo de producto'
            : 'Editar tipo de producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nombreCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 8),
              TextField(
                  controller: descripcionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              final descripcion = descripcionCtrl.text.trim();

              if (nombre.isEmpty) return;

              Navigator.of(context).pop(TipoProducto(
                  id: tipoProducto?.id,
                  nombre: nombre,
                  descripcion: descripcion));
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
