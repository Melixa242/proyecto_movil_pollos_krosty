import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/orden_produccion_insumo.dart';
import '../../providers/transaccional/orden_produccion_insumo_provider.dart';
import '../pretty_crud_screen.dart';

class OrdenProduccionInsumoScreen extends StatefulWidget {
  const OrdenProduccionInsumoScreen({super.key});

  @override
  State<OrdenProduccionInsumoScreen> createState() => _OrdenProduccionInsumoScreenState();
}

class _OrdenProduccionInsumoScreenState extends State<OrdenProduccionInsumoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<OrdenProduccionInsumoProvider>().fetchDetalles();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<OrdenProduccionInsumoProvider>();
    final detalle = await _showOrdenProduccionInsumoFormDialog(context);
    if (detalle == null || !mounted) return;
    final ok = await provider.createDetalle(detalle);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle creado' : 'Error al crear detalle')));
  }

  Future<void> _editar(OrdenProduccionInsumo detalle) async {
    final provider = context.read<OrdenProduccionInsumoProvider>();
    final updated = await _showOrdenProduccionInsumoFormDialog(context, detalle: detalle);
    if (updated == null || !mounted) return;
    final ok = await provider.updateDetalle(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(OrdenProduccionInsumo detalle) async {
    if (!await confirmDelete(context, entity: 'este detalle') || !mounted) return;
    final ok = await context.read<OrdenProduccionInsumoProvider>().deleteDetalle(detalle.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdenProduccionInsumoProvider>();
    return PrettyCrudScreen<OrdenProduccionInsumo>(
      title: 'Insumos de orden de producción',
      subtitle: 'Listado de insumos de órdenes de producción registrados.',
      searchHint: 'Buscar por orden o insumo',
      newButtonLabel: 'Nuevo detalle',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<OrdenProduccionInsumoProvider>().fetchDetalles(),
      items: provider.detalles,
      matches: (item, query) =>
          '${item.ordenProduccionId}'.contains(query) || '${item.insumoId}'.contains(query),
      columns: [
        PrettyColumn(label: 'Orden Producción ID', value: (d) => '${d.ordenProduccionId}'),
        PrettyColumn(label: 'Insumo ID', value: (d) => '${d.insumoId}'),
        PrettyColumn(label: 'Cantidad', value: (d) => d.cantidad.toStringAsFixed(2)),
        PrettyColumn(label: 'Estado', value: (d) => '${d.estado}'),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<OrdenProduccionInsumo?> _showOrdenProduccionInsumoFormDialog(BuildContext context,
    {OrdenProduccionInsumo? detalle}) {
  final ordenProduccionIdCtrl =
      TextEditingController(text: detalle?.ordenProduccionId.toString() ?? '');
  final insumoIdCtrl = TextEditingController(text: detalle?.insumoId.toString() ?? '');
  final cantidadCtrl = TextEditingController(text: detalle?.cantidad.toString() ?? '');
  final estadoCtrl = TextEditingController(text: detalle?.estado.toString() ?? '1');

  return showDialog<OrdenProduccionInsumo>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(detalle == null ? 'Nuevo detalle' : 'Editar detalle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ordenProduccionIdCtrl,
                decoration: const InputDecoration(labelText: 'Orden Producción ID'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: insumoIdCtrl,
                decoration: const InputDecoration(labelText: 'Insumo ID'),
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
              final ordenProduccionId = int.tryParse(ordenProduccionIdCtrl.text.trim());
              final insumoId = int.tryParse(insumoIdCtrl.text.trim());
              final cantidad = double.tryParse(cantidadCtrl.text.trim());
              final estado = int.tryParse(estadoCtrl.text.trim()) ?? 1;
              if (ordenProduccionId == null || insumoId == null || cantidad == null) return;

              Navigator.of(context).pop(OrdenProduccionInsumo(
                id: detalle?.id,
                ordenProduccionId: ordenProduccionId,
                insumoId: insumoId,
                cantidad: cantidad,
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
