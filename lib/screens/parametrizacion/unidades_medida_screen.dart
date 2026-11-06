import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parametrizacion/unidad_medida.dart';
import '../../providers/parametrizacion/unidad_medida_provider.dart';
import '../pretty_crud_screen.dart';

class UnidadesMedidaScreen extends StatefulWidget {
  const UnidadesMedidaScreen({super.key});

  @override
  State<UnidadesMedidaScreen> createState() => _UnidadesMedidaScreenState();
}

class _UnidadesMedidaScreenState extends State<UnidadesMedidaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<UnidadMedidaProvider>().fetchUnidadesMedida();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<UnidadMedidaProvider>();
    final unidad = await showUnidadMedidaFormDialog(context);
    if (unidad == null || !mounted) return;
    final ok = await provider.createUnidadMedida(unidad);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Unidad de medida creada' : 'Error al crear unidad')));
  }

  Future<void> _editar(UnidadMedida unidad) async {
    final provider = context.read<UnidadMedidaProvider>();
    final updated = await showUnidadMedidaFormDialog(context, unidadMedida: unidad);
    if (updated == null || !mounted) return;
    final ok = await provider.updateUnidadMedida(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Unidad actualizada' : 'Error al actualizar')));
  }

  Future<void> _eliminar(UnidadMedida unidad) async {
    if (!await confirmDelete(context, entity: 'esta unidad de medida') || !mounted) return;
    final ok = await context.read<UnidadMedidaProvider>().deleteUnidadMedida(unidad.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Unidad eliminada' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UnidadMedidaProvider>();
    return PrettyCrudScreen<UnidadMedida>(
      title: 'Unidades de Medida',
      subtitle: 'Listado de unidades de medida registradas.',
      searchHint: 'Buscar por nombre o abreviatura',
      newButtonLabel: 'Nueva unidad',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<UnidadMedidaProvider>().fetchUnidadesMedida(),
      items: provider.unidadesMedida,
      matches: (u, query) =>
          u.nombre.toLowerCase().contains(query) || u.abreviatura.toLowerCase().contains(query),
      columns: [
        PrettyColumn(label: 'Nombre', flex: 2, value: (u) => u.nombre),
        PrettyColumn(label: 'Abreviatura', flex: 1, value: (u) => u.abreviatura),
        PrettyColumn(label: 'Factor', flex: 1, value: (u) => u.getFactorFormato()),
        PrettyColumn(label: 'Estado', flex: 1, value: (u) => u.getEstadoDisplay()),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<UnidadMedida?> showUnidadMedidaFormDialog(BuildContext context,
    {UnidadMedida? unidadMedida}) {
  final nombreCtrl =
      TextEditingController(text: unidadMedida?.nombre ?? '');
  final abreviaturaCtrl =
      TextEditingController(text: unidadMedida?.abreviatura ?? '');
  final factorConversionCtrl = TextEditingController(
      text: unidadMedida?.factorConversion.toString() ?? '');
  final estadoCtrl = TextEditingController(text: unidadMedida?.estado ?? '');

  return showDialog<UnidadMedida>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(unidadMedida == null
            ? 'Nueva unidad de medida'
            : 'Editar unidad de medida'),
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
                  controller: abreviaturaCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Abreviatura')),
              const SizedBox(height: 8),
              TextField(
                  controller: factorConversionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Factor de Conversión'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 8),
              TextField(
                  controller: estadoCtrl,
                  decoration: const InputDecoration(labelText: 'Estado')),
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
              final abreviatura = abreviaturaCtrl.text.trim();
              final factorConversion =
                  double.tryParse(factorConversionCtrl.text.trim()) ?? 0.0;
              final estado = estadoCtrl.text.trim();

              if (nombre.isEmpty) return;

              Navigator.of(context).pop(UnidadMedida(
                  id: unidadMedida?.id,
                  nombre: nombre,
                  abreviatura: abreviatura,
                  factorConversion: factorConversion,
                  estado: estado));
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
