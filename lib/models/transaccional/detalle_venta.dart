import '../seguridad/model_helpers.dart';

class DetalleVenta {
	final int? id;
	final int ventaId;
	final int productoId;
	final double precioUnitario;
	final double cantidad;
	final double subTotal;
	final int estado;

	DetalleVenta({
		this.id,
		required this.ventaId,
		required this.productoId,
		required this.precioUnitario,
		required this.cantidad,
		required this.subTotal,
		required this.estado,
	});

	factory DetalleVenta.fromJson(Map<String, dynamic> json) {
		return DetalleVenta(
			id: modelIntOrNull(json['id']),
			ventaId: int.parse(json['venta_id'].toString()),
			productoId: int.parse(json['producto_id'].toString()),
			precioUnitario: double.parse(json['precio_unitario'].toString()),
			cantidad: double.parse(json['cantidad'].toString()),
			subTotal: double.parse(json['sub_total'].toString()),
			estado: int.parse(json['estado'].toString()),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'venta_id': ventaId,
			'producto_id': productoId,
			'precio_unitario': precioUnitario,
			'cantidad': cantidad,
			'sub_total': subTotal,
			'estado': estado,
		};
	}
}