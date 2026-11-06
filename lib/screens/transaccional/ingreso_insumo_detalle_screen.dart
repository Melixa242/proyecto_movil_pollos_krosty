import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/ingreso_insumo_detalle.dart';
import '../../providers/transaccional/ingreso_insumo_detalle_provider.dart';
import '../pretty_crud_screen.dart';

class IngresoInsumoDetalleScreen extends StatefulWidget {
  const IngresoInsumoDetalleScreen({super.key});

  @override
  State<IngresoInsumoDetalleScreen> createState() => _IngresoInsumoDetalleScreenState();
}

class _IngresoInsumoDetalleScreenState extends State<IngresoInsumoDetalleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<IngresoInsumoDetalleProvider>().fetchDetalles();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<IngresoInsumoDetalleProvider>();
    final detalle = await _showIngresoInsumoDetalleFormDialog(context);
    if (detalle == null || !mounted) return;
    final ok = await provider.createDetalle(detalle);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle creado' : 'Error al crear detalle')));
  }

  Future<void> _editar(IngresoInsumoDetalle detalle) async {
    final provider = context.read<IngresoInsumoDetalleProvider>();
    final updated = await _showIngresoInsumoDetalleFormDialog(context, detalle: detalle);
    if (updated == null || !mounted) return;
    final ok = await provider.updateDetalle(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(IngresoInsumoDetalle detalle) async {
    if (!await confirmDelete(context, entity: 'este detalle') || !mounted) return;
    final ok = await context.read<IngresoInsumoDetalleProvider>().deleteDetalle(detalle.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Detalle eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngresoInsumoDetalleProvider>();
    return PrettyCrudScreen<IngresoInsumoDetalle>(
      title: 'Detalle de ingreso de insumos',
      subtitle: 'Listado de detalles de ingreso de insumos registrados.',
      searchHint: 'Buscar por insumo o ingreso',
      newButtonLabel: 'Nuevo detalle',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<IngresoInsumoDetalleProvider>().fetchDetalles(),
      items: provider.detalles,
      matches: (item, query) =>
          '${item.ingresoInsumoId}'.contains(query) || '${item.insumoId}'.contains(query),
      columns: [
        PrettyColumn(label: 'Ingreso Insumo ID', value: (d) => '${d.ingresoInsumoId}'),
        PrettyColumn(label: 'Insumo ID', value: (d) => '${d.insumoId}'),
        PrettyColumn(label: 'Cantidad', value: (d) => d.cantidad.toStringAsFixed(2)),
        PrettyColumn(label: 'Precio Unitario', value: (d) => d.precioUnitario.toStringAsFixed(2)),
        PrettyColumn(label: 'Estado', value: (d) => '${d.estado}'),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<IngresoInsumoDetalle?> _showIngresoInsumoDetalleFormDialog(BuildContext context,
    {IngresoInsumoDetalle? detalle}) {
  final ingresoInsumoIdCtrl =
      TextEditingController(text: detalle?.ingresoInsumoId.toString() ?? '');
  final insumoIdCtrl = TextEditingController(text: detalle?.insumoId.toString() ?? '');
  final cantidadCtrl = TextEditingController(text: detalle?.cantidad.toString() ?? '');
  final precioUnitarioCtrl = TextEditingController(text: detalle?.precioUnitario.toString() ?? '');
  final estadoCtrl = TextEditingController(text: detalle?.estado.toString() ?? '1');

  return showDialog<IngresoInsumoDetalle>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(detalle == null ? 'Nuevo detalle' : 'Editar detalle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ingresoInsumoIdCtrl,
                decoration: const InputDecoration(labelText: 'Ingreso Insumo ID'),
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
                controller: precioUnitarioCtrl,
                decoration: const InputDecoration(labelText: 'Precio Unitario'),
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
              final ingresoInsumoId = int.tryParse(ingresoInsumoIdCtrl.text.trim());
              final insumoId = int.tryParse(insumoIdCtrl.text.trim());
              final cantidad = double.tryParse(cantidadCtrl.text.trim());
              final precioUnitario = double.tryParse(precioUnitarioCtrl.text.trim());
              final estado = int.tryParse(estadoCtrl.text.trim()) ?? 1;
              if (ingresoInsumoId == null || insumoId == null || cantidad == null || precioUnitario == null) {
                return;
              }

              Navigator.of(context).pop(IngresoInsumoDetalle(
                id: detalle?.id,
                ingresoInsumoId: ingresoInsumoId,
                insumoId: insumoId,
                cantidad: cantidad,
                precioUnitario: precioUnitario,
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
