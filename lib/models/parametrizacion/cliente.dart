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

  String getTelefonoFormato() {
    final clean = telefono.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return '(${clean.substring(0, 3)}) ${clean.substring(3, 6)}-${clean.substring(6)}';
    }
    return telefono;
  }

  String getEstadoDisplay() {
    final statusMap = {
      'activo': 'Activo',
      'inactivo': 'Inactivo',
      'bloqueado': 'Bloqueado',
      'pendiente': 'Pendiente',
    };
    return statusMap[estado.toLowerCase()] ?? estado;
  }

  String getDisplay() => nombre;
  
  String getDetailedDisplay() => 'Nombre: $nombre\nTeléfono: ${getTelefonoFormato()}\nEstado: ${getEstadoDisplay()}';
}
