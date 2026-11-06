import '../seguridad/model_helpers.dart';

class Produccion {
	final int? id;
	final int? ordenProduccionId;
	final int? ordenProduccionInsumoId;
	final int? reglaConversionId;
	final int? productoId;
	final double cantidadInsumo;
	final double cantidadObtenida;
	final int nivel;
	final int estado;

	Produccion({
		this.id,
		this.ordenProduccionId,
		this.ordenProduccionInsumoId,
		this.reglaConversionId,
		this.productoId,
		required this.cantidadInsumo,
		required this.cantidadObtenida,
		required this.nivel,
		required this.estado,
	});

	factory Produccion.fromJson(Map<String, dynamic> json) {
		return Produccion(
			id: modelIntOrNull(json['id']),
			ordenProduccionId: modelIntOrNull(json['orden_produccion_id']),
			ordenProduccionInsumoId: modelIntOrNull(json['orden_produccion_insumo_id']),
			reglaConversionId: modelIntOrNull(json['regla_conversion_id']),
			productoId: modelIntOrNull(json['producto_id']),
			cantidadInsumo: modelDouble(json['cantidad_insumo']),
			cantidadObtenida: modelDouble(json['cantidad_obtenida']),
			nivel: modelInt(json['nivel']),
			estado: modelInt(json['estado']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'orden_produccion_id': ordenProduccionId,
			'orden_produccion_insumo_id': ordenProduccionInsumoId,
			'regla_conversion_id': reglaConversionId,
			'producto_id': productoId,
			'cantidad_insumo': cantidadInsumo,
			'cantidad_obtenida': cantidadObtenida,
			'nivel': nivel,
			'estado': estado,
		};
	}
}