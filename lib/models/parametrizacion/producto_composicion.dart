/// Una fila de composición: el producto padre lleva [cantidad] del producto hijo.
/// En el backend la composición se guarda por producto padre (lista de ingredientes),
/// por eso [id] es el id del producto padre.
class ProductoComposicion {
  final int? id;
  final int productoPadreId;
  final int productoHijoId;
  final double cantidad;
  final String estado;
  final String productoPadreNombre;
  final String productoHijoNombre;

  ProductoComposicion({
    this.id,
    required this.productoPadreId,
    required this.productoHijoId,
    required this.cantidad,
    this.estado = '1',
    this.productoPadreNombre = '',
    this.productoHijoNombre = '',
  });

  factory ProductoComposicion.fromJson(Map<String, dynamic> json) {
    return ProductoComposicion(
      id: json['id'],
      productoPadreId: json['producto_padre_id'] ?? 0,
      productoHijoId: json['producto_hijo_id'] ?? 0,
      cantidad: double.tryParse(json['cantidad'].toString()) ?? 0.0,
      estado: json['estado']?.toString() ?? '',
    );
  }

  /// Formato de un ingrediente para el backend: {id, cantidad}.
  Map<String, dynamic> toIngrediente() => {'id': productoHijoId, 'cantidad': cantidad};

  String get padreDisplay =>
      productoPadreNombre.isNotEmpty ? productoPadreNombre : '#$productoPadreId';
  String get hijoDisplay =>
      productoHijoNombre.isNotEmpty ? productoHijoNombre : '#$productoHijoId';

  String getCantidadFormato() => cantidad == cantidad.toInt()
    ? cantidad.toInt().toString()
    : cantidad.toStringAsFixed(2);

  String getEstadoDisplay() {
    final statusMap = {
      '1': 'Activo',
      '0': 'Inactivo',
      'activo': 'Activo',
      'inactivo': 'Inactivo',
    };
    return statusMap[estado.toLowerCase()] ?? estado;
  }

  String getDisplay() => 'Padre: $padreDisplay → Hijo: $hijoDisplay (x${getCantidadFormato()})';

  String getDetailedDisplay() => 'Producto Padre: $padreDisplay\nProducto Hijo: $hijoDisplay\nCantidad: ${getCantidadFormato()}\nEstado: ${getEstadoDisplay()}';
}
