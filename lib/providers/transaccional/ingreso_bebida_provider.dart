import '../../models/transaccional/ingreso_bebida.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class IngresoBebidaProvider extends CrudProvider<IngresoBebida> {
  IngresoBebidaProvider() : super('/ingreso-bebidas', IngresoBebida.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<IngresoBebida> get ingresos => items;
  Future<void> fetchIngresos() => fetch();
  Future<bool> createIngreso(IngresoBebida item) => create(item);
  Future<bool> updateIngreso(IngresoBebida item) => update(item.id!, item);
  Future<bool> deleteIngreso(int id) => remove(id);
}

