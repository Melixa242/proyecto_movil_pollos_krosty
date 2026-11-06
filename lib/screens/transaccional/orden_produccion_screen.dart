import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/orden_produccion.dart';
import '../../providers/parametrizacion/insumo_provider.dart';
import '../../providers/parametrizacion/regla_provider.dart';
import '../../providers/transaccional/orden_produccion_provider.dart';
import '../pretty_crud_screen.dart';
import 'lineas_ingreso_editor.dart';

class OrdenProduccionScreen extends StatefulWidget {
  const OrdenProduccionScreen({super.key});

  @override
  State<OrdenProduccionScreen> createState() => _OrdenProduccionScreenState();
}

class _OrdenProduccionScreenState extends State<OrdenProduccionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<OrdenProduccionProvider>().fetchOrdenes();
      context.read<InsumoProvider>().fetchInsumos();
      context.read<ReglaConversionProvider>().fetchReglasConversion();
    });
  }

  /// id → "insumo → producto" de cada receta (regla de conversión).
  Map<int, String> _recetas() => {
        for (final r in context.read<ReglaConversionProvider>().reglasConversion)
          if (r.id != null) r.id!: '${r.nombreInsumo} → ${r.nombreProducto}',
      };

  Future<void> _crear() => _guardar();
  Future<void> _editar(OrdenProduccion orden) => _guardar(orden);

  /// Crea o edita la orden junto con sus insumos planificados (el servidor exige al menos uno).
  Future<void> _guardar([OrdenProduccion? orden]) async {
    final provider = context.read<OrdenProduccionProvider>();
    final lineas = <LineaIngreso>[];
    if (orden != null) {
      for (final i in await provider.fetchLines('/ordenes/${orden.id}/insumos')) {
        lineas.add(LineaIngreso(
          itemId: int.tryParse('${i['insumo_id']}'),
          cantidad: double.tryParse('${i['cantidad']}') ?? 0,
        ));
      }
    }
    if (!mounted) return;
    final insumos = {
      for (final i in context.read<InsumoProvider>().insumos)
        if (i.id != null) i.id!: i.nombre,
    };
    final result = await _showOrdenProduccionFormDialog(context, _recetas(), insumos, lineas, orden: orden);
    if (result == null || !mounted) return;
    final error = await provider.saveWithLines(
      result,
      'insumos',
      [
        for (final l in lineas) {'insumo_id': l.itemId, 'cantidad': l.cantidad},
      ],
      id: orden?.id,
    );
    if (!mounted) return;
    final ok = orden == null ? 'Orden creada' : 'Orden actualizada';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? ok)));
  }

  /// Ejecuta la orden: el servidor crea las producciones, descuenta el stock de
  /// los insumos y suma la cantidad obtenida al producto de la receta.
  Future<void> _ejecutar(OrdenProduccion orden) async {
    final provider = context.read<OrdenProduccionProvider>();
    final datos = await provider.datosEjecucion(orden.id!);
    if (!mounted) return;
    if (datos == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudieron obtener los datos de la orden')));
      return;
    }
    final cantidad = await _showEjecutarDialog(context, orden, datos);
    if (cantidad == null || !mounted) return;
    final result = await provider.ejecutar(orden.id!, cantidad);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.mensaje)));
  }

  Future<void> _eliminar(OrdenProduccion orden) async {
    if (!await confirmDelete(context, entity: 'esta orden') || !mounted) return;
    final ok = await context.read<OrdenProduccionProvider>().deleteOrden(orden.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Orden eliminada' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdenProduccionProvider>();
    context.watch<ReglaConversionProvider>();
    final recetas = _recetas();
    return PrettyCrudScreen<OrdenProduccion>(
      title: 'Orden de producción',
      subtitle: 'Listado de órdenes de producción registradas.',
      searchHint: 'Buscar por número de orden',
      newButtonLabel: 'Nueva orden',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<OrdenProduccionProvider>().fetchOrdenes(),
      items: provider.ordenes,
      matches: (item, query) => item.numeroOrden.toLowerCase().contains(query),
      columns: [
        PrettyColumn(label: 'N° Orden', value: (o) => o.numeroOrden),
        PrettyColumn(label: 'Fecha programada', value: (o) => o.fechaProgramada),
        PrettyColumn(label: 'Receta', flex: 2, value: (o) => recetas[o.reglaConversionId] ?? '-'),
        PrettyColumn(label: 'Observaciones', flex: 2, value: (o) => o.observaciones),
        PrettyColumn(label: 'Estado', value: (o) => '${o.estado}'),
      ],
      onNew: _crear,
      onView: _ejecutar,
      viewLabel: 'Ejecutar',
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<OrdenProduccion?> _showOrdenProduccionFormDialog(
    BuildContext context, Map<int, String> recetas, Map<int, String> insumos, List<LineaIngreso> lineas,
    {OrdenProduccion? orden}) {
  final hoy = DateTime.now().toIso8601String().substring(0, 10);
  final numeroOrdenCtrl = TextEditingController(text: orden?.numeroOrden ?? '');
  final fechaProgramadaCtrl = TextEditingController(text: orden?.fechaProgramada ?? hoy);
  final observacionesCtrl = TextEditingController(text: orden?.observaciones ?? '');
  final estadoCtrl = TextEditingController(text: orden?.estado.toString() ?? '1');
  int? reglaId = recetas.containsKey(orden?.reglaConversionId) ? orden?.reglaConversionId : null;
  String? error;

  return showDialog<OrdenProduccion>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(orden == null ? 'Nueva orden' : 'Editar orden'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                      controller: numeroOrdenCtrl,
                      decoration: const InputDecoration(
                          labelText: 'N° Orden', hintText: 'Vacío: se genera automáticamente')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: fechaProgramadaCtrl,
                      decoration: const InputDecoration(labelText: 'Fecha programada (AAAA-MM-DD)')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: reglaId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Receta (regla de conversión)'),
                    items: recetas.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => reglaId = v,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: observacionesCtrl,
                      decoration: const InputDecoration(labelText: 'Observaciones')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: estadoCtrl,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  LineasIngresoEditor(itemLabel: 'Insumo', opciones: insumos, lineas: lineas, conPrecio: false),
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
                final fechaProgramada = fechaProgramadaCtrl.text.trim();
                final mensaje = DateTime.tryParse(fechaProgramada) == null
                    ? 'Ingresa una fecha válida (AAAA-MM-DD).'
                    : reglaId == null
                        ? 'Selecciona la receta de la orden.'
                        : LineasIngresoEditor.validar(lineas, 'Insumo');
                if (mensaje != null) {
                  setState(() => error = mensaje);
                  return;
                }

                Navigator.of(context).pop(OrdenProduccion(
                  id: orden?.id,
                  numeroOrden: numeroOrdenCtrl.text.trim(),
                  fechaProgramada: fechaProgramada,
                  reglaConversionId: reglaId,
                  observaciones: observacionesCtrl.text.trim(),
                  estado: int.tryParse(estadoCtrl.text.trim()) ?? 1,
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

/// Muestra la receta, los insumos pendientes y el rango permitido; devuelve la
/// cantidad obtenida a registrar, o null si se cancela.
Future<double?> _showEjecutarDialog(BuildContext context, OrdenProduccion orden, Map<String, dynamic> datos) {
  final regla = datos['regla'] as Map?;
  final producto = datos['producto'] as Map?;
  final pendientes = (datos['pendientes'] as List?) ?? const [];
  final minimo = (datos['minimo'] as num?)?.toDouble() ?? 0;
  final maximo = (datos['maximo'] as num?)?.toDouble() ?? 0;
  final noEjecutable = regla == null
      ? 'La orden no tiene receta asignada. Edítala y elige una.'
      : producto == null
          ? 'No existe el producto "${regla['producto_resultante']}" de la receta.'
          : pendientes.isEmpty
              ? 'La orden ya fue ejecutada: no tiene insumos pendientes.'
              : null;
  String fmt(double v) => v.toStringAsFixed(2);
  final cantidadCtrl = TextEditingController(text: minimo == maximo && minimo > 0 ? fmt(minimo) : '');
  String? error;

  return showDialog<double>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text('Ejecutar ${orden.numeroOrden}'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (regla != null) Text('Receta: ${regla['nombre_insumo']} → ${regla['producto_resultante']}'),
                  if (noEjecutable != null) ...[
                    const SizedBox(height: 12),
                    Text(noEjecutable, style: const TextStyle(color: Colors.red)),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text('Insumos a descontar:', style: TextStyle(fontWeight: FontWeight.bold)),
                    for (final p in pendientes) Text('• ${p['insumo']}: ${p['cantidad']}'),
                    const SizedBox(height: 12),
                    Text('Cantidad obtenida permitida: ${fmt(minimo)} a ${fmt(maximo)} de ${producto!['nombre']}'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cantidadCtrl,
                      decoration: const InputDecoration(labelText: 'Cantidad obtenida'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(error!, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            if (noEjecutable == null)
              ElevatedButton(
                onPressed: () {
                  final cantidad = double.tryParse(cantidadCtrl.text.trim().replaceAll(',', '.'));
                  if (cantidad == null || cantidad < minimo || cantidad > maximo) {
                    setState(() => error = 'Ingresa una cantidad entre ${fmt(minimo)} y ${fmt(maximo)}.');
                    return;
                  }
                  Navigator.of(context).pop(cantidad);
                },
                child: const Text('Ejecutar'),
              ),
          ],
        );
      });
    },
  );
}
