import 'dart:convert';
import '../../models/transaccional/orden_produccion.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class OrdenProduccionProvider extends CrudProvider<OrdenProduccion> {
  OrdenProduccionProvider() : super('/ordenes', OrdenProduccion.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<OrdenProduccion> get ordenes => items;
  Future<void> fetchOrdenes() => fetch();
  Future<bool> createOrden(OrdenProduccion item) => create(item);
  Future<bool> updateOrden(OrdenProduccion item) => update(item.id!, item);
  Future<bool> deleteOrden(int id) => remove(id);

  /// Receta, producto resultante, insumos pendientes y rango de rendimiento
  /// (`minimo`/`maximo`) para ejecutar la orden. null si no se pudo obtener.
  Future<Map<String, dynamic>?> datosEjecucion(int id) async {
    try {
      final response = await api.get('$endpoint/$id/ejecucion');
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Ejecuta la orden: crea las producciones, descuenta el stock de los insumos y
  /// suma lo obtenido al producto. Va directo al servidor (nunca se encola offline,
  /// porque mueve stock y el servidor valida rendimiento y disponibilidad).
  Future<({bool ok, String mensaje})> ejecutar(int id, double cantidadObtenida) async {
    try {
      final path = '${endpoint.replaceFirst('/', '')}/$id/ejecutar';
      final response = await api.enviar('POST', path, jsonEncode({'cantidad_obtenida': cantidadObtenida}));
      Map? decoded;
      try {
        final d = jsonDecode(response.body);
        if (d is Map) decoded = d;
      } on FormatException catch (_) {}
      if (response.statusCode == 201) {
        return (ok: true, mensaje: '${decoded?['mensaje'] ?? 'Producción ejecutada'}');
      }
      return (ok: false, mensaje: '${decoded?['error'] ?? 'Error ${response.statusCode} al ejecutar'}');
    } catch (e) {
      return (ok: false, mensaje: 'Error de conexión: $e');
    }
  }
}
