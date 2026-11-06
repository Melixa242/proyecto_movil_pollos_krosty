import '../seguridad/model_helpers.dart';

class IngresoInsumo {
	final int? id;
	final String fechaIngreso;
	final String descripcion;
	final int estado;

	IngresoInsumo({
		this.id,
		required this.fechaIngreso,
		required this.descripcion,
		required this.estado,
	});

	factory IngresoInsumo.fromJson(Map<String, dynamic> json) {
		return IngresoInsumo(
			id: modelIntOrNull(json['id']),
			fechaIngreso: json['fecha_ingreso'].toString(),
			descripcion: json['descripcion'].toString(),
			estado: int.parse(json['estado'].toString()),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'fecha_ingreso': fechaIngreso,
			'descripcion': descripcion,
			'estado': estado,
		};
	}
}