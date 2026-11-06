import '../../models/transaccional/ingreso_bebida_producto.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class IngresoBebidaProductoProvider extends CrudProvider<IngresoBebidaProducto> {
  IngresoBebidaProductoProvider() : super('/ingreso-bebida-productos', IngresoBebidaProducto.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<IngresoBebidaProducto> get detalles => items;
  Future<void> fetchDetalles() => fetch();
  Future<bool> createDetalle(IngresoBebidaProducto item) => create(item);
  Future<bool> updateDetalle(IngresoBebidaProducto item) => update(item.id!, item);
  Future<bool> deleteDetalle(int id) => remove(id);
}

