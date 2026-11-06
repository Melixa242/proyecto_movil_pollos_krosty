import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parametrizacion/regla_conversion.dart';
import '../../providers/parametrizacion/regla_provider.dart';
import '../app_colors.dart';
import '../pretty_crud_screen.dart';
import '../selector_api.dart';

class ReglasConversionScreen extends StatefulWidget {
  const ReglasConversionScreen({super.key});

  @override
  State<ReglasConversionScreen> createState() =>
      _ReglasConversionScreenState();
}

class _ReglasConversionScreenState extends State<ReglasConversionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ReglaConversionProvider>().fetchReglasConversion();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<ReglaConversionProvider>();
    final regla = await showReglaFormDialog(context);
    if (regla == null || !mounted) return;
    final ok = await provider.createReglaConversion(regla);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Regla creada' : provider.errorGuardado ?? 'Error al crear regla')));
  }

  Future<void> _editar(ReglaConversion regla) async {
    final provider = context.read<ReglaConversionProvider>();
    final updated = await showReglaFormDialog(context, regla: regla);
    if (updated == null || !mounted) return;
    final ok = await provider.updateReglaConversion(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Regla actualizada' : provider.errorGuardado ?? 'Error al actualizar')));
  }

  Future<void> _eliminar(ReglaConversion regla) async {
    if (!await confirmDelete(context, entity: 'esta regla') || !mounted) return;
    final provider = context.read<ReglaConversionProvider>();
    final ok = await provider.deleteReglaConversion(regla.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Regla eliminada' : provider.errorGuardado ?? 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReglaConversionProvider>();
    return PrettyCrudScreen<ReglaConversion>(
      title: 'Reglas de Conversión',
      subtitle: 'Gestión de reglas de conversión de insumos.',
      searchHint: 'Buscar por insumo o unidad',
      newButtonLabel: 'Nueva regla',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<ReglaConversionProvider>().fetchReglasConversion(),
      items: provider.reglasConversion,
      matches: (r, query) =>
          r.nombreInsumo.toLowerCase().contains(query) ||
          r.unidadEntrada.toLowerCase().contains(query) ||
          r.unidadSalida.toLowerCase().contains(query),
      columns: [
        PrettyColumn(label: 'Insumo', flex: 2, value: (r) => r.nombreInsumo),
        PrettyColumn(label: 'Entrada', flex: 1, value: (r) => r.unidadEntrada),
        PrettyColumn(label: 'Salida', flex: 1, value: (r) => r.unidadSalida),
        PrettyColumn(label: 'Producto resultante', flex: 2, value: (r) => r.nombreProducto),
        PrettyColumn(label: 'Cantidad', flex: 1, value: (r) => r.getCantidadFormato()),
        PrettyColumn(label: 'Tipo', flex: 1, value: (r) => r.getTipoDisplay()),
        PrettyColumn(label: 'Rendimiento', flex: 1, value: (r) => r.getRendimientoFormato()),
        PrettyColumn(label: 'Estado', flex: 1, value: (r) => r.getEstadoDisplay()),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<ReglaConversion?> showReglaFormDialog(BuildContext context,
    {ReglaConversion? regla}) async {
  final opciones = await Future.wait([
    cargarOpciones('/insumos'),
    cargarOpciones('/productos'),
    cargarOpciones('/unidad-medidas'),
  ]);
  if (!context.mounted) return null;
  final insumos = opciones[0], productos = opciones[1], unidades = opciones[2];
  if (insumos.isEmpty || productos.isEmpty || unidades.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudieron cargar insumos, productos o unidades')));
    return null;
  }

  int? insumoId = regla?.insumoId;
  int? productoId = regla?.productoResultanteId;
  int? unidadEntradaId = regla?.unidadEntradaId;
  int? unidadSalidaId = regla?.unidadSalidaId;
  String tipo = regla?.tipoConversion.toLowerCase() == 'variable' ? 'variable' : 'estatica';
  final rendimientoMinCtrl =
      TextEditingController(text: regla?.rendimientoMin.toString() ?? '');
  final rendimientoMaxCtrl =
      TextEditingController(text: regla?.rendimientoMax.toString() ?? '');
  String? error;

  double? numero(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  return showDialog<ReglaConversion>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(regla == null ? 'Nueva regla' : 'Editar regla'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectorApi(
                      label: 'Insumo de entrada',
                      opciones: insumos,
                      valor: insumoId,
                      onChanged: (v) => setState(() => insumoId = v)),
                  const SizedBox(height: 8),
                  SelectorApi(
                      label: 'Unidad de entrada',
                      opciones: unidades,
                      valor: unidadEntradaId,
                      onChanged: (v) => setState(() => unidadEntradaId = v)),
                  const SizedBox(height: 8),
                  SelectorApi(
                      label: 'Producto resultante',
                      opciones: productos,
                      valor: productoId,
                      onChanged: (v) => setState(() => productoId = v)),
                  const SizedBox(height: 8),
                  SelectorApi(
                      label: 'Unidad resultante',
                      opciones: unidades,
                      valor: unidadSalidaId,
                      onChanged: (v) => setState(() => unidadSalidaId = v)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de conversión'),
                    items: const [
                      DropdownMenuItem(value: 'estatica', child: Text('Estática')),
                      DropdownMenuItem(value: 'variable', child: Text('Variable')),
                    ],
                    onChanged: (v) => setState(() => tipo = v ?? 'estatica'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: rendimientoMinCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Rendimiento mínimo'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: rendimientoMaxCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Rendimiento máximo'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!,
                        style: const TextStyle(color: AppColors.primaryRed)),
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
                final min = numero(rendimientoMinCtrl);
                final max = numero(rendimientoMaxCtrl);
                String? nuevoError;
                if (insumoId == null ||
                    productoId == null ||
                    unidadEntradaId == null ||
                    unidadSalidaId == null) {
                  nuevoError = 'Completá insumo, producto y las dos unidades.';
                } else if (min == null || max == null || min < 0) {
                  nuevoError = 'Ingresá rendimientos válidos (números mayores o iguales a 0).';
                } else if (max < min) {
                  nuevoError = 'El rendimiento máximo debe ser mayor o igual al mínimo.';
                }
                if (nuevoError != null) {
                  setState(() => error = nuevoError);
                  return;
                }

                Navigator.of(context).pop(ReglaConversion(
                    id: regla?.id,
                    insumoId: insumoId!,
                    productoResultanteId: productoId!,
                    unidadEntradaId: unidadEntradaId!,
                    unidadSalidaId: unidadSalidaId!,
                    tipoConversion: tipo,
                    rendimientoMin: min!,
                    rendimientoMax: max!));
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      });
    },
  );
}
