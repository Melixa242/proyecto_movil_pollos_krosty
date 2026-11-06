import '../../models/transaccional/venta_pago.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class VentaPagoProvider extends CrudProvider<VentaPago> {
  VentaPagoProvider() : super('/venta-pagos', VentaPago.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<VentaPago> get pagos => items;
  Future<void> fetchPagos() => fetch();
  Future<bool> createPago(VentaPago item) => create(item);
  Future<bool> updatePago(VentaPago item) => update(item.id!, item);
  Future<bool> deletePago(int id) => remove(id);
}