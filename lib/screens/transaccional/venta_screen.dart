import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parametrizacion/cliente.dart';
import '../../models/parametrizacion/producto.dart';
import '../../models/parametrizacion/tipo_producto.dart';
import '../../models/transaccional/detalle_venta.dart';
import '../../models/transaccional/venta.dart';
import '../../models/transaccional/venta_pago.dart';
import '../../providers/parametrizacion/cliente_provider.dart';
import '../../providers/parametrizacion/producto_provider.dart';
import '../../providers/parametrizacion/tipo_product_provider.dart';
import '../../providers/transaccional/venta_provider.dart';
import '../app_colors.dart';
import '../custom_button.dart';
import '../producto_imagen.dart';
import '../parametrizacion/clientes_screen.dart' show showClienteFormDialog;

class _CartItem {
  final Producto producto;
  double cantidad;
  _CartItem(this.producto, this.cantidad);
  double get subtotal => producto.precio * cantidad;
}

class VentaScreen extends StatefulWidget {
  const VentaScreen({super.key});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> {
  final _searchCtrl = TextEditingController();
  final _efectivoCtrl = TextEditingController(text: '0');
  final _qrCtrl = TextEditingController(text: '0');

  String _query = '';
  int? _categoriaId; // null = "Todos"
  int? _clienteId;
  final List<_CartItem> _cart = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductoProvider>().fetchProductos();
      context.read<TipoProductProvider>().fetchTiposProducto();
      context.read<ClienteProvider>().fetchClientes();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _efectivoCtrl.dispose();
    _qrCtrl.dispose();
    super.dispose();
  }

  double get _total => _cart.fold(0.0, (sum, item) => sum + item.subtotal);

