import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parametrizacion/insumo.dart';
import '../../providers/parametrizacion/insumo_provider.dart';
import '../../providers/parametrizacion/unidad_medida_provider.dart';
import '../app_colors.dart';
import '../pretty_crud_screen.dart';
import '../selector_api.dart';

class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<InsumoProvider>().fetchInsumos();
      // Para mostrar el nombre de la unidad en vez de su id.
      context.read<UnidadMedidaProvider>().fetchUnidadesMedida();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<InsumoProvider>();
    final insumo = await showInsumoFormDialog(context);
    if (insumo == null || !mounted) return;
    final ok = await provider.createInsumo(insumo);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Insumo creado' : 'Error al crear insumo')));
  }

  Future<void> _editar(Insumo insumo) async {
    final provider = context.read<InsumoProvider>();
    final updated = await showInsumoFormDialog(context, insumo: insumo);
    if (updated == null || !mounted) return;
    final ok = await provider.updateInsumo(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Insumo actualizado' : 'Error al actualizar')));
  }

  Future<void> _eliminar(Insumo insumo) async {
    if (!await confirmDelete(context, entity: 'este insumo') || !mounted) return;
    final ok = await context.read<InsumoProvider>().deleteInsumo(insumo.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Insumo eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsumoProvider>();
    final unidades = {
      for (final u in context.watch<UnidadMedidaProvider>().unidadesMedida) u.id: u.nombre,
    };
    return PrettyCrudScreen<Insumo>(
      title: 'Insumos',
      subtitle: 'Listado de insumos registrados.',
      searchHint: 'Buscar por nombre o stock',
      newButtonLabel: 'Nuevo insumo',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<InsumoProvider>().fetchInsumos(),
      items: provider.insumos,
      matches: (i, query) => i.nombre.toLowerCase().contains(query) || i.getStockFormato().contains(query),
      columns: [
        PrettyColumn(label: 'Nombre', flex: 3, value: (i) => i.nombre),
        PrettyColumn(label: 'Unidad', flex: 2, value: (i) => unidades[i.unidadMedidaId] ?? '#${i.unidadMedidaId}'),
        PrettyColumn(label: 'Stock actual', flex: 2, value: (i) => i.getStockFormato()),
        PrettyColumn(label: 'Stock mínimo', flex: 2, value: (i) => i.stockMinimo.toStringAsFixed(2)),
        PrettyColumn(label: 'Nivel de stock', flex: 2, value: (i) => i.getStockStatus()),
        PrettyColumn(label: 'Estado', flex: 1, value: (i) => i.getEstadoDisplay()),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

/// Formulario de insumo; la unidad se elige de la tabla unidad_medidas.
Future<Insumo?> showInsumoFormDialog(BuildContext context,
    {Insumo? insumo}) async {
  final unidades = await cargarOpciones('/unidad-medidas');
  if (!context.mounted) return null;
  if (unidades.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar las unidades de medida')));
    return null;
  }

  final nombreCtrl = TextEditingController(text: insumo?.nombre ?? '');
  final stockActualCtrl =
      TextEditingController(text: insumo?.stockActual.toString() ?? '');
  final stockMinimoCtrl =
      TextEditingController(text: insumo?.stockMinimo.toString() ?? '');
  final estadoCtrl = TextEditingController(text: insumo?.estado ?? '');
  int? unidadMedidaId = insumo?.unidadMedidaId;
  String? error;

  return showDialog<Insumo>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title:
              Text(insumo == null ? 'Nuevo insumo' : 'Editar insumo'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nombreCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 8),
                  SelectorApi(
                      label: 'Unidad de medida',
                      opciones: unidades,
                      valor: unidadMedidaId,
                      onChanged: (v) => setState(() => unidadMedidaId = v)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: stockActualCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Stock actual'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: stockMinimoCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Stock mínimo'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: estadoCtrl,
                      decoration: const InputDecoration(labelText: 'Estado')),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: AppColors.primaryRed)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final nombre = nombreCtrl.text.trim();
                final stockActual =
                    double.tryParse(stockActualCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
                final stockMinimo =
                    double.tryParse(stockMinimoCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
                final estado = estadoCtrl.text.trim();

                String? nuevoError;
                if (nombre.isEmpty) {
                  nuevoError = 'Ingresá el nombre del insumo.';
                } else if (unidadMedidaId == null) {
                  nuevoError = 'Seleccioná la unidad de medida.';
                }
                if (nuevoError != null) {
                  setState(() => error = nuevoError);
                  return;
                }

                Navigator.of(context).pop(Insumo(
                    id: insumo?.id,
                    nombre: nombre,
                    unidadMedidaId: unidadMedidaId!,
                    stockActual: stockActual,
                    stockMinimo: stockMinimo,
                    estado: estado));
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      });
    },
  );
}
