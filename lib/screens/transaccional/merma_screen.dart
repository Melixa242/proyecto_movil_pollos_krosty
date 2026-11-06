import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/merma.dart';
import '../../providers/transaccional/merma_provider.dart';
import '../pretty_crud_screen.dart';

class MermaScreen extends StatefulWidget {
  const MermaScreen({super.key});

  @override
  State<MermaScreen> createState() => _MermaScreenState();
}

class _MermaScreenState extends State<MermaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MermaProvider>().fetchMermas();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<MermaProvider>();
    final merma = await _showMermaFormDialog(context);
    if (merma == null || !mounted) return;
    final ok = await provider.createMerma(merma);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Merma creada' : 'Error al crear merma')));
  }

  Future<void> _editar(Merma merma) async {
    final provider = context.read<MermaProvider>();
    final updated = await _showMermaFormDialog(context, merma: merma);
    if (updated == null || !mounted) return;
    final ok = await provider.updateMerma(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Merma actualizada' : 'Error al actualizar')));
  }

  Future<void> _eliminar(Merma merma) async {
    if (!await confirmDelete(context, entity: 'esta merma') || !mounted) return;
    final ok = await context.read<MermaProvider>().deleteMerma(merma.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Merma eliminada' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MermaProvider>();
    return PrettyCrudScreen<Merma>(
      title: 'Mermas',
      subtitle: 'Listado de mermas registradas.',
      searchHint: 'Buscar por producción',
      newButtonLabel: 'Nueva merma',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<MermaProvider>().fetchMermas(),
      items: provider.mermas,
      matches: (item, query) => '${item.produccionId}'.contains(query),
      columns: [
        PrettyColumn(label: 'Producción ID', value: (m) => '${m.produccionId}'),
        PrettyColumn(label: 'Cantidad', value: (m) => m.cantidad.toStringAsFixed(2)),
        PrettyColumn(label: 'Estado', value: (m) => '${m.estado}'),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<Merma?> _showMermaFormDialog(BuildContext context, {Merma? merma}) {
  final produccionIdCtrl = TextEditingController(text: merma?.produccionId.toString() ?? '');
  final cantidadCtrl = TextEditingController(text: merma?.cantidad.toString() ?? '');
  final estadoCtrl = TextEditingController(text: merma?.estado.toString() ?? '1');

  return showDialog<Merma>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(merma == null ? 'Nueva merma' : 'Editar merma'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: produccionIdCtrl,
                decoration: const InputDecoration(labelText: 'Producción ID'),
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
              final produccionId = int.tryParse(produccionIdCtrl.text.trim());
              final cantidad = double.tryParse(cantidadCtrl.text.trim());
              final estado = int.tryParse(estadoCtrl.text.trim()) ?? 1;
              if (produccionId == null || cantidad == null) return;

              Navigator.of(context).pop(Merma(
                id: merma?.id,
                produccionId: produccionId,
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
