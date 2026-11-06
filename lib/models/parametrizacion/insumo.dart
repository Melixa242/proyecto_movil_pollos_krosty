class Insumo {
  final int? id;
  final String nombre;
  final int unidadMedidaId;
  final double stockActual;
  final double stockMinimo;
  final String estado;

  Insumo({
    this.id,
    required this.nombre,
    required this.unidadMedidaId,
    required this.stockActual,
    required this.stockMinimo,
    required this.estado,
  });

  factory Insumo.fromJson(Map<String, dynamic> json) {
    return Insumo(
      id: json['id'],
      nombre: json['nombre']?.toString() ?? '',
      unidadMedidaId: json['unidad_medida_id'] ?? 0,
      stockActual: double.tryParse(json['stock_actual'].toString()) ?? 0.0,
      stockMinimo: double.tryParse(json['stock_minimo'].toString()) ?? 0.0,
      estado: json['estado']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'unidad_medida_id': unidadMedidaId,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'estado': estado,
    };
  }

  String getStockFormato() => stockActual == stockActual.toInt() 
    ? stockActual.toInt().toString() 
    : stockActual.toStringAsFixed(2);

  String getEstadoDisplay() {
    final statusMap = {
      'activo': 'Activo',
      'inactivo': 'Inactivo',
      'descontinuado': 'Descontinuado',
    };
    return statusMap[estado.toLowerCase()] ?? estado;
  }

  bool isStockBajo() => stockActual <= stockMinimo;

  String getStockStatus() => isStockBajo() ? 'BAJO' : 'OK';

  String getDisplay() => '$nombre (Stock: ${getStockFormato()})';
  
  String getDetailedDisplay() => 'Nombre: $nombre\nStock Actual: ${getStockFormato()}\nStock Mínimo: ${stockMinimo.toStringAsFixed(2)}\nEstado: ${getEstadoDisplay()}\nStock: ${getStockStatus()}';
}