  void _addToCart(Producto p) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.producto.id == p.id);
      if (idx >= 0) {
        _cart[idx].cantidad += 1;
      } else {
        _cart.add(_CartItem(p, 1));
      }
    });
  }

  void _changeQty(_CartItem item, double delta) {
    setState(() {
      final next = item.cantidad + delta;
      if (next <= 0) {
        _cart.remove(item);
      } else {
        item.cantidad = next;
      }
    });
  }

  void _removeFromCart(_CartItem item) => setState(() => _cart.remove(item));

  List<Producto> _filterProductos(List<Producto> productos) {
    return productos.where((p) {
      final matchesCategoria = _categoriaId == null || p.tipoProductoId == _categoriaId;
      final matchesQuery = _query.isEmpty || p.nombre.toLowerCase().contains(_query);
      return matchesCategoria && matchesQuery;
    }).toList();
  }

  Future<void> _crearClienteNuevo() async {
    final created = await showClienteFormDialog(context);
    if (created == null || !mounted) return;
    final clienteProvider = context.read<ClienteProvider>();
    final ok = await clienteProvider.createCliente(created);
    if (ok && mounted) {
      final nuevos = clienteProvider.clientes.where((c) => c.nombre == created.nombre);
      if (nuevos.isNotEmpty) setState(() => _clienteId = nuevos.last.id);
    }
  }

  Future<void> _confirmarVenta() async {
    if (_cart.isEmpty) {
      _showMessage('Agrega al menos un producto al carrito.');
      return;
    }
    if (_clienteId == null) {
      _showMessage('Selecciona un cliente para la venta.');
      return;
    }
    final efectivo = double.tryParse(_efectivoCtrl.text.trim()) ?? 0.0;
    final qr = double.tryParse(_qrCtrl.text.trim()) ?? 0.0;
    if (efectivo + qr < _total) {
      _showMessage('El monto pagado no cubre el total de la venta.');
      return;
    }

    setState(() => _guardando = true);

    final ventaProvider = context.read<VentaProvider>();

    // Los pagos deben sumar exactamente el total: el vuelto sale del efectivo.
    final montoQr = double.parse((qr < _total ? qr : _total).toStringAsFixed(2));
    final montoEfectivo = double.parse((_total - montoQr).toStringAsFixed(2));
    final opcionPago = montoEfectivo > 0 && montoQr > 0 ? 'Mixto' : (montoQr > 0 ? 'QR' : 'Efectivo');

    final ventaId = await ventaProvider.crearVentaConId(
      Venta(
        clienteId: _clienteId!,
        fechaVenta: DateTime.now().toIso8601String(),
        observaciones: '',
        opcionPago: opcionPago,
        descuento: 0,
        total: _total,
        estado: 1,
      ),
      [
        for (final item in _cart)
          DetalleVenta(
            ventaId: 0, // lo asigna el servidor
            productoId: item.producto.id!,
            precioUnitario: item.producto.precio,
            cantidad: item.cantidad,
            subTotal: item.subtotal,
            estado: 1,
          ),
      ],
      [
        if (montoEfectivo > 0) VentaPago(ventaId: 0, metodoPago: 'Efectivo', monto: montoEfectivo, referencia: '', estado: 1),
        if (montoQr > 0) VentaPago(ventaId: 0, metodoPago: 'QR', monto: montoQr, referencia: '', estado: 1),
      ],
    );

    if (!mounted) return;
    if (ventaId == null) {
      setState(() => _guardando = false);
      _showMessage(ventaProvider.error ?? 'Error al registrar la venta.');
      return;
    }

    setState(() {
      _cart.clear();
      _clienteId = null;
      _efectivoCtrl.text = '0';
      _qrCtrl.text = '0';
      _guardando = false;
    });
    // Id negativo = el servidor no respondió y la venta quedó en la cola offline.
    _showMessage(ventaId < 0
        ? 'Sin conexión con el servidor: la venta quedó pendiente y se enviará al reconectar.'
        : 'Venta registrada correctamente.');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final productoProvider = context.watch<ProductoProvider>();
    final tipoProvider = context.watch<TipoProductProvider>();
    final clienteProvider = context.watch<ClienteProvider>();
    final productosVisibles = _filterProductos(productoProvider.productos);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onBack: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;
                  final productosPanel = _ProductosPanel(
                    searchController: _searchCtrl,
                    onQueryChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    tiposProducto: tipoProvider.tiposProducto,
                    categoriaSeleccionada: _categoriaId,
                    onCategoriaChanged: (id) => setState(() => _categoriaId = id),
                    isLoading: productoProvider.isLoading,
                    error: productoProvider.error,
                    productos: productosVisibles,
                    onTapProducto: _addToCart,
                  );
                  final ventaPanel = _VentaPanel(
                    clientes: clienteProvider.clientes,
                    clienteId: _clienteId,
                    onClienteChanged: (id) => setState(() => _clienteId = id),
                    onCrearCliente: _crearClienteNuevo,
                    cart: _cart,
                    total: _total,
                    onIncrement: (item) => _changeQty(item, 1),
                    onDecrement: (item) => _changeQty(item, -1),
                    onRemove: _removeFromCart,
                    efectivoController: _efectivoCtrl,
                    qrController: _qrCtrl,
                    guardando: _guardando,
                    onConfirmar: _confirmarVenta,
                  );

                  if (isNarrow) {
                    return Column(children: [productosPanel, const SizedBox(height: 20), ventaPanel]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: productosPanel),
                      const SizedBox(width: 20),
                      SizedBox(width: 360, child: ventaPanel),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Punto de Venta',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
              SizedBox(height: 4),
              Text('Crear una nueva venta para cliente.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
        AppButton(label: 'Volver', icon: Icons.arrow_back, variant: ButtonVariant.outline, onPressed: onBack),
      ],
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
      ),
      child: child,
    );
  }
}

