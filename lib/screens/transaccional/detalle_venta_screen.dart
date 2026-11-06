import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/detalle_venta.dart';
import '../../providers/transaccional/detalle_venta_provider.dart';
import '../pretty_crud_screen.dart';

class DetalleVentaScreen extends StatefulWidget {
  const DetalleVentaScreen({super.key});

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<DetalleVentaProvider>().fetchDetalles();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<DetalleVentaProvider>();
    final detalle = await _showDetalleVentaFormDialog(context);
    if (detalle == null || !mounted) return;
    final ok = await provider.createDetalle(detalle);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle creado' : 'Error al crear detalle')));
  }

  Future<void> _editar(DetalleVenta detalle) async {
    final provider = context.read<DetalleVentaProvider>();
    final updated = await _showDetalleVentaFormDialog(context, detalle: detalle);
    if (updated == null || !mounted) return;
    final ok = await provider.updateDetalle(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(DetalleVenta detalle) async {
    if (!await confirmDelete(context, entity: 'este detalle') || !mounted) return;
    final ok = await context.read<DetalleVentaProvider>().deleteDetalle(detalle.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DetalleVentaProvider>();
    return PrettyCrudScreen<DetalleVenta>(
      title: 'Detalle de ventas',
      subtitle: 'Listado de detalles de venta registrados.',
      searchHint: 'Buscar por venta o producto',
      newButtonLabel: 'Nuevo detalle',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<DetalleVentaProvider>().fetchDetalles(),
      items: provider.detalles,
      matches: (item, query) =>
          '${item.ventaId}'.contains(query) || '${item.productoId}'.contains(query),
      columns: [
        PrettyColumn(label: 'Venta ID', value: (d) => '${d.ventaId}'),
        PrettyColumn(label: 'Producto ID', value: (d) => '${d.productoId}'),
        PrettyColumn(label: 'Precio Unitario', value: (d) => d.precioUnitario.toStringAsFixed(2)),
        PrettyColumn(label: 'Cantidad', value: (d) => d.cantidad.toStringAsFixed(2)),
        PrettyColumn(label: 'Subtotal', value: (d) => d.subTotal.toStringAsFixed(2)),
        PrettyColumn(label: 'Estado', value: (d) => '${d.estado}'),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<DetalleVenta?> _showDetalleVentaFormDialog(BuildContext context, {DetalleVenta? detalle}) {
  final ventaIdCtrl = TextEditingController(text: detalle?.ventaId.toString() ?? '');
  final productoIdCtrl = TextEditingController(text: detalle?.productoId.toString() ?? '');
  final precioUnitarioCtrl = TextEditingController(text: detalle?.precioUnitario.toString() ?? '');
  final cantidadCtrl = TextEditingController(text: detalle?.cantidad.toString() ?? '');
  final subTotalCtrl = TextEditingController(text: detalle?.subTotal.toString() ?? '');
  final estadoCtrl = TextEditingController(text: detalle?.estado.toString() ?? '1');

  return showDialog<DetalleVenta>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(detalle == null ? 'Nuevo detalle' : 'Editar detalle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ventaIdCtrl,
                decoration: const InputDecoration(labelText: 'Venta ID'),
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
                controller: precioUnitarioCtrl,
                decoration: const InputDecoration(labelText: 'Precio Unitario'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cantidadCtrl,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subTotalCtrl,
                decoration: const InputDecoration(labelText: 'Subtotal'),
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
              final ventaId = int.tryParse(ventaIdCtrl.text.trim());
              final productoId = int.tryParse(productoIdCtrl.text.trim());
              final precioUnitario = double.tryParse(precioUnitarioCtrl.text.trim());
              final cantidad = double.tryParse(cantidadCtrl.text.trim());
              final subTotal = double.tryParse(subTotalCtrl.text.trim());
              final estado = int.tryParse(estadoCtrl.text.trim()) ?? 1;
              if (ventaId == null || productoId == null || precioUnitario == null || cantidad == null || subTotal == null) {
                return;
              }

              Navigator.of(context).pop(DetalleVenta(
                id: detalle?.id,
                ventaId: ventaId,
                productoId: productoId,
                precioUnitario: precioUnitario,
                cantidad: cantidad,
                subTotal: subTotal,
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
