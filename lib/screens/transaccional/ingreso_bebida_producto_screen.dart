import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/ingreso_bebida_producto.dart';
import '../../providers/transaccional/ingreso_bebida_producto_provider.dart';
import '../pretty_crud_screen.dart';

class IngresoBebidaProductoScreen extends StatefulWidget {
  const IngresoBebidaProductoScreen({super.key});

  @override
  State<IngresoBebidaProductoScreen> createState() => _IngresoBebidaProductoScreenState();
}

class _IngresoBebidaProductoScreenState extends State<IngresoBebidaProductoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<IngresoBebidaProductoProvider>().fetchDetalles();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<IngresoBebidaProductoProvider>();
    final detalle = await _showIngresoBebidaProductoFormDialog(context);
    if (detalle == null || !mounted) return;
    final ok = await provider.createDetalle(detalle);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle creado' : 'Error al crear detalle')));
  }

  Future<void> _editar(IngresoBebidaProducto detalle) async {
    final provider = context.read<IngresoBebidaProductoProvider>();
    final updated = await _showIngresoBebidaProductoFormDialog(context, detalle: detalle);
    if (updated == null || !mounted) return;
    final ok = await provider.updateDetalle(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(IngresoBebidaProducto detalle) async {
    if (!await confirmDelete(context, entity: 'este detalle') || !mounted) return;
    final ok = await context.read<IngresoBebidaProductoProvider>().deleteDetalle(detalle.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngresoBebidaProductoProvider>();
    return PrettyCrudScreen<IngresoBebidaProducto>(
      title: 'Detalle de ingreso de bebidas',
      subtitle: 'Listado de detalles de ingreso de bebidas registrados.',
      searchHint: 'Buscar por producto o ingreso',
      newButtonLabel: 'Nuevo detalle',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<IngresoBebidaProductoProvider>().fetchDetalles(),
      items: provider.detalles,
      matches: (item, query) =>
          '${item.ingresoBebidaId}'.contains(query) || '${item.productoId}'.contains(query),
      columns: [
        PrettyColumn(label: 'Ingreso Bebida ID', value: (d) => '${d.ingresoBebidaId}'),
        PrettyColumn(label: 'Producto ID', value: (d) => '${d.productoId}'),
        PrettyColumn(label: 'Cantidad', value: (d) => d.cantidadIngresa.toStringAsFixed(2)),
        PrettyColumn(label: 'Precio', value: (d) => d.precio.toStringAsFixed(2)),
        PrettyColumn(label: 'Estado', value: (d) => '${d.estado}'),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<IngresoBebidaProducto?> _showIngresoBebidaProductoFormDialog(BuildContext context,
    {IngresoBebidaProducto? detalle}) {
  final ingresoBebidaIdCtrl =
      TextEditingController(text: detalle?.ingresoBebidaId.toString() ?? '');
  final productoIdCtrl = TextEditingController(text: detalle?.productoId.toString() ?? '');
  final cantidadCtrl = TextEditingController(text: detalle?.cantidadIngresa.toString() ?? '');
  final precioCtrl = TextEditingController(text: detalle?.precio.toString() ?? '');
  final estadoCtrl = TextEditingController(text: detalle?.estado.toString() ?? '1');

  return showDialog<IngresoBebidaProducto>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(detalle == null ? 'Nuevo detalle' : 'Editar detalle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ingresoBebidaIdCtrl,
                decoration: const InputDecoration(labelText: 'Ingreso Bebida ID'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: productoIdCtrl,
                decoration: const InputDecoration(labelText: 'Producto ID'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cantidadCtrl,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: precioCtrl,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: estadoCtrl,
                decoration: const InputDecoration(labelText: 'Estado'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final ingresoBebidaId = int.tryParse(ingresoBebidaIdCtrl.text.trim());
              final productoId = int.tryParse(productoIdCtrl.text.trim());
              final cantidad = double.tryParse(cantidadCtrl.text.trim());
              final precio = double.tryParse(precioCtrl.text.trim());
              final estado = int.tryParse(estadoCtrl.text.trim()) ?? 1;
              if (ingresoBebidaId == null || productoId == null || cantidad == null || precio == null) {
                return;
              }

              Navigator.of(context).pop(IngresoBebidaProducto(
                id: detalle?.id,
                ingresoBebidaId: ingresoBebidaId,
                productoId: productoId,
                cantidadIngresa: cantidad,
                precio: precio,
                estado: estado,
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
