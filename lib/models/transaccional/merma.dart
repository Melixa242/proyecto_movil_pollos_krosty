import '../seguridad/model_helpers.dart';

class Merma {
    final int? id;
    final int produccionId;
    final double cantidad;
    final int estado;

    Merma({
        this.id,
        required this.produccionId,
        required this.cantidad,
        required this.estado,
    });

    factory Merma.fromJson(Map<String, dynamic> json) {
        return Merma(
            id: modelIntOrNull(json['id']),
            produccionId: modelInt(json['produccion_id']),
            cantidad: modelDouble(json['cantidad']),
            estado: modelInt(json['estado']),
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'produccion_id': produccionId,
            'cantidad': cantidad,
            'estado': estado,
        };
    }
}