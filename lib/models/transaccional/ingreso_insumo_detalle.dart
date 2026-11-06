import '../seguridad/model_helpers.dart';


class IngresoInsumoDetalle {
	final int? id;
	final int ingresoInsumoId;
	final int insumoId;
	final double cantidad;
	final double precioUnitario;
	final int estado;

	IngresoInsumoDetalle({
		this.id,
		required this.ingresoInsumoId,
		required this.insumoId,
		required this.cantidad,
		required this.precioUnitario,
		required this.estado,
	});

	factory IngresoInsumoDetalle.fromJson(Map<String, dynamic> json) {
		return IngresoInsumoDetalle(
			id: modelIntOrNull(json['id']),
			ingresoInsumoId: modelInt(json['ingreso_insumo_id']),
			insumoId: modelInt(json['insumo_id']),
			cantidad: modelDouble(json['cantidad']),
			precioUnitario: modelDouble(json['precio_unitario']),
			estado: modelInt(json['estado']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'ingreso_insumo_id': ingresoInsumoId,
			'insumo_id': insumoId,
			'cantidad': cantidad,
			'precio_unitario': precioUnitario,
			'estado': estado,
		};
	}
}