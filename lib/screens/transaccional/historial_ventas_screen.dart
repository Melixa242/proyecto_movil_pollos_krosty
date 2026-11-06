import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/venta.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/parametrizacion/cliente_provider.dart';
import '../../providers/parametrizacion/producto_provider.dart';
import '../../providers/transaccional/detalle_venta_provider.dart';
import '../../providers/transaccional/venta_pago_provider.dart';
import '../../providers/transaccional/venta_provider.dart';
import '../app_colors.dart';

/// Historial (sólo lectura) de las ventas realizadas, con filtro por período,
/// búsqueda y detalle de productos y pagos de cada venta.
class HistorialVentasScreen extends StatefulWidget {
  const HistorialVentasScreen({super.key});

  @override
  State<HistorialVentasScreen> createState() => _HistorialVentasScreenState();
}

enum _Periodo {
  hoy('Hoy'),
  semana('Esta semana'),
  mes('Este mes'),
  todas('Todas');

  const _Periodo(this.label);
  final String label;
}

String _bs(double monto) => 'Bs ${monto.toStringAsFixed(2)}';

String _fecha(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} ${dos(fecha.hour)}:${dos(fecha.minute)}';
}

DateTime? _fechaDe(Venta venta) => DateTime.tryParse(venta.fechaVenta)?.toLocal();

IconData _iconoPago(String opcion) => switch (opcion.toLowerCase()) {
      'qr' => Icons.qr_code_2,
      'mixto' => Icons.swap_horiz,
      _ => Icons.payments_outlined,
    };

class _HistorialVentasScreenState extends State<HistorialVentasScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _Periodo _periodo = _Periodo.todas;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _cargar();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    await Future.wait([
      context.read<VentaProvider>().fetchVentas(),
      context.read<ClienteProvider>().fetchClientes(),
      context.read<ProductoProvider>().fetchProductos(),
      context.read<DetalleVentaProvider>().fetchDetalles(),
      context.read<VentaPagoProvider>().fetchPagos(),
    ]);
  }

  Future<void> _nuevaVenta() async {
    await Navigator.pushNamed(context, AppNavigation.ventas);
    // Al volver del punto de venta se recarga para mostrar la venta nueva.
    if (mounted) _cargar();
  }

  bool _enPeriodo(DateTime? fecha) {
    if (_periodo == _Periodo.todas) return true;
    if (fecha == null) return false;
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    return switch (_periodo) {
      _Periodo.hoy => !fecha.isBefore(hoy),
      _Periodo.semana => !fecha.isBefore(hoy.subtract(Duration(days: now.weekday - 1))),
      _Periodo.mes => fecha.year == now.year && fecha.month == now.month,
      _Periodo.todas => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 700;
    final ventaProvider = context.watch<VentaProvider>();
    final clientes = {for (final c in context.watch<ClienteProvider>().clientes) c.id: c.nombre};

    // Más recientes primero (las fechas vienen en ISO 8601, que ordena como texto).
    final visibles = [...ventaProvider.ventas]
      ..retainWhere((v) {
        if (!_enPeriodo(_fechaDe(v))) return false;
        if (_query.isEmpty) return true;
        final cliente = (clientes[v.clienteId] ?? '').toLowerCase();
        return '${v.id}'.contains(_query) ||
            cliente.contains(_query) ||
            v.opcionPago.toLowerCase().contains(_query) ||
            v.observaciones.toLowerCase().contains(_query);
      })
      ..sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
    final totalVendido = visibles.fold(0.0, (suma, v) => suma + v.total);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial de ventas'),
        actions: [IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaVenta,
        elevation: 4,
        icon: const Icon(Icons.point_of_sale, size: 24),
        label: const Text('Nueva venta',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primaryRed,
          onRefresh: _cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 16, isNarrow ? 16 : 24, 96),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Resumen(periodo: _periodo, cantidad: visibles.length, total: totalVendido),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) => TextField(
                        controller: _searchController,
                        onChanged: (t) => setState(() => _query = t.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Buscar por N° de venta, cliente o forma de pago',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: value.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in _Periodo.values)
                          ChoiceChip(
                            label: Text(p.label),
                            selected: _periodo == p,
                            showCheckmark: false,
                            selectedColor: AppColors.primaryRed,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: _periodo == p ? AppColors.primaryRed : AppColors.borderLight),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _periodo == p ? Colors.white : AppColors.textPrimary,
                            ),
                            onSelected: (_) => setState(() => _periodo = p),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (ventaProvider.isLoading && ventaProvider.ventas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (ventaProvider.error != null && ventaProvider.ventas.isEmpty)
                      _Aviso(
                        icono: Icons.cloud_off,
                        texto: ventaProvider.error!,
                        accion: TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                      )
                    else if (visibles.isEmpty)
                      _Aviso(
                        icono: Icons.receipt_long_outlined,
                        texto: ventaProvider.ventas.isEmpty
                            ? 'Todavía no hay ventas registradas.'
                            : 'No hay ventas para este filtro.',
                      )
                    else
                      for (final venta in visibles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _VentaCard(
                            venta: venta,
                            cliente: clientes[venta.clienteId],
                            onTap: () => _mostrarDetalle(context, venta, clientes[venta.clienteId]),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta roja con el total vendido y la cantidad de ventas del filtro actual.
class _Resumen extends StatelessWidget {
  final _Periodo periodo;
  final int cantidad;
  final double total;
  const _Resumen({required this.periodo, required this.cantidad, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryRed, AppColors.primaryRedDark],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x33B8202E), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total vendido · ${periodo.label.toLowerCase()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(_bs(total),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('$cantidad',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(cantidad == 1 ? 'venta' : 'ventas', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VentaCard extends StatelessWidget {
  final Venta venta;
  final String? cliente;
  final VoidCallback onTap;
  const _VentaCard({required this.venta, required this.cliente, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final anulada = venta.estado == 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.rowDivider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.primaryRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Venta #${venta.id ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                        if (anulada) ...[
                          const SizedBox(width: 8),
                          const _Etiqueta(texto: 'Anulada', color: AppColors.primaryRed),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(cliente ?? 'Cliente #${venta.clienteId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(_fecha(_fechaDe(venta)),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_iconoPago(venta.opcionPago), size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(venta.opcionPago.isEmpty ? '-' : venta.opcionPago,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_bs(venta.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: anulada ? AppColors.textSecondary : AppColors.accentGreen,
                    decoration: anulada ? TextDecoration.lineThrough : null,
                  )),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  const _Etiqueta({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Widget? accion;
  const _Aviso({required this.icono, required this.texto, this.accion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
            child: Icon(icono, color: AppColors.primaryRed, size: 28),
          ),
          const SizedBox(height: 12),
          Text(texto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          if (accion != null) ...[const SizedBox(height: 8), accion!],
        ],
      ),
    );
  }
}

/// Hoja inferior con el detalle de la venta: productos, pagos y totales.
void _mostrarDetalle(BuildContext context, Venta venta, String? cliente) {
  final productos = {for (final p in context.read<ProductoProvider>().productos) p.id: p.nombre};
  final detalles = context.read<DetalleVentaProvider>().detalles.where((d) => d.ventaId == venta.id).toList();
  final pagos = context.read<VentaPagoProvider>().pagos.where((p) => p.ventaId == venta.id).toList();
  final subtotal = detalles.fold(0.0, (suma, d) => suma + d.subTotal);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text('Venta #${venta.id ?? '-'}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              if (venta.estado == 0) const _Etiqueta(texto: 'Anulada', color: AppColors.primaryRed),
            ],
          ),
          const SizedBox(height: 12),
          _Dato(icono: Icons.person_outline, etiqueta: 'Cliente', valor: cliente ?? 'Cliente #${venta.clienteId}'),
          _Dato(icono: Icons.schedule, etiqueta: 'Fecha', valor: _fecha(_fechaDe(venta))),
          _Dato(icono: _iconoPago(venta.opcionPago), etiqueta: 'Forma de pago', valor: venta.opcionPago),
          if (venta.observaciones.isNotEmpty)
            _Dato(icono: Icons.notes, etiqueta: 'Observaciones', valor: venta.observaciones),
          const _Titulo('Productos'),
          if (detalles.isEmpty)
            const Text('Sin detalle de productos.', style: TextStyle(color: AppColors.textSecondary))
          else
            for (final d in detalles)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productos[d.productoId] ?? 'Producto #${d.productoId}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text(
                              '${d.cantidad == d.cantidad.roundToDouble() ? d.cantidad.toInt() : d.cantidad} × ${_bs(d.precioUnitario)}',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(_bs(d.subTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          if (pagos.isNotEmpty) ...[
            const _Titulo('Pagos'),
            for (final p in pagos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_iconoPago(p.metodoPago), size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.referencia.isEmpty ? p.metodoPago : '${p.metodoPago} · ${p.referencia}'),
                    ),
                    Text(_bs(p.monto)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          if (detalles.isNotEmpty) _Total(etiqueta: 'Subtotal', valor: _bs(subtotal)),
          if (venta.descuento > 0) _Total(etiqueta: 'Descuento', valor: '- ${_bs(venta.descuento)}'),
          _Total(etiqueta: 'Total', valor: _bs(venta.total), destacado: true),
        ],
      ),
    ),
  );
}

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  const _Dato({required this.icono, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(etiqueta, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(valor.isEmpty ? '-' : valor,
                style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;
  const _Total({required this.etiqueta, required this.valor, this.destacado = false});

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: destacado ? 18 : 14,
      fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
      color: destacado ? AppColors.accentGreen : AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          Text(valor, style: estilo),
        ],
      ),
    );
  }
}
