import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/parametrizacion/producto.dart';
import '../../providers/parametrizacion/producto_provider.dart';
import '../../providers/parametrizacion/tipo_product_provider.dart';
import '../pretty_crud_screen.dart';
import '../producto_imagen.dart';
import '../selector_api.dart';
import '../app_colors.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductoProvider>().fetchProductos();
      // Para mostrar el nombre del tipo en vez de su id.
      context.read<TipoProductProvider>().fetchTiposProducto();
    });
  }

  Future<void> _crear() async {
    final provider = context.read<ProductoProvider>();
    final form = await showProductoFormDialog(context);
    if (form == null || !mounted) return;
    final ok = await provider.createProducto(form.producto, foto: form.foto);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Producto creado' : _errorGuardado('Error al crear producto', form.foto != null))));
  }

  Future<void> _editar(Producto producto) async {
    final provider = context.read<ProductoProvider>();
    final form = await showProductoFormDialog(context, producto: producto);
    if (form == null || !mounted) return;
    final ok = await provider.updateProducto(form.producto, foto: form.foto, quitarFoto: form.quitarFoto);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Producto actualizado'
            : _errorGuardado('Error al actualizar', form.foto != null || form.quitarFoto))));
  }

  /// Con foto el guardado no se puede encolar offline: se avisa que hace falta conexión.
  String _errorGuardado(String base, bool conFoto) =>
      conFoto ? '$base. Para subir la foto se necesita conexión con el servidor.' : base;

  Future<void> _eliminar(Producto producto) async {
    if (!await confirmDelete(context, entity: 'este producto') || !mounted) return;
    final ok = await context.read<ProductoProvider>().deleteProducto(producto.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Producto eliminado' : 'Error al eliminar')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();
    final tipos = {
      for (final t in context.watch<TipoProductProvider>().tiposProducto) t.id: t.nombre,
    };
    return PrettyCrudScreen<Producto>(
      title: 'Productos',
      subtitle: 'Listado de productos registrados.',
      searchHint: 'Buscar por nombre o precio',
      newButtonLabel: 'Nuevo producto',
      isLoading: provider.isLoading,
      error: provider.error,
      onRetry: () => context.read<ProductoProvider>().fetchProductos(),
      items: provider.productos,
      matches: (p, query) => p.nombre.toLowerCase().contains(query) || p.precio.toString().contains(query),
      columns: [
        PrettyColumn(label: 'Nombre', flex: 3, value: (p) => p.nombre),
        PrettyColumn(label: 'Precio', flex: 2, value: (p) => p.getPrecioFormato()),
        PrettyColumn(label: 'Cantidad', flex: 2, value: (p) => p.getCantidadFormato()),
        PrettyColumn(label: 'Tipo', flex: 2, value: (p) => tipos[p.tipoProductoId] ?? '#${p.tipoProductoId}'),
        PrettyColumn(label: 'Estado', flex: 1, value: (p) => p.getEstadoDisplay()),
      ],
      leading: (p) => ProductoImagen(ruta: p.imagen),
      onNew: _crear,
      onEdit: _editar,
      onDelete: _eliminar,
    );
  }
}

typedef ProductoFormResult = ({Producto producto, ProductoFoto? foto, bool quitarFoto});

/// Formulario de producto: datos, tipo (lista de la tabla tipo_productos) y foto.
Future<ProductoFormResult?> showProductoFormDialog(BuildContext context,
    {Producto? producto}) async {
  final tipos = await cargarOpciones('/tipo-productos');
  if (!context.mounted) return null;
  if (tipos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los tipos de producto')));
    return null;
  }

  final nombreCtrl = TextEditingController(text: producto?.nombre ?? '');
  final precioCtrl =
      TextEditingController(text: producto?.precio.toString() ?? '');
  final cantidadActualCtrl =
      TextEditingController(text: producto?.cantidadActual.toString() ?? '');
  final estadoCtrl = TextEditingController(text: producto?.estado ?? '');
  int? tipoProductoId = producto?.tipoProductoId;
  ProductoFoto? foto;
  bool quitarFoto = false;
  String? error;

  final fotoActual = producto?.imagen;
  bool tieneFoto() => foto != null || (!quitarFoto && (fotoActual?.isNotEmpty ?? false));

  return showDialog<ProductoFormResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        Future<void> elegirFoto(ImageSource origen) async {
          // Se reduce la foto para no superar el límite de 2 MB del backend.
          final archivo = await ImagePicker()
              .pickImage(source: origen, maxWidth: 1280, imageQuality: 80);
          if (archivo == null) return;
          final bytes = await archivo.readAsBytes();
          if (!context.mounted) return;
          setState(() {
            foto = ProductoFoto(bytes, archivo.name);
            quitarFoto = false;
          });
        }

        return AlertDialog(
          title: Text(
              producto == null ? 'Nuevo producto' : 'Editar producto'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: foto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(foto!.bytes, fit: BoxFit.cover),
                          )
                        : ProductoImagen(
                            ruta: quitarFoto ? null : fotoActual,
                            borderRadius: BorderRadius.circular(12),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => elegirFoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                      TextButton.icon(
                        onPressed: () => elegirFoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Cámara'),
                      ),
                      if (tieneFoto())
                        TextButton.icon(
                          onPressed: () => setState(() {
                            foto = null;
                            quitarFoto = fotoActual?.isNotEmpty ?? false;
                          }),
                          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                          icon: const Icon(Icons.hide_image_outlined),
                          label: const Text('Quitar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: nombreCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: precioCtrl,
                      decoration: const InputDecoration(labelText: 'Precio (Bs)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 8),
                  SelectorApi(
                      label: 'Tipo de producto',
                      opciones: tipos,
                      valor: tipoProductoId,
                      onChanged: (v) => setState(() => tipoProductoId = v)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: cantidadActualCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Cantidad actual'),
                      keyboardType: TextInputType.number),
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
                final precio = double.tryParse(precioCtrl.text.trim().replaceAll(',', '.'));
                final cantidadActual =
                    double.tryParse(cantidadActualCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
                String? nuevoError;
                if (nombre.isEmpty) {
                  nuevoError = 'Ingresá el nombre del producto.';
                } else if (precio == null || precio < 0) {
                  nuevoError = 'Ingresá un precio válido.';
                } else if (tipoProductoId == null) {
                  nuevoError = 'Seleccioná el tipo de producto.';
                }
                if (nuevoError != null) {
                  setState(() => error = nuevoError);
                  return;
                }

                Navigator.of(context).pop((
                  producto: Producto(
                      id: producto?.id,
                      nombre: nombre,
                      precio: precio!,
                      tipoProductoId: tipoProductoId!,
                      cantidadActual: cantidadActual,
                      estado: estadoCtrl.text.trim(),
                      imagen: fotoActual),
                  foto: foto,
                  quitarFoto: quitarFoto,
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
