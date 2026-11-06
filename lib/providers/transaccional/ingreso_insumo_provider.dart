import '../../models/transaccional/ingreso_insumo.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class IngresoInsumoProvider extends CrudProvider<IngresoInsumo> {
  IngresoInsumoProvider() : super('/ingreso-insumos', IngresoInsumo.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<IngresoInsumo> get ingresos => items;
  Future<void> fetchIngresos() => fetch();
  Future<bool> createIngreso(IngresoInsumo item) => create(item);
  Future<bool> updateIngreso(IngresoInsumo item) => update(item.id!, item);
  Future<bool> deleteIngreso(int id) => remove(id);
}