import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaccional/venta.dart';
import '../../providers/parametrizacion/producto_provider.dart';
import '../../providers/transaccional/detalle_venta_provider.dart';
import '../../providers/transaccional/venta_pago_provider.dart';
import '../../providers/transaccional/venta_provider.dart';
import '../app_colors.dart';
import '../producto_imagen.dart';

/// Reporte de ventas por día, semana, mes o año: indicadores, gráfico de
/// barras por hora/día/mes, formas de pago, productos más vendidos y tabla.
/// Las ventas anuladas (estado 0) no se cuentan.
class ReporteVentasScreen extends StatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

enum _Periodo {
  dia('Día', 'día anterior', 'Ventas por hora'),
  semana('Semana', 'semana anterior', 'Ventas por día'),
  mes('Mes', 'mes anterior', 'Ventas por día'),
  anio('Año', 'año anterior', 'Ventas por mes');

  const _Periodo(this.label, this.anterior, this.tituloGrafico);
  final String label;
  final String anterior;
  final String tituloGrafico;
}

const _diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _diasLargos = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const _mesesCortos = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
const _mesesLargos = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

String _dos(int n) => n.toString().padLeft(2, '0');
String _bs(double monto) => 'Bs ${monto.toStringAsFixed(2)}';
String _ddmm(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}';

/// Montos cortos para el eje del gráfico (1.2k, 15k).
String _compacto(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return '${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
  }
  return v.toStringAsFixed(0);
}

/// Inicio (incluido) y fin (excluido) del período que contiene [ancla].
(DateTime, DateTime) _rango(_Periodo p, DateTime a) => switch (p) {
      _Periodo.dia => (DateTime(a.year, a.month, a.day), DateTime(a.year, a.month, a.day + 1)),
      _Periodo.semana => (
          DateTime(a.year, a.month, a.day - (a.weekday - 1)),
          DateTime(a.year, a.month, a.day - (a.weekday - 1) + 7),
        ),
      _Periodo.mes => (DateTime(a.year, a.month), DateTime(a.year, a.month + 1)),
      _Periodo.anio => (DateTime(a.year), DateTime(a.year + 1)),
    };

DateTime _mover(_Periodo p, DateTime a, int n) => switch (p) {
      _Periodo.dia => DateTime(a.year, a.month, a.day + n),
      _Periodo.semana => DateTime(a.year, a.month, a.day + 7 * n),
      _Periodo.mes => DateTime(a.year, a.month + n),
      _Periodo.anio => DateTime(a.year + n),
    };

int _cantidadBarras(_Periodo p, DateTime inicio) => switch (p) {
      _Periodo.dia => 24,
      _Periodo.semana => 7,
      _Periodo.mes => DateTime(inicio.year, inicio.month + 1, 0).day,
      _Periodo.anio => 12,
    };

int _indiceBarra(_Periodo p, DateTime f) => switch (p) {
      _Periodo.dia => f.hour,
      _Periodo.semana => f.weekday - 1,
      _Periodo.mes => f.day - 1,
      _Periodo.anio => f.month - 1,
    };

String _etiquetaEje(_Periodo p, int i) => switch (p) {
      _Periodo.dia => '${i}h',
      _Periodo.semana => _diasCortos[i],
      _Periodo.mes => '${i + 1}',
      _Periodo.anio => _mesesCortos[i],
    };

/// En día y mes hay muchas barras: se rotulan sólo algunas para que no se encimen.
bool _mostrarEtiqueta(_Periodo p, int i) => switch (p) {
      _Periodo.dia => i % 3 == 0,
      _Periodo.mes => i == 0 || (i + 1) % 5 == 0,
      _ => true,
    };

String _etiquetaBarra(_Periodo p, DateTime inicio, int i) => switch (p) {
      _Periodo.dia => '${_dos(i)}:00 – ${_dos(i)}:59',
      _Periodo.semana => '${_diasLargos[i]} ${_ddmm(DateTime(inicio.year, inicio.month, inicio.day + i))}',
      _Periodo.mes => '${i + 1} de ${_mesesLargos[inicio.month - 1].toLowerCase()}',
      _Periodo.anio => '${_mesesLargos[i]} ${inicio.year}',
    };

String _tituloPeriodo(_Periodo p, DateTime inicio, DateTime fin) {
  final hoy = DateTime.now();
  switch (p) {
    case _Periodo.dia:
      final dif = DateTime(hoy.year, hoy.month, hoy.day).difference(inicio).inDays;
      final base = '${_diasLargos[inicio.weekday - 1]} ${_ddmm(inicio)}/${inicio.year}';
      return dif == 0 ? 'Hoy · $base' : (dif == 1 ? 'Ayer · $base' : base);
    case _Periodo.semana:
      final ultimo = fin.subtract(const Duration(days: 1));
      return '${_ddmm(inicio)} – ${_ddmm(ultimo)}/${ultimo.year}';
    case _Periodo.mes:
      return '${_mesesLargos[inicio.month - 1]} ${inicio.year}';
    case _Periodo.anio:
      return '${inicio.year}';
  }
}

/// Totales de un período ya calculados para la vista.
class _Datos {
  final List<Venta> ventas;
  final double total;
  final List<double> montos;
  final List<int> cantidades;
  const _Datos(this.ventas, this.total, this.montos, this.cantidades);
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen> {
  _Periodo _periodo = _Periodo.dia;
  DateTime _ancla = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _cargar();
    });
  }

  Future<void> _cargar() async {
    await Future.wait([
      context.read<VentaProvider>().fetchVentas(),
      context.read<DetalleVentaProvider>().fetchDetalles(),
      context.read<VentaPagoProvider>().fetchPagos(),
      context.read<ProductoProvider>().fetchProductos(),
    ]);
  }

  _Datos _calcular(List<Venta> todas, DateTime inicio, DateTime fin) {
    final n = _cantidadBarras(_periodo, inicio);
    final montos = List<double>.filled(n, 0);
    final cantidades = List<int>.filled(n, 0);
    final ventas = <Venta>[];
    for (final v in todas) {
      if (v.estado == 0) continue;
      final fecha = DateTime.tryParse(v.fechaVenta)?.toLocal();
      if (fecha == null || fecha.isBefore(inicio) || !fecha.isBefore(fin)) continue;
      ventas.add(v);
      final i = _indiceBarra(_periodo, fecha);
      montos[i] += v.total;
      cantidades[i]++;
    }
    return _Datos(ventas, montos.fold(0.0, (a, b) => a + b), montos, cantidades);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final ventaProvider = context.watch<VentaProvider>();
    final todas = ventaProvider.ventas;

    final (inicio, fin) = _rango(_periodo, _ancla);
    final (inicioAnt, finAnt) = _rango(_periodo, _mover(_periodo, _ancla, -1));
    final actual = _calcular(todas, inicio, fin);
    final anterior = _calcular(todas, inicioAnt, finAnt);
    // El período en curso es el último navegable: no se avanza hacia el futuro.
    final now = DateTime.now();
    final esPeriodoActual = !inicio.isAfter(now) && now.isBefore(fin);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reporte de ventas'),
        actions: [IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primaryRed,
          onRefresh: _cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isWide ? 24 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---------- Filtros: período + navegación ----------
                    SegmentedButton<_Periodo>(
                      segments: [
                        for (final p in _Periodo.values) ButtonSegment(value: p, label: Text(p.label)),
                      ],
                      selected: {_periodo},
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.primaryRed,
                        selectedForegroundColor: Colors.white,
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderLight),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onSelectionChanged: (s) => setState(() {
                        _periodo = s.first;
                        _ancla = DateTime.now();
                      }),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton.outlined(
                          tooltip: '${_periodo.label} anterior',
                          onPressed: () => setState(() => _ancla = _mover(_periodo, _ancla, -1)),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            _tituloPeriodo(_periodo, inicio, fin),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: '${_periodo.label} siguiente',
                          onPressed: esPeriodoActual ? null : () => setState(() => _ancla = _mover(_periodo, _ancla, 1)),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (ventaProvider.isLoading && todas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (ventaProvider.error != null && todas.isEmpty)
                      _Tarjeta(
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off, color: AppColors.primaryRed, size: 32),
                            const SizedBox(height: 8),
                            Text(ventaProvider.error!, textAlign: TextAlign.center),
                            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                          ],
                        ),
                      )
                    else ...[
                      _Indicadores(actual: actual, anterior: anterior, periodo: _periodo),
                      const SizedBox(height: 16),
                      _Tarjeta(
                        titulo: _periodo.tituloGrafico,
                        child: _GraficoBarras(
                          montos: actual.montos,
                          cantidades: actual.cantidades,
                          etiquetaEje: (i) => _etiquetaEje(_periodo, i),
                          mostrarEtiqueta: (i) => _mostrarEtiqueta(_periodo, i),
                          etiquetaBarra: (i) => _etiquetaBarra(_periodo, inicio, i),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _FormasDePago(ventas: actual.ventas)),
                            const SizedBox(width: 16),
                            Expanded(child: _TopProductos(ventas: actual.ventas)),
                          ],
                        )
                      else ...[
                        _FormasDePago(ventas: actual.ventas),
                        const SizedBox(height: 16),
                        _TopProductos(ventas: actual.ventas),
                      ],
                      const SizedBox(height: 16),
                      _TablaPorBarra(
                        periodo: _periodo,
                        inicio: inicio,
                        montos: actual.montos,
                        cantidades: actual.cantidades,
                      ),
                      const SizedBox(height: 16),
                      _Detalle(ventas: actual.ventas),
                    ],
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

// =====================================================================
// PIEZAS DE LA VISTA
// =====================================================================

class _Tarjeta extends StatelessWidget {
  final String? titulo;
  final Widget child;
  const _Tarjeta({this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titulo != null) ...[
            Text(titulo!,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Cuatro cifras clave del período, con la variación respecto al anterior.
class _Indicadores extends StatelessWidget {
  final _Datos actual;
  final _Datos anterior;
  final _Periodo periodo;
  const _Indicadores({required this.actual, required this.anterior, required this.periodo});

  @override
  Widget build(BuildContext context) {
    final n = actual.ventas.length;
    final ticket = n == 0 ? 0.0 : actual.total / n;
    final tiles = [
      _Cifra(titulo: 'Total vendido', valor: _bs(actual.total), icono: Icons.payments_outlined, destacado: true),
      _Cifra(titulo: 'Ventas', valor: '$n', icono: Icons.receipt_long_outlined),
      _Cifra(titulo: 'Ticket promedio', valor: _bs(ticket), icono: Icons.shopping_basket_outlined),
      _Variacion(actual: actual.total, anterior: anterior.total, etiqueta: 'vs ${periodo.anterior}'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columnas = constraints.maxWidth >= 760 ? 4 : 2;
      final ancho = (constraints.maxWidth - 12 * (columnas - 1)) / columnas;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final t in tiles) SizedBox(width: ancho, height: 104, child: t)],
      );
    });
  }
}

class _Cifra extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final bool destacado;
  const _Cifra({required this.titulo, required this.valor, required this.icono, this.destacado = false});

  @override
  Widget build(BuildContext context) {
    final fg = destacado ? Colors.white : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: destacado ? AppColors.primaryRed : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: destacado ? null : Border.all(color: AppColors.rowDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: destacado ? Colors.white70 : AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: destacado ? Colors.white70 : AppColors.textSecondary)),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg)),
          ),
        ],
      ),
    );
  }
}

/// Variación porcentual con ícono + texto (nunca sólo color).
class _Variacion extends StatelessWidget {
  final double actual;
  final double anterior;
  final String etiqueta;
  const _Variacion({required this.actual, required this.anterior, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final String valor;
    final IconData icono;
    final Color color;
    if (anterior <= 0) {
      valor = actual > 0 ? 'Nuevo' : '—';
      icono = Icons.remove;
      color = AppColors.textSecondary;
    } else {
      final delta = (actual - anterior) / anterior * 100;
      valor = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%';
      icono = delta > 0 ? Icons.trending_up : (delta < 0 ? Icons.trending_down : Icons.trending_flat);
      color = delta > 0 ? AppColors.accentGreen : (delta < 0 ? AppColors.primaryRed : AppColors.textSecondary);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          Row(
            children: [
              Icon(icono, color: color, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valor,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
              ),
            ],
          ),
          Text('Antes: ${_bs(anterior)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Barras de una sola serie (monto vendido). Tocar o pasar el mouse por una
/// barra muestra su detalle arriba del gráfico.
class _GraficoBarras extends StatefulWidget {
  final List<double> montos;
  final List<int> cantidades;
  final String Function(int i) etiquetaEje;
  final bool Function(int i) mostrarEtiqueta;
  final String Function(int i) etiquetaBarra;

  const _GraficoBarras({
    required this.montos,
    required this.cantidades,
    required this.etiquetaEje,
    required this.mostrarEtiqueta,
    required this.etiquetaBarra,
  });

  @override
  State<_GraficoBarras> createState() => _GraficoBarrasState();
}

class _GraficoBarrasState extends State<_GraficoBarras> {
  int? _seleccion;

  static const double _alto = 180;
  static const double _anchoEje = 40;

  @override
  void didUpdateWidget(covariant _GraficoBarras oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Al cambiar de período cambia la cantidad de barras.
    if (oldWidget.montos.length != widget.montos.length) _seleccion = null;
  }

  @override
  Widget build(BuildContext context) {
    final maximo = widget.montos.fold(0.0, (a, b) => a > b ? a : b);
    // Escala redondeada hacia arriba para que el eje muestre números limpios.
    final tope = maximo <= 0 ? 1.0 : _redondearEscala(maximo);
    final i = _seleccion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Detalle de la barra seleccionada (reemplaza al tooltip flotante en móvil).
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          child: i == null
              ? Text(
                  maximo <= 0 ? 'Sin ventas en este período.' : 'Tocá una barra para ver el detalle.',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(widget.etiquetaBarra(i),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    Text('${widget.cantidades[i]} ${widget.cantidades[i] == 1 ? 'venta' : 'ventas'} · ',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    Text(_bs(widget.montos[i]),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _alto,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Eje Y: tope, mitad y cero.
              SizedBox(
                width: _anchoEje,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final v in [tope, tope / 2, 0.0])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(_compacto(v), style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Cuadrícula discreta.
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var k = 0; k < 3; k++)
                          Container(height: 1, color: k == 2 ? AppColors.borderLight : AppColors.rowDivider),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var b = 0; b < widget.montos.length; b++)
                          Expanded(
                            // El área táctil es toda la columna, más grande que la barra.
                            child: MouseRegion(
                              onEnter: (_) => setState(() => _seleccion = b),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() => _seleccion = _seleccion == b ? null : b),
                                child: Padding(
                                  // 2px de separación entre barras vecinas.
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      widthFactor: widget.montos.length > 12 ? 1 : 0.6,
                                      heightFactor: (widget.montos[b] / tope).clamp(0.0, 1.0),
                                      child: Container(
                                        constraints: BoxConstraints(minHeight: widget.montos[b] > 0 ? 2 : 0),
                                        decoration: BoxDecoration(
                                          color: _seleccion == null || _seleccion == b
                                              ? AppColors.primaryRed
                                              : AppColors.primaryRed.withValues(alpha: 0.35),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Eje X.
        Row(
          children: [
            const SizedBox(width: _anchoEje),
            for (var b = 0; b < widget.montos.length; b++)
              Expanded(
                child: widget.mostrarEtiqueta(b)
                    ? Text(widget.etiquetaEje(b),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: _seleccion == b ? FontWeight.bold : FontWeight.normal,
                          color: _seleccion == b ? AppColors.textPrimary : AppColors.textSecondary,
                        ))
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ],
    );
  }

  /// 1, 2 o 5 por potencia de 10 (p. ej. 730 → 1000, 180 → 200).
  static double _redondearEscala(double v) {
    var base = 1.0;
    while (base * 10 <= v) {
      base *= 10;
    }
    for (final m in [1, 2, 5, 10]) {
      if (base * m >= v) return base * m;
    }
    return base * 10;
  }
}

/// Monto cobrado por método de pago (Efectivo / QR), según los pagos registrados.
class _FormasDePago extends StatelessWidget {
  final List<Venta> ventas;
  const _FormasDePago({required this.ventas});

  @override
  Widget build(BuildContext context) {
    final ids = ventas.map((v) => v.id).toSet();
    final porMetodo = <String, double>{};
    final pagos = context.watch<VentaPagoProvider>().pagos.where((p) => ids.contains(p.ventaId));
    for (final p in pagos) {
      final metodo = p.metodoPago.isEmpty ? 'Otro' : p.metodoPago;
      porMetodo[metodo] = (porMetodo[metodo] ?? 0) + p.monto;
    }
    // Sin pagos registrados se usa la forma de pago de la venta.
    if (porMetodo.isEmpty) {
      for (final v in ventas) {
        final metodo = v.opcionPago.isEmpty ? 'Otro' : v.opcionPago;
        porMetodo[metodo] = (porMetodo[metodo] ?? 0) + v.total;
      }
    }
    final total = porMetodo.values.fold(0.0, (a, b) => a + b);
    final filas = porMetodo.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return _Tarjeta(
      titulo: 'Formas de pago',
      child: filas.isEmpty
          ? const Text('Sin cobros en este período.', style: TextStyle(color: AppColors.textSecondary))
          : Column(
              children: [
                for (final f in filas)
                  _BarraHorizontal(
                    icono: switch (f.key.toLowerCase()) {
                      'qr' => Icons.qr_code_2,
                      'mixto' => Icons.swap_horiz,
                      _ => Icons.payments_outlined,
                    },
                    etiqueta: f.key,
                    valor: _bs(f.value),
                    proporcion: total == 0 ? 0 : f.value / total,
                    detalle: '${(total == 0 ? 0 : f.value / total * 100).toStringAsFixed(0)}%',
                  ),
              ],
            ),
    );
  }
}

/// Los 5 productos con mayor monto vendido en el período.
class _TopProductos extends StatelessWidget {
  final List<Venta> ventas;
  const _TopProductos({required this.ventas});

  @override
  Widget build(BuildContext context) {
    final ids = ventas.map((v) => v.id).toSet();
    final productos = {for (final p in context.watch<ProductoProvider>().productos) p.id: p};
    final montos = <int, double>{};
    final unidades = <int, double>{};
    for (final d in context.watch<DetalleVentaProvider>().detalles) {
      if (!ids.contains(d.ventaId)) continue;
      montos[d.productoId] = (montos[d.productoId] ?? 0) + d.subTotal;
      unidades[d.productoId] = (unidades[d.productoId] ?? 0) + d.cantidad;
    }
    final top = montos.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maximo = top.isEmpty ? 0.0 : top.first.value;

    return _Tarjeta(
      titulo: 'Productos más vendidos',
      child: top.isEmpty
          ? const Text('Sin productos vendidos en este período.', style: TextStyle(color: AppColors.textSecondary))
          : Column(
              children: [
                for (final e in top.take(5))
                  _BarraHorizontal(
                    imagen: productos[e.key]?.imagen,
                    etiqueta: productos[e.key]?.nombre ?? 'Producto #${e.key}',
                    valor: _bs(e.value),
                    proporcion: maximo == 0 ? 0 : e.value / maximo,
                    detalle: '${_unidades(unidades[e.key] ?? 0)} u.',
                  ),
              ],
            ),
    );
  }

  static String _unidades(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
}

class _BarraHorizontal extends StatelessWidget {
  final IconData? icono;
  final String? imagen;
  final String etiqueta;
  final String valor;
  final double proporcion;
  final String detalle;

  const _BarraHorizontal({
    this.icono,
    this.imagen,
    required this.etiqueta,
    required this.valor,
    required this.proporcion,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (imagen != null || icono == null)
            ProductoImagen(ruta: imagen, width: 36, height: 36)
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Icon(icono, size: 20, color: AppColors.textSecondary),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(etiqueta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: proporcion.clamp(0.0, 1.0),
                          minHeight: 6,
                          color: AppColors.primaryRed,
                          backgroundColor: AppColors.rowDivider,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(detalle,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista de tabla de los mismos datos del gráfico (sólo filas con ventas).
class _TablaPorBarra extends StatelessWidget {
  final _Periodo periodo;
  final DateTime inicio;
  final List<double> montos;
  final List<int> cantidades;
  const _TablaPorBarra({required this.periodo, required this.inicio, required this.montos, required this.cantidades});

  @override
  Widget build(BuildContext context) {
    final filas = [for (var i = 0; i < montos.length; i++) if (cantidades[i] > 0) i];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.table_rows_outlined, color: AppColors.primaryRed),
        title: Text('Tabla · ${periodo.tituloGrafico.toLowerCase()}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (filas.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Sin ventas en este período.', style: TextStyle(color: AppColors.textSecondary)),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text('Período', style: _encabezado)),
                  SizedBox(width: 70, child: Text('Ventas', textAlign: TextAlign.right, style: _encabezado)),
                  SizedBox(width: 110, child: Text('Monto', textAlign: TextAlign.right, style: _encabezado)),
                ],
              ),
            ),
            const Divider(),
            for (final i in filas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(_etiquetaBarra(periodo, inicio, i))),
                    SizedBox(width: 70, child: Text('${cantidades[i]}', textAlign: TextAlign.right)),
                    SizedBox(
                      width: 110,
                      child: Text(_bs(montos[i]),
                          textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static const _encabezado = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary);
}

/// Lista de las ventas del período (más recientes primero).
class _Detalle extends StatelessWidget {
  final List<Venta> ventas;
  const _Detalle({required this.ventas});

  @override
  Widget build(BuildContext context) {
    final ordenadas = [...ventas]..sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.receipt_long_outlined, color: AppColors.primaryRed),
        title: Text('Ventas del período (${ventas.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (ordenadas.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Sin ventas en este período.', style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            for (final v in ordenadas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Venta #${v.id ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    Text(_fechaHora(v), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: Text(_bs(v.total),
                          textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static String _fechaHora(Venta v) {
    final f = DateTime.tryParse(v.fechaVenta)?.toLocal();
    if (f == null) return '';
    return '${_ddmm(f)} ${_dos(f.hour)}:${_dos(f.minute)}';
  }
}
