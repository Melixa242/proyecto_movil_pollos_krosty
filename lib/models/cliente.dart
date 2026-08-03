class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String estado;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.estado,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nombre: json['nombre']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'estado': estado,
    };
  }
}