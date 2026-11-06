import '../../models/seguridad/usuario.dart';
import '../crud_provider.dart';

class UsuarioProvider extends CrudProvider<Usuario> {
  UsuarioProvider() : super('/usuarios', Usuario.fromJson, (item) => item.toJson());
  List<Usuario> get usuarios => items;
  Future<void> fetchUsuarios() => fetch();
  Future<bool> createUsuario(Usuario item) => create(item);
  Future<bool> updateUsuario(Usuario item) => update(item.id!, item);
  Future<bool> deleteUsuario(int id) => remove(id);
}