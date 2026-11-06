import '../../models/transaccional/produccion.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class ProduccionProvider extends CrudProvider<Produccion> {
  ProduccionProvider() : super('/producciones', Produccion.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<Produccion> get producciones => items;
  Future<void> fetchProducciones() => fetch();
  Future<bool> createProduccion(Produccion item) => create(item);
  Future<bool> updateProduccion(Produccion item) => update(item.id!, item);
  Future<bool> deleteProduccion(int id) => remove(id);
}