import '../seguridad/model_helpers.dart';

class VentaPago {
	final int? id;
	final int ventaId;
	final String metodoPago;
	final double monto;
	final String referencia;
	final int estado;

	VentaPago({
		this.id,
		required this.ventaId,
		required this.metodoPago,
		required this.monto,
		required this.referencia,
		required this.estado,
	});

	factory VentaPago.fromJson(Map<String, dynamic> json) {
		return VentaPago(
			id: modelIntOrNull(json['id']),
			ventaId: modelInt(json['venta_id']),
			metodoPago: modelString(json['metodo_pago']),
			monto: modelDouble(json['monto']),
			referencia: modelString(json['referencia']),
			estado: modelInt(json['estado']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'venta_id': ventaId,
			'metodo_pago': metodoPago,
			'monto': monto,
			'referencia': referencia,
			'estado': estado,
		};
	}
}