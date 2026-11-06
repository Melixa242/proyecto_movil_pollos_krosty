import '../seguridad/model_helpers.dart';


class IngresoBebida {
	final int? id;
	final String nombre;
	final String descripcion;
	final String fechaIngreso;
	final int estado;

	IngresoBebida({
		this.id,
		required this.nombre,
		required this.descripcion,
		required this.fechaIngreso,
		required this.estado,
	});

	factory IngresoBebida.fromJson(Map<String, dynamic> json) {
		return IngresoBebida(
			id: modelIntOrNull(json['id']),
			nombre: modelString(json['nombre']),
			descripcion: modelString(json['descripcion']),
			fechaIngreso: modelString(json['fecha_ingreso']),
			estado: modelInt(json['estado']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'nombre': nombre,
			'descripcion': descripcion,
			'fecha_ingreso': fechaIngreso,
			'estado': estado,
		};
	}
}