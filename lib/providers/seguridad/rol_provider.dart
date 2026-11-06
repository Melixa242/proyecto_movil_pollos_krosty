import '../../models/seguridad/rol.dart';
import '../crud_provider.dart';

class RolProvider extends CrudProvider<Rol> {
  RolProvider() : super('/roles', Rol.fromJson, (item) => item.toJson());
  List<Rol> get roles => items;
  Future<void> fetchRoles() => fetch();
  Future<bool> createRol(Rol item) => create(item);
  Future<bool> updateRol(Rol item) => update(item.id!, item);
  Future<bool> deleteRol(int id) => remove(id);
}