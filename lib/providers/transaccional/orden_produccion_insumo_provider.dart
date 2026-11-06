import '../../models/transaccional/orden_produccion_insumo.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class OrdenProduccionInsumoProvider extends CrudProvider<OrdenProduccionInsumo> {
  OrdenProduccionInsumoProvider() : super('/orden-produccion-insumos', OrdenProduccionInsumo.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<OrdenProduccionInsumo> get detalles => items;
  Future<void> fetchDetalles() => fetch();
  Future<bool> createDetalle(OrdenProduccionInsumo item) => create(item);
  Future<bool> updateDetalle(OrdenProduccionInsumo item) => update(item.id!, item);
  Future<bool> deleteDetalle(int id) => remove(id);
}