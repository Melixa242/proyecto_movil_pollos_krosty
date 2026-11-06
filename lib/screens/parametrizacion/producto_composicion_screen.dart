import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parametrizacion/producto_composicion.dart';
import '../../providers/parametrizacion/produc_composicion_provider.dart';
import '../app_colors.dart';
import '../pretty_crud_screen.dart';
import '../selector_api.dart';

class ProductoComposicionScreen extends StatefulWidget {
  const ProductoComposicionScreen({super.key});

  @override
  State<ProductoComposicionScreen> createState() =>
      _ProductoComposicionScreenState();
}

class _ProductoComposicionScreenState extends State<ProductoComposicionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductoComposicionProvider>().fetchComposiciones();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<ProductoComposicionProvider>();
    final nueva = await showNuevaComposicionDialog(context);
    if (nueva == null || !mounted) return;
    final ok = await provider.createComposiciones(nueva.padreId, nueva.hijos);
    if (!mounted) return;
    final n = nueva.hijos.length;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Composición guardada con $n ${n == 1 ? 'producto hijo' : 'productos hijos'}'
            : provider.errorGuardado ?? 'Error al crear composición')));
  }

  Future<void> _editar(ProductoComposicion pc) async {
    final provider = context.read<ProductoComposicionProvider>();
    final updated = await showComposicionFormDialog(context, composicion: pc);
    if (updated == null || !mounted) return;
    final ok = await provider.updateComposicion(pc, updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Composición actualizada' : provider.errorGuardado ?? 'Error al actualizar')));
  }

  Future<void> _eliminar(ProductoComposicion pc) async {
    if (!await confirmDelete(context, entity: 'esta composición') || !mounted) return;
    final provider = context.read<ProductoComposicionProvider>();
    final ok = await provider.deleteComposicion(pc);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Composición eliminada' : provider.errorGuardado ?? 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoComposicionProvider>();
    return PrettyCrudScreen<ProductoComposicion>(
      title: 'Composiciones',
      subtitle: 'Gestión de composiciones de productos.',
      searchHint: 'Buscar por producto padre o hijo',
      newButtonLabel: 'Nueva composición',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<ProductoComposicionProvider>().fetchComposiciones(),
      items: provider.composiciones,
      matches: (c, query) =>
          c.padreDisplay.toLowerCase().contains(query) ||
          c.hijoDisplay.toLowerCase().contains(query) ||
          c.getCantidadFormato().contains(query),
      columns: [
        PrettyColumn(label: 'Producto padre', flex: 2, value: (c) => c.padreDisplay),
        PrettyColumn(label: 'Producto hijo', flex: 2, value: (c) => c.hijoDisplay),
        PrettyColumn(label: 'Cantidad', flex: 1, value: (c) => c.getCantidadFormato()),
        PrettyColumn(label: 'Estado', flex: 1, value: (c) => c.getEstadoDisplay()),
      ],
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

/// Una línea "producto hijo + cantidad" del formulario de nueva composición.
/// La [key] mantiene el estado de cada desplegable al quitar líneas del medio.
class _LineaHijo {
  _LineaHijo(this.key);
  final Key key;
  int? hijoId;
  final cantidad = TextEditingController();
}

typedef NuevaComposicion = ({int padreId, List<ProductoComposicion> hijos});

/// Alta de composición: un producto padre y uno o más productos hijos con su cantidad.
Future<NuevaComposicion?> showNuevaComposicionDialog(BuildContext context) async {
  final productos = await cargarOpciones('/productos');
  if (!context.mounted) return null;
  if (productos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los productos')));
    return null;
  }
  final existentes = context.read<ProductoComposicionProvider>().composiciones;

  var siguienteKey = 0;
  _LineaHijo nuevaLinea() => _LineaHijo(ValueKey(siguienteKey++));
  int? padreId;
  final lineas = [nuevaLinea()];
  String? error;

  String? validar() {
    if (padreId == null) return 'Seleccioná el producto padre.';
    final vistos = <int>{};
    for (var i = 0; i < lineas.length; i++) {
      final linea = lineas[i];
      final n = i + 1;
      if (linea.hijoId == null) return 'Seleccioná el producto hijo $n.';
      if (linea.hijoId == padreId) return 'El producto hijo $n es el mismo que el padre.';
      if (!vistos.add(linea.hijoId!)) return 'El producto hijo $n está repetido.';
      final cantidad = double.tryParse(linea.cantidad.text.trim().replaceAll(',', '.'));
      if (cantidad == null || cantidad <= 0) return 'La cantidad del producto hijo $n debe ser mayor a 0.';
    }
    return null;
  }

  return showDialog<NuevaComposicion>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        final yaTiene = padreId == null
            ? 0
            : existentes.where((c) => c.productoPadreId == padreId).length;
        return AlertDialog(
          title: const Text('Nueva composición'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectorApi(
                      label: 'Producto padre',
                      opciones: productos,
                      valor: padreId,
                      onChanged: (v) => setState(() {
                            padreId = v;
                            error = null;
                          })),
                  if (yaTiene > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Este producto ya tiene $yaTiene ${yaTiene == 1 ? 'ingrediente' : 'ingredientes'}. '
                        'Los nuevos se agregan; si repetís uno, se actualiza su cantidad.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primaryRed),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('Productos hijos',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${lineas.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryRed)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < lineas.length; i++)
                    Padding(
                      key: lineas[i].key,
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SelectorApi(
                                label: 'Producto hijo ${i + 1}',
                                opciones: productos,
                                valor: lineas[i].hijoId,
                                onChanged: (v) => setState(() {
                                      lineas[i].hijoId = v;
                                      error = null;
                                    })),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 88,
                            child: TextField(
                                controller: lineas[i].cantidad,
                                decoration: const InputDecoration(labelText: 'Cant.'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          ),
                          IconButton(
                            tooltip: 'Quitar',
                            color: AppColors.primaryRed,
                            icon: const Icon(Icons.remove_circle_outline),
                            // Siempre queda al menos un hijo.
                            onPressed: lineas.length == 1
                                ? null
                                : () => setState(() {
                                      lineas.removeAt(i);
                                      error = null;
                                    }),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => lineas.add(nuevaLinea())),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Agregar producto hijo'),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
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
                final nuevoError = validar();
                if (nuevoError != null) {
                  setState(() => error = nuevoError);
                  return;
                }
                Navigator.of(context).pop((
                  padreId: padreId!,
                  hijos: [
                    for (final linea in lineas)
                      ProductoComposicion(
                        id: padreId,
                        productoPadreId: padreId!,
                        productoHijoId: linea.hijoId!,
                        cantidad: double.parse(linea.cantidad.text.trim().replaceAll(',', '.')),
                      ),
                  ],
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

Future<ProductoComposicion?> showComposicionFormDialog(BuildContext context,
    {ProductoComposicion? composicion}) async {
  final productos = await cargarOpciones('/productos');
  if (!context.mounted) return null;
  if (productos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los productos')));
    return null;
  }

  int? padreId = composicion?.productoPadreId;
  int? hijoId = composicion?.productoHijoId;
  final cantidadCtrl = TextEditingController(
      text: composicion == null ? '' : composicion.getCantidadFormato());
  String? error;

  return showDialog<ProductoComposicion>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(composicion == null
              ? 'Nueva composición'
              : 'Editar composición'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectorApi(
                      label: 'Producto padre',
                      opciones: productos,
                      valor: padreId,
                      onChanged: (v) => setState(() => padreId = v)),
                  const SizedBox(height: 8),
                  SelectorApi(
                      label: 'Producto hijo (ingrediente)',
                      opciones: productos,
                      valor: hijoId,
                      onChanged: (v) => setState(() => hijoId = v)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: cantidadCtrl,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
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
                final cantidad = double.tryParse(
                    cantidadCtrl.text.trim().replaceAll(',', '.'));
                String? nuevoError;
                if (padreId == null || hijoId == null) {
                  nuevoError = 'Seleccioná el producto padre y el hijo.';
                } else if (padreId == hijoId) {
                  nuevoError = 'Un producto no puede ser ingrediente de sí mismo.';
                } else if (cantidad == null || cantidad <= 0) {
                  nuevoError = 'La cantidad debe ser mayor a 0.';
                }
                if (nuevoError != null) {
                  setState(() => error = nuevoError);
                  return;
                }

                Navigator.of(context).pop(ProductoComposicion(
                    id: padreId,
                    productoPadreId: padreId!,
                    productoHijoId: hijoId!,
                    cantidad: cantidad!));
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      });
    },
  );
}
