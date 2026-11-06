import '../seguridad/model_helpers.dart';

class Venta {
	final int? id;
	final int clienteId;
	final String fechaVenta;
	final String observaciones;
	final String opcionPago;
	final double descuento;
	final double total;
	final int estado;

	Venta({
		this.id,
		required this.clienteId,
		required this.fechaVenta,
		required this.observaciones,
		required this.opcionPago,
		required this.descuento,
		required this.total,
		required this.estado,
	});

	factory Venta.fromJson(Map<String, dynamic> json) {
		return Venta(
			id: modelIntOrNull(json['id']),
			clienteId: modelInt(json['cliente_id']),
			fechaVenta: modelString(json['fecha_venta']),
			observaciones: modelString(json['observaciones']),
			opcionPago: modelString(json['opcion_pago']),
			descuento: modelDouble(json['descuento']),
			total: modelDouble(json['total']),
			estado: modelInt(json['estado']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'cliente_id': clienteId,
			'fecha_venta': fechaVenta,
			'observaciones': observaciones,
			'opcion_pago': opcionPago,
			'descuento': descuento,
			'total': total,
			'estado': estado,
		};
	}
}