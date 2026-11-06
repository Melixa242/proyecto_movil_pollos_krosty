import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/produccion.dart';
import '../../providers/transaccional/produccion_provider.dart';
import '../pretty_crud_screen.dart';

class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({super.key});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProduccionProvider>().fetchProducciones();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<ProduccionProvider>();
    final produccion = await _showProduccionFormDialog(context);
    if (produccion == null || !mounted) return;
    final ok = await provider.createProduccion(produccion);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Producción creada' : 'Error al crear producción')));
  }

  Future<void> _editar(Produccion produccion) async {
    final provider = context.read<ProduccionProvider>();
    final updated = await _showProduccionFormDialog(context, produccion: produccion);
    if (updated == null || !mounted) return;
    final ok = await provider.updateProduccion(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Producción actualizada' : 'Error al actualizar')));
  }

  Future<void> _eliminar(Produccion produccion) async {
    if (!await confirmDelete(context, entity: 'esta producción') || !mounted) return;
    final ok = await context.read<ProduccionProvider>().deleteProduccion(produccion.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Producción eliminada' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProduccionProvider>();
    return PrettyCrudScreen<Produccion>(
      title: 'Producción',
      subtitle: 'Listado de producciones registradas.',
      searchHint: 'Buscar por producto u orden',
      newButtonLabel: 'Nueva producción',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<ProduccionProvider>().fetchProducciones(),
      items: provider.producciones,
      matches: (item, query) =>
          '${item.ordenProduccionId}'.contains(query) || '${item.productoId}'.contains(query),
      columns: [
        PrettyColumn(label: 'Orden Producción ID', value: (p) => p.ordenProduccionId == null ? '-' : '${p.ordenProduccionId}'),
        PrettyColumn(label: 'Producto ID', value: (p) => p.productoId == null ? '-' : '${p.productoId}'),
        PrettyColumn(label: 'Cant. Insumo', value: (p) => p.cantidadInsumo.toStringAsFixed(2)),
        PrettyColumn(label: 'Cant. Obtenida', value: (p) => p.cantidadObtenida.toStringAsFixed(2)),
        PrettyColumn(label: 'Nivel', value: (p) => '${p.nivel}'),
        PrettyColumn(label: 'Estado', value: (p) => '${p.estado}'),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<Produccion?> _showProduccionFormDialog(BuildContext context, {Produccion? produccion}) {
  final ordenProduccionIdCtrl =
      TextEditingController(text: produccion?.ordenProduccionId?.toString() ?? '');
  final ordenProduccionInsumoIdCtrl =
      TextEditingController(text: produccion?.ordenProduccionInsumoId?.toString() ?? '');
  final reglaConversionIdCtrl =
      TextEditingController(text: produccion?.reglaConversionId?.toString() ?? '');
  final productoIdCtrl = TextEditingController(text: produccion?.productoId?.toString() ?? '');
  final cantidadInsumoCtrl = TextEditingController(text: produccion?.cantidadInsumo.toString() ?? '');
  final cantidadObtenidaCtrl =
      TextEditingController(text: produccion?.cantidadObtenida.toString() ?? '');
  final nivelCtrl = TextEditingController(text: produccion?.nivel.toString() ?? '0');
  final estadoCtrl = TextEditingController(text: produccion?.estado.toString() ?? '1');

  return showDialog<Produccion>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(produccion == null ? 'Nueva producción' : 'Editar producción'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ordenProduccionIdCtrl,
                decoration: const InputDecoration(labelText: 'Orden Producción ID (opcional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ordenProduccionInsumoIdCtrl,
                decoration: const InputDecoration(labelText: 'Orden Producción Insumo ID (opcional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reglaConversionIdCtrl,
                decoration: const InputDecoration(labelText: 'Regla Conversión ID (opcional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: productoIdCtrl,
                decoration: const InputDecoration(labelText: 'Producto ID (opcional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cantidadInsumoCtrl,
                decoration: const InputDecoration(labelText: 'Cantidad Insumo'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cantidadObtenidaCtrl,
                decoration: const InputDecoration(labelText: 'Cantidad Obtenida'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nivelCtrl,
                decoration: const InputDecoration(labelText: 'Nivel'),
                keyboardType: TextInputType.number,
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
              final ordenProduccionIdText = ordenProduccionIdCtrl.text.trim();
              final ordenProduccionInsumoIdText = ordenProduccionInsumoIdCtrl.text.trim();
              final reglaConversionIdText = reglaConversionIdCtrl.text.trim();
              final productoIdText = productoIdCtrl.text.trim();
              final cantidadInsumo = double.tryParse(cantidadInsumoCtrl.text.trim());
              final cantidadObtenida = double.tryParse(cantidadObtenidaCtrl.text.trim());
              final nivel = int.tryParse(nivelCtrl.text.trim()) ?? 0;
              final estado = int.tryParse(estadoCtrl.text.trim()) ?? 1;
              if (cantidadInsumo == null || cantidadObtenida == null) return;

              Navigator.of(context).pop(Produccion(
                id: produccion?.id,
                ordenProduccionId:
                    ordenProduccionIdText.isEmpty ? null : int.tryParse(ordenProduccionIdText),
                ordenProduccionInsumoId: ordenProduccionInsumoIdText.isEmpty
                    ? null
                    : int.tryParse(ordenProduccionInsumoIdText),
                reglaConversionId:
                    reglaConversionIdText.isEmpty ? null : int.tryParse(reglaConversionIdText),
                productoId: productoIdText.isEmpty ? null : int.tryParse(productoIdText),
                cantidadInsumo: cantidadInsumo,
                cantidadObtenida: cantidadObtenida,
                nivel: nivel,
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
