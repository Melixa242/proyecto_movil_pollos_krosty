import '../seguridad/model_helpers.dart';

class OrdenProduccion {
	final int? id;
	final String numeroOrden;
	final String fechaProgramada;
	final int? reglaConversionId;
	final String observaciones;
	final int estado;

	OrdenProduccion({
		this.id,
		required this.numeroOrden,
		required this.fechaProgramada,
		this.reglaConversionId,
		required this.observaciones,
		required this.estado,
	});

	factory OrdenProduccion.fromJson(Map<String, dynamic> json) {
		return OrdenProduccion(
			id: modelIntOrNull(json['id']),
			numeroOrden: modelString(json['numero_orden']),
			fechaProgramada: modelString(json['fecha_programada']),
			reglaConversionId: modelIntOrNull(json['regla_conversion_id']),
			observaciones: modelString(json['observaciones']),
			estado: modelInt(json['estado']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'numero_orden': numeroOrden,
			'fecha_programada': fechaProgramada,
			'regla_conversion_id': reglaConversionId,
			'observaciones': observaciones,
			'estado': estado,
		};
	}
}