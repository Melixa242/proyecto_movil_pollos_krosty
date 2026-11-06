
import '../../models/transaccional/detalle_venta.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class DetalleVentaProvider extends CrudProvider<DetalleVenta> {
  DetalleVentaProvider() : super('/detalle-ventas', DetalleVenta.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<DetalleVenta> get detalles => items;
  Future<void> fetchDetalles() => fetch();
  Future<bool> createDetalle(DetalleVenta item) => create(item);
  Future<bool> updateDetalle(DetalleVenta item) => update(item.id!, item);
  Future<bool> deleteDetalle(int id) => remove(id);
}