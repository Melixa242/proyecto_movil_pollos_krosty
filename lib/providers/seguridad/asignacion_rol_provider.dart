import '../../models/seguridad/asignacion_rol.dart';
import '../crud_provider.dart';

class AsignacionRolProvider extends CrudProvider<AsignacionRol> {
  AsignacionRolProvider() : super('/asignacion-roles', AsignacionRol.fromJson, (item) => item.toJson());
  List<AsignacionRol> get asignaciones => items;
  Future<void> fetchAsignaciones() => fetch();
  Future<bool> createAsignacion(AsignacionRol item) => create(item);
  Future<bool> updateAsignacion(AsignacionRol item) => update(item.id!, item);
  Future<bool> deleteAsignacion(int id) => remove(id);
}