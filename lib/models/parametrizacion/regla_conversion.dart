class ReglaConversion {
  final int? id;
  final int insumoId;
  final int productoResultanteId;
  final int unidadEntradaId;
  final int unidadSalidaId;
  final String tipoConversion;
  final String nombreInsumo;
  final String nombreProducto;
  final String unidadEntrada;
  final String unidadSalida;
  final double cantidadEntrada;
  final double rendimientoMax;
  final double rendimientoMin;
  final String estado;

  ReglaConversion({
    this.id,
    required this.insumoId,
    required this.productoResultanteId,
    required this.unidadEntradaId,
    required this.unidadSalidaId,
    required this.tipoConversion,
    required this.rendimientoMax,
    required this.rendimientoMin,
    this.nombreInsumo = '',
    this.nombreProducto = '',
    this.unidadEntrada = '',
    this.unidadSalida = '',
    this.cantidadEntrada = 1,
    this.estado = '1',
  });

  factory ReglaConversion.fromJson(Map<String, dynamic> json) {
    // El backend manda insumo, producto y unidades como objetos relacionados
    // ({id, nombre, abreviatura}); también se aceptan como texto plano.
    String unidad(dynamic u) =>
        u is Map ? (u['abreviatura'] ?? u['nombre'] ?? '').toString() : u?.toString() ?? '';
    String nombre(dynamic rel) => rel is Map ? '${rel['nombre'] ?? ''}' : '';
    int entero(dynamic v) => int.tryParse('$v') ?? 0;

    return ReglaConversion(
      id: json['id'],
      insumoId: entero(json['insumo_id']),
      productoResultanteId: entero(json['producto_id'] ?? json['producto_resultante_id']),
      unidadEntradaId: entero(json['unidad_entrada_id']),
      unidadSalidaId: entero(json['unidad_salida_id']),
      tipoConversion: json['tipo_conversion']?.toString() ?? 'estatica',
      nombreInsumo: json['nombre_insumo']?.toString() ?? nombre(json['insumo']),
      nombreProducto: json['producto_resultante']?.toString() ?? nombre(json['producto']),
      unidadEntrada: unidad(json['unidad_entrada']),
      unidadSalida: unidad(json['unidad_salida']),
      cantidadEntrada: double.tryParse(json['cantidad_entrada'].toString()) ?? 1.0,
      rendimientoMax: double.tryParse(json['rendimiento_max'].toString()) ?? 0.0,
      rendimientoMin: double.tryParse(json['rendimiento_min'].toString()) ?? 0.0,
      estado: json['estado']?.toString() ?? '',
    );
  }

  /// Campos que valida StoreReglaConversionRequest en el backend.
  /// La cantidad de entrada la fija el backend en 1.
  Map<String, dynamic> toJson() {
    return {
      'insumo_id': insumoId,
      'producto_id': productoResultanteId,
      'unidad_medida_entrada_id': unidadEntradaId,
      'unidad_medida_resultante_id': unidadSalidaId,
      'rendimiento_minimo': rendimientoMin,
      'rendimiento_maximo': rendimientoMax,
      'tipo_conversion': tipoConversion,
    };
  }

  String getCantidadFormato() => cantidadEntrada == cantidadEntrada.toInt()
    ? cantidadEntrada.toInt().toString()
    : cantidadEntrada.toStringAsFixed(2);

  String getRendimientoPromedio() {
    final promedio = (rendimientoMax + rendimientoMin) / 2;
    return promedio.toStringAsFixed(2);
  }

  String getRendimientoFormato() => 'Min: ${rendimientoMin.toStringAsFixed(2)}% - Max: ${rendimientoMax.toStringAsFixed(2)}%';

  String getTipoDisplay() => tipoConversion.toLowerCase() == 'variable' ? 'Variable' : 'Estática';

  String getEstadoDisplay() {
    final statusMap = {
      '1': 'Activo',
      '0': 'Inactivo',
      'activo': 'Activo',
      'inactivo': 'Inactivo',
      'prueba': 'Prueba',
    };
    return statusMap[estado.toLowerCase()] ?? estado;
  }

  String getDisplay() => '$nombreInsumo: ${getCantidadFormato()} $unidadEntrada → $unidadSalida';

  String getDetailedDisplay() => 'Insumo: $nombreInsumo\nEntrada: ${getCantidadFormato()} $unidadEntrada\nSalida: $unidadSalida\nRendimiento: ${getRendimientoFormato()}\nProducto: $nombreProducto\nEstado: ${getEstadoDisplay()}';
}
