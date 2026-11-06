import '../../models/transaccional/ingreso_insumo_detalle.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class IngresoInsumoDetalleProvider extends CrudProvider<IngresoInsumoDetalle> {
  IngresoInsumoDetalleProvider() : super('/ingreso-insumo-detalles', IngresoInsumoDetalle.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<IngresoInsumoDetalle> get detalles => items;
  Future<void> fetchDetalles() => fetch();
  Future<bool> createDetalle(IngresoInsumoDetalle item) => create(item);
  Future<bool> updateDetalle(IngresoInsumoDetalle item) => update(item.id!, item);
  Future<bool> deleteDetalle(int id) => remove(id);
}
