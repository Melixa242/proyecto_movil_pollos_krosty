class Producto {
  final int? id;
  final String nombre;
  final double precio;
  final int tipoProductoId;
  final double cantidadActual;
  final String estado;
  /// Ruta de la foto en el storage público de Laravel (p. ej. 'productos/abc.png'), o null.
  /// Es sólo de lectura: no se envía en [toJson] para no pisar la foto al editar.
  final String? imagen;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.tipoProductoId,
    required this.cantidadActual,
    required this.estado,
    this.imagen,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre']?.toString() ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      tipoProductoId: json['tipo_producto_id'] ?? 0,
      cantidadActual: double.tryParse(json['cantidad_actual'].toString()) ?? 0.0,
      estado: json['estado']?.toString() ?? '',
      imagen: json['imagen']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'tipo_producto_id': tipoProductoId,
      'cantidad_actual': cantidadActual,
      'estado': estado,
    };
  }

  String getPrecioFormato() => '\$${precio.toStringAsFixed(2)}';
  
  String getCantidadFormato() => cantidadActual == cantidadActual.toInt() 
    ? cantidadActual.toInt().toString() 
    : cantidadActual.toStringAsFixed(2);
  
  String getEstadoDisplay() {
    final statusMap = {
      'activo': 'Activo',
      'inactivo': 'Inactivo',
      'pausado': 'Pausado',
    };
    return statusMap[estado.toLowerCase()] ?? estado;
  }

  String getDisplay() => '$nombre - ${getPrecioFormato()}';
  
  String getDetailedDisplay() => 'Nombre: $nombre\nPrecio: ${getPrecioFormato()}\nCantidad: ${getCantidadFormato()}\nEstado: ${getEstadoDisplay()}';
}