class _ProductosPanel extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final List<TipoProducto> tiposProducto;
  final int? categoriaSeleccionada;
  final ValueChanged<int?> onCategoriaChanged;
  final bool isLoading;
  final String? error;
  final List<Producto> productos;
  final ValueChanged<Producto> onTapProducto;

  const _ProductosPanel({
    required this.searchController,
    required this.onQueryChanged,
    required this.tiposProducto,
    required this.categoriaSeleccionada,
    required this.onCategoriaChanged,
    required this.isLoading,
    required this.error,
    required this.productos,
    required this.onTapProducto,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480;
            final title = const Row(children: [
              Icon(Icons.restaurant, color: AppColors.primaryRed),
              SizedBox(width: 8),
              Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]);
            final search = TextField(
              controller: searchController,
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: 'Buscar producto...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.6)),
              ),
            );
            if (isNarrow) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 12), search]);
            }
            return Row(children: [title, const Spacer(), SizedBox(width: 260, child: search)]);
          }),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryChip(label: 'Todos', selected: categoriaSeleccionada == null, onTap: () => onCategoriaChanged(null)),
              for (final tipo in tiposProducto)
                _CategoryChip(
                  label: tipo.nombre,
                  selected: categoriaSeleccionada == tipo.id,
                  onTap: () => onCategoriaChanged(tipo.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.rowDivider),
          const SizedBox(height: 16),
          if (isLoading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()))
          else if (error != null)
            Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text(error!, style: const TextStyle(color: AppColors.primaryRed)))
          else if (productos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No se encontraron productos.', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            LayoutBuilder(builder: (context, constraints) {
              // Con foto, al menos 2 columnas también en el móvil.
              final crossAxisCount = (constraints.maxWidth ~/ 170).clamp(2, 5);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) => _ProductoCard(producto: productos[index], onTap: () => onTapProducto(productos[index])),
              );
            }),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryRed : AppColors.tableHeaderBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primaryRed : AppColors.rowDivider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  const _ProductoCard({required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.rowDivider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductoImagen(
                      ruta: producto.imagen,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    // Indica que tocar la tarjeta agrega el producto al carrito.
                    const Positioned(
                      right: 6,
                      bottom: 6,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryRed,
                        child: Icon(Icons.add, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.2, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Bs ${producto.precio.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VentaPanel extends StatelessWidget {
  final List<Cliente> clientes;
  final int? clienteId;
  final ValueChanged<int?> onClienteChanged;
  final VoidCallback onCrearCliente;
  final List<_CartItem> cart;
  final double total;
  final ValueChanged<_CartItem> onIncrement;
  final ValueChanged<_CartItem> onDecrement;
  final ValueChanged<_CartItem> onRemove;
  final TextEditingController efectivoController;
  final TextEditingController qrController;
  final bool guardando;
  final VoidCallback onConfirmar;

  const _VentaPanel({
    required this.clientes,
    required this.clienteId,
    required this.onClienteChanged,
    required this.onCrearCliente,
    required this.cart,
    required this.total,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.efectivoController,
    required this.qrController,
    required this.guardando,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              OutlinedButton.icon(
                onPressed: onCrearCliente,
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('Crear cliente nuevo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: clienteId,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Seleccionar cliente...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
            ),
            items: clientes.where((c) => c.id != null).map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
            onChanged: onClienteChanged,
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.rowDivider),
          const SizedBox(height: 16),
          if (cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 42, color: AppColors.borderLight),
                    SizedBox(height: 8),
                    Text('El carrito está vacío', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Column(children: cart.map((item) => _CartRow(item: item, onIncrement: () => onIncrement(item), onDecrement: () => onDecrement(item), onRemove: () => onRemove(item))).toList()),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.rowDivider),
          const SizedBox(height: 16),
          const Text('Pagos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MontoField(label: 'Efectivo (Bs)', controller: efectivoController)),
              const SizedBox(width: 10),
              Expanded(child: _MontoField(label: 'QR (Bs)', controller: qrController)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('Bs ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: guardando ? 'Guardando...' : 'Registrar venta',
            icon: Icons.point_of_sale,
            expand: true,
            onPressed: guardando ? null : onConfirmar,
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final _CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartRow({required this.item, required this.onIncrement, required this.onDecrement, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ProductoImagen(ruta: item.producto.imagen, width: 44, height: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('Bs ${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          IconButton(onPressed: onDecrement, icon: const Icon(Icons.remove_circle_outline, size: 20), visualDensity: VisualDensity.compact),
          Text('${item.cantidad.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(onPressed: onIncrement, icon: const Icon(Icons.add_circle_outline, size: 20), visualDensity: VisualDensity.compact),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.primaryRed), visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class _MontoField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _MontoField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
          ),
        ),
      ],
    );
  }
}
