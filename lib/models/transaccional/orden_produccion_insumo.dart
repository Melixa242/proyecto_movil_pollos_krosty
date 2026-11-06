import '../seguridad/model_helpers.dart';

class OrdenProduccionInsumo {
	final int? id;
	final int ordenProduccionId;
	final int insumoId;
	final double cantidad;
	final int estado;

	OrdenProduccionInsumo({
		this.id,
		required this.ordenProduccionId,
		required this.insumoId,
		required this.cantidad,
		required this.estado,
	});

	factory OrdenProduccionInsumo.fromJson(Map<String, dynamic> json) {
		return OrdenProduccionInsumo(
			id: modelIntOrNull(json['id']),
			ordenProduccionId: modelInt(json['orden_produccion_id']),
			insumoId: modelInt(json['insumo_id']),
			cantidad: modelDouble(json['cantidad']),
			estado: modelInt(json['estado']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'orden_produccion_id': ordenProduccionId,
			'insumo_id': insumoId,
			'cantidad': cantidad,
			'estado': estado,
		};
	}
}