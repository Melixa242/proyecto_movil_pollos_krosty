import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/venta_pago.dart';
import '../../providers/transaccional/venta_pago_provider.dart';
import '../pretty_crud_screen.dart';

class VentaPagoScreen extends StatefulWidget {
  const VentaPagoScreen({super.key});

  @override
  State<VentaPagoScreen> createState() => _VentaPagoScreenState();
}

class _VentaPagoScreenState extends State<VentaPagoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<VentaPagoProvider>().fetchPagos();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<VentaPagoProvider>();
    final pago = await _showVentaPagoFormDialog(context);
    if (pago == null || !mounted) return;
    final ok = await provider.createPago(pago);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Pago creado' : 'Error al crear pago')));
  }

  Future<void> _editar(VentaPago pago) async {
    final provider = context.read<VentaPagoProvider>();
    final updated = await _showVentaPagoFormDialog(context, pago: pago);
    if (updated == null || !mounted) return;
    final ok = await provider.updatePago(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Pago actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(VentaPago pago) async {
    if (!await confirmDelete(context, entity: 'este pago') || !mounted) return;
    final ok = await context.read<VentaPagoProvider>().deletePago(pago.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Pago eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VentaPagoProvider>();
    return PrettyCrudScreen<VentaPago>(
      title: 'Pagos de venta',
      subtitle: 'Listado de pagos de venta registrados.',
      searchHint: 'Buscar por método de pago',
      newButtonLabel: 'Nuevo pago',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<VentaPagoProvider>().fetchPagos(),
      items: provider.pagos,
      matches: (item, query) => item.metodoPago.toLowerCase().contains(query),
      columns: [
        PrettyColumn(label: 'Venta ID', value: (p) => '${p.ventaId}'),
        PrettyColumn(label: 'Método pago', value: (p) => p.metodoPago),
        PrettyColumn(label: 'Monto', value: (p) => p.monto.toStringAsFixed(2)),
        PrettyColumn(label: 'Referencia', flex: 2, value: (p) => p.referencia),
        PrettyColumn(label: 'Estado', value: (p) => '${p.estado}'),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<VentaPago?> _showVentaPagoFormDialog(BuildContext context, {VentaPago? pago}) {
  final ventaIdCtrl = TextEditingController(text: pago?.ventaId.toString() ?? '');
  final metodoPagoCtrl = TextEditingController(text: pago?.metodoPago ?? '');
  final montoCtrl = TextEditingController(text: pago?.monto.toString() ?? '');
  final referenciaCtrl = TextEditingController(text: pago?.referencia ?? '');
  final estadoCtrl = TextEditingController(text: pago?.estado.toString() ?? '1');

  return showDialog<VentaPago>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(pago == null ? 'Nuevo pago' : 'Editar pago'),
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
                  controller: metodoPagoCtrl,
                  decoration: const InputDecoration(labelText: 'Método pago')),
              const SizedBox(height: 8),
              TextField(
                controller: montoCtrl,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: referenciaCtrl,
                  decoration: const InputDecoration(labelText: 'Referencia')),
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
              final metodoPago = metodoPagoCtrl.text.trim();
              final monto = double.tryParse(montoCtrl.text.trim());
              final referencia = referenciaCtrl.text.trim();
              final estado = int.tryParse(estadoCtrl.text.trim()) ?? 1;
              if (ventaId == null || metodoPago.isEmpty || monto == null) return;

              Navigator.of(context).pop(VentaPago(
                id: pago?.id,
                ventaId: ventaId,
                metodoPago: metodoPago,
                monto: monto,
                referencia: referencia,
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
