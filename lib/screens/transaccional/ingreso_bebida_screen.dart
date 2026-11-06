import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/ingreso_bebida.dart';
import '../../providers/transaccional/ingreso_bebida_provider.dart';
import '../../providers/parametrizacion/producto_provider.dart';
import '../pretty_crud_screen.dart';
import 'lineas_ingreso_editor.dart';

class IngresoBebidaScreen extends StatefulWidget {
  const IngresoBebidaScreen({super.key});

  @override
  State<IngresoBebidaScreen> createState() => _IngresoBebidaScreenState();
}

class _IngresoBebidaScreenState extends State<IngresoBebidaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<IngresoBebidaProvider>().fetchIngresos();
      context.read<ProductoProvider>().fetchProductos();
    });
  }

  Future<void> _crear() => _guardar();
  Future<void> _editar(IngresoBebida ingreso) => _guardar(ingreso);

  /// Crea o edita el ingreso junto con sus productos (el servidor exige al menos uno).
  Future<void> _guardar([IngresoBebida? ingreso]) async {
    final provider = context.read<IngresoBebidaProvider>();
    final lineas = <LineaIngreso>[];
    if (ingreso != null) {
      for (final p in await provider.fetchLines('/ingreso-bebidas/${ingreso.id}/productos')) {
        lineas.add(LineaIngreso(
          itemId: int.tryParse('${p['producto_id']}'),
          cantidad: double.tryParse('${p['cantidad_ingresa']}') ?? 0,
          precio: double.tryParse('${p['precio']}') ?? 0,
        ));
      }
    }
    if (!mounted) return;
    final productos = {
      for (final p in context.read<ProductoProvider>().productos)
        if (p.id != null) p.id!: p.nombre,
    };
    final result = await _showIngresoBebidaFormDialog(context, productos, lineas, ingreso: ingreso);
    if (result == null || !mounted) return;
    final error = await provider.saveWithLines(
      result,
      'productos',
      [
        for (final l in lineas) {'producto_id': l.itemId, 'cantidad_ingresa': l.cantidad, 'precio': l.precio},
      ],
      id: ingreso?.id,
    );
    if (!mounted) return;
    final ok = ingreso == null ? 'Ingreso creado' : 'Ingreso actualizado';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? ok)));
  }

  Future<void> _eliminar(IngresoBebida ingreso) async {
    if (!await confirmDelete(context, entity: 'este ingreso') || !mounted) return;
    final ok = await context.read<IngresoBebidaProvider>().deleteIngreso(ingreso.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Ingreso eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngresoBebidaProvider>();
    return PrettyCrudScreen<IngresoBebida>(
      title: 'Ingresos de bebidas',
      subtitle: 'Listado de ingresos de bebidas registrados.',
      searchHint: 'Buscar por nombre',
      newButtonLabel: 'Nuevo ingreso',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<IngresoBebidaProvider>().fetchIngresos(),
      items: provider.ingresos,
      matches: (item, query) => item.nombre.toLowerCase().contains(query),
      columns: [
        PrettyColumn(label: 'Nombre', flex: 2, value: (i) => i.nombre),
        PrettyColumn(label: 'Descripción', flex: 2, value: (i) => i.descripcion),
        PrettyColumn(label: 'Fecha ingreso', value: (i) => i.fechaIngreso),
        PrettyColumn(label: 'Estado', value: (i) => '${i.estado}'),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

Future<IngresoBebida?> _showIngresoBebidaFormDialog(
    BuildContext context, Map<int, String> productos, List<LineaIngreso> lineas,
    {IngresoBebida? ingreso}) {
  final hoy = DateTime.now().toIso8601String().substring(0, 10);
  final nombreCtrl = TextEditingController(text: ingreso?.nombre ?? '');
  final descripcionCtrl = TextEditingController(text: ingreso?.descripcion ?? '');
  final fechaIngresoCtrl = TextEditingController(text: ingreso?.fechaIngreso ?? hoy);
  final estadoCtrl = TextEditingController(text: ingreso?.estado.toString() ?? '1');
  String? error;

  return showDialog<IngresoBebida>(
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
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: descripcionCtrl,
                      decoration: const InputDecoration(labelText: 'Descripción')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: fechaIngresoCtrl,
                      decoration: const InputDecoration(labelText: 'Fecha ingreso (AAAA-MM-DD)')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: estadoCtrl,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  LineasIngresoEditor(itemLabel: 'Producto', opciones: productos, lineas: lineas),
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
                final nombre = nombreCtrl.text.trim();
                final descripcion = descripcionCtrl.text.trim();
                final fechaIngreso = fechaIngresoCtrl.text.trim();
                final estado = int.tryParse(estadoCtrl.text.trim()) ?? 1;
                final mensaje = nombre.isEmpty
                    ? 'El nombre es obligatorio.'
                    : DateTime.tryParse(fechaIngreso) == null
                        ? 'Ingresa una fecha válida (AAAA-MM-DD).'
                        : LineasIngresoEditor.validar(lineas, 'Producto');
                if (mensaje != null) {
                  setState(() => error = mensaje);
                  return;
                }

                Navigator.of(context).pop(IngresoBebida(
                  id: ingreso?.id,
                  nombre: nombre,
                  descripcion: descripcion,
                  fechaIngreso: fechaIngreso,
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
