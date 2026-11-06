import '../../models/transaccional/merma.dart';
import '../../services/api_service.dart';
import '../crud_provider.dart';

class MermaProvider extends CrudProvider<Merma> {
  MermaProvider() : super('/mermas', Merma.fromJson, (item) => item.toJson(), api: ApiService.local);
  List<Merma> get mermas => items;
  Future<void> fetchMermas() => fetch();
  Future<bool> createMerma(Merma item) => create(item);
  Future<bool> updateMerma(Merma item) => update(item.id!, item);
  Future<bool> deleteMerma(int id) => remove(id);
}