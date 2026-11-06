import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/ingreso_insumo.dart';
import '../../providers/transaccional/ingreso_insumo_provider.dart';
import '../../providers/parametrizacion/insumo_provider.dart';
import '../pretty_crud_screen.dart';
import 'lineas_ingreso_editor.dart';

class IngresoInsumoScreen extends StatefulWidget {
  const IngresoInsumoScreen({super.key});

  @override
  State<IngresoInsumoScreen> createState() => _IngresoInsumoScreenState();
}

class _IngresoInsumoScreenState extends State<IngresoInsumoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<IngresoInsumoProvider>().fetchIngresos();
      context.read<InsumoProvider>().fetchInsumos();
    });
  }

  Future<void> _crear() => _guardar();
  Future<void> _editar(IngresoInsumo ingreso) => _guardar(ingreso);

  /// Crea o edita el ingreso junto con sus detalles (el servidor exige al menos uno).
  Future<void> _guardar([IngresoInsumo? ingreso]) async {
    final provider = context.read<IngresoInsumoProvider>();
    final lineas = <LineaIngreso>[];
    if (ingreso != null) {
      for (final d in await provider.fetchLines('/ingreso-insumos/${ingreso.id}/detalles')) {
        lineas.add(LineaIngreso(
          itemId: int.tryParse('${d['insumo_id']}'),
          cantidad: double.tryParse('${d['cantidad']}') ?? 0,
          precio: double.tryParse('${d['precio_unitario']}') ?? 0,
        ));
      }
    }
    if (!mounted) return;
    final insumos = {
      for (final i in context.read<InsumoProvider>().insumos)
        if (i.id != null) i.id!: i.nombre,
    };
    final result = await _showIngresoInsumoFormDialog(context, insumos, lineas, ingreso: ingreso);
    if (result == null || !mounted) return;
    final error = await provider.saveWithLines(
      result,
      'detalles',
      [
        for (final l in lineas) {'insumo_id': l.itemId, 'cantidad': l.cantidad, 'precio_unitario': l.precio},
      ],
      id: ingreso?.id,
    );
    if (!mounted) return;
    final ok = ingreso == null ? 'Ingreso creado' : 'Ingreso actualizado';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? ok)));
  }

  Future<void> _eliminar(IngresoInsumo ingreso) async {
    if (!await confirmDelete(context, entity: 'este ingreso') || !mounted) return;
    final ok = await context.read<IngresoInsumoProvider>().deleteIngreso(ingreso.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Ingreso eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngresoInsumoProvider>();
    return PrettyCrudScreen<IngresoInsumo>(
      title: 'Ingresos de insumos',
      subtitle: 'Listado de ingresos de insumos registrados.',
      searchHint: 'Buscar por descripción',
      newButtonLabel: 'Nuevo ingreso',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<IngresoInsumoProvider>().fetchIngresos(),
      items: provider.ingresos,
      matches: (item, query) => item.descripcion.toLowerCase().contains(query),
      columns: [
        PrettyColumn(label: 'Fecha ingreso', value: (i) => i.fechaIngreso),
        PrettyColumn(label: 'Descripción', flex: 2, value: (i) => i.descripcion),
        PrettyColumn(label: 'Estado', value: (i) => '${i.estado}'),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<IngresoInsumo?> _showIngresoInsumoFormDialog(
    BuildContext context, Map<int, String> insumos, List<LineaIngreso> lineas,
    {IngresoInsumo? ingreso}) {
  final hoy = DateTime.now().toIso8601String().substring(0, 10);
  final fechaIngresoCtrl = TextEditingController(text: ingreso?.fechaIngreso ?? hoy);
  final descripcionCtrl = TextEditingController(text: ingreso?.descripcion ?? '');
  final estadoCtrl = TextEditingController(text: ingreso?.estado.toString() ?? '1');
  String? error;

  return showDialog<IngresoInsumo>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(ingreso == null ? 'Nuevo ingreso' : 'Editar ingreso'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                      controller: fechaIngresoCtrl,
                      decoration: const InputDecoration(labelText: 'Fecha ingreso (AAAA-MM-DD)')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: descripcionCtrl,
                      decoration: const InputDecoration(labelText: 'Descripción')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: estadoCtrl,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  LineasIngresoEditor(itemLabel: 'Insumo', opciones: insumos, lineas: lineas),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final fechaIngreso = fechaIngresoCtrl.text.trim();
                final descripcion = descripcionCtrl.text.trim();
                final estado = int.tryParse(estadoCtrl.text.trim()) ?? 1;
                final mensaje = DateTime.tryParse(fechaIngreso) == null
                    ? 'Ingresa una fecha válida (AAAA-MM-DD).'
                    : LineasIngresoEditor.validar(lineas, 'Insumo');
                if (mensaje != null) {
                  setState(() => error = mensaje);
                  return;
                }

                Navigator.of(context).pop(IngresoInsumo(
                  id: ingreso?.id,
                  fechaIngreso: fechaIngreso,
                  descripcion: descripcion,
                  estado: estado,
                ));
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      });
    },
  );
}
