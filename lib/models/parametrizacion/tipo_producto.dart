class TipoProducto {
  final int? id;
  final String nombre;
  final String descripcion;

  TipoProducto({
    this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory TipoProducto.fromJson(Map<String, dynamic> json) {
    return TipoProducto(
      id: json['id'],
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  String getDescripcionCorta({int maxLength = 50}) {
    if (descripcion.length <= maxLength) return descripcion;
    return '${descripcion.substring(0, maxLength)}...';
  }

  String getDisplay() => nombre;
  
  String getDetailedDisplay() => 'Nombre: $nombre\nDescripción: $descripcion';
}
