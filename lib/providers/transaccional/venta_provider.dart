import 'dart:convert';
import '../../models/transaccional/detalle_venta.dart';
import '../../models/transaccional/venta.dart';
import '../../models/transaccional/venta_pago.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class VentaProvider extends CrudProvider<Venta> {
  VentaProvider() : super('/ventas', Venta.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<Venta> get ventas => items;
  Future<void> fetchVentas() => fetch();
  Future<bool> createVenta(Venta item) => create(item);
  Future<bool> updateVenta(Venta item) => update(item.id!, item);
  Future<bool> deleteVenta(int id) => remove(id);

  /// Crea la venta junto con sus detalles y pagos en un solo POST (el servidor
  /// los guarda en una transacción) y devuelve el id asignado por el backend.
  /// Si se guardó offline devuelve el id temporal negativo.
  Future<int?> crearVentaConId(Venta item, List<DetalleVenta> detalles, List<VentaPago> pagos) async {
    try {
      final response = await api.post(endpoint, {
        ...item.toJson(),
        'detalles': detalles.map((d) => d.toJson()).toList(),
        'pagos': pagos.map((p) => p.toJson()).toList(),
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['offline'] == true) return -(decoded['pendiente_id'] as int);
        final data = decoded is Map && decoded['data'] is Map ? decoded['data'] : decoded;
        final id = data is Map ? data['id'] : null;
        await fetch();
        return id is int ? id : int.tryParse('$id');
      }
      error = _mensajeError(response.body) ?? 'Error ${response.statusCode} al registrar la venta';
    } catch (e) {
      error = 'Error de conexión: $e';
    }
    notifyListeners();
    return null;
  }

  /// Mensaje `{"error": ...}` que devuelve el servidor al rechazar la venta.
  String? _mensajeError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) return decoded['error'].toString();
    } catch (_) {}
    return null;
  }
}