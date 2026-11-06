class UnidadMedida {
  final int? id;
  final String nombre;
  final String abreviatura;
  final double factorConversion;
  final String estado;

  UnidadMedida({
    this.id,
    required this.nombre,
    required this.abreviatura,
    required this.factorConversion,
    required this.estado,
  });

  factory UnidadMedida.fromJson(Map<String, dynamic> json) {
    return UnidadMedida(
      id: json['id'],
      nombre: json['nombre']?.toString() ?? '',
      abreviatura: json['abreviatura']?.toString() ?? '',
      factorConversion: double.tryParse(json['factor_conversion'].toString()) ?? 0.0,
      estado: json['estado']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'abreviatura': abreviatura,
      'factor_conversion': factorConversion,
      'estado': estado,
    };
  }

  String getFactorFormato() => factorConversion == factorConversion.toInt() 
    ? factorConversion.toInt().toString() 
    : factorConversion.toStringAsFixed(4);

  String getEstadoDisplay() {
    final statusMap = {
      'activo': 'Activo',
      'inactivo': 'Inactivo',
    };
    return statusMap[estado.toLowerCase()] ?? estado;
  }

  String getDisplay() => '$abreviatura - $nombre';
  
  String getDetailedDisplay() => 'Nombre: $nombre\nAbreviatura: $abreviatura\nFactor: ${getFactorFormato()}\nEstado: ${getEstadoDisplay()}';
}
