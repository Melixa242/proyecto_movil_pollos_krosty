import '../seguridad/model_helpers.dart';


class IngresoBebidaProducto {
    final int? id;
    final int ingresoBebidaId;
    final int productoId;
    final double cantidadIngresa;
    final double precio;
    final int estado;

    IngresoBebidaProducto({
        this.id,
        required this.ingresoBebidaId,
        required this.productoId,
        required this.cantidadIngresa,
        required this.precio,
        required this.estado,
    });

    factory IngresoBebidaProducto.fromJson(Map<String, dynamic> json) {
        return IngresoBebidaProducto(
            id: modelIntOrNull(json['id']),
            ingresoBebidaId: int.parse(json['ingreso_bebida_id'].toString()),
            productoId: int.parse(json['producto_id'].toString()),
            cantidadIngresa: double.parse(json['cantidad_ingresa'].toString()),
            precio: double.parse(json['precio'].toString()),
            estado: int.parse(json['estado'].toString()),
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'ingreso_bebida_id': ingresoBebidaId,
            'producto_id': productoId,
            'cantidad_ingresa': cantidadIngresa,
            'precio': precio,
            'estado': estado,
        };
    }
}