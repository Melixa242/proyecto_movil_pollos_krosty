import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/local_db.dart';

class AuthProvider with ChangeNotifier {
  //Una variable privada que almacena el servicio de API
  final ApiService _apiService = ApiService();
  //Una variable privada que indica si el usuario está autenticado o no
  bool _isAuthenticated = false;
  //Una variable privada que almacena los datos del usuario autenticado
  Map<String, dynamic>? _user;
  //Una variable privada que almacena el mensaje de error
  String? _error;

  // Getters para acceder a las variables privadas desde fuera de la clase
  bool get isAuthenticated => _isAuthenticated;
  //Una variable privada que almacena los datos del usuario autenticado
  Map<String, dynamic>? get user => _user;
  //Una variable privada que almacena el mensaje de error
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    // Reiniciar el estado de error antes de intentar iniciar sesión
    _error = null;
    // Notificar a los listeners que el estado ha cambiado (por ejemplo, para mostrar un indicador de carga)
    notifyListeners();

    try {
      // Instancia el servicio de API y realiza la solicitud de inicio de sesión
      final response = await _apiService.post('/login', {
        'email': email,
        'password': password,
        'device_name': 'mobile_app',
      });

      final data = jsonDecode(response.body);

      // Busca el token en las claves más comunes que devuelven los backends
      // de Sanctum (token, access_token, o anidado dentro de data).
      final token = data['token'] ??
          data['access_token'] ??
          (data['data'] is Map ? data['data']['token'] : null);

      // Verifica si la respuesta es exitosa y trae un token válido.
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          token != null) {
        // Guarda el token de autenticación utilizando el servicio de API
        await _apiService.saveToken(token.toString());
        // Actualiza el estado de autenticación y los datos del usuario
        _user = data['user'] ?? (data['data'] is Map ? data['data']['user'] : null);
        // Actualiza el estado de autenticación a verdadero
        _isAuthenticated = true;
        // Notifica a los listeners que el estado ha cambiado
        notifyListeners();
        // Retorna verdadero para indicar que el inicio de sesión fue exitoso
        return true;
      } else {
        // Manejo en caso de que el servidor responda pero no sea exitoso
        _error = data['message'] ??
            'Error al iniciar sesión (código ${response.statusCode})';
        // Actualiza el estado de autenticación a falso
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Sin respuesta del servidor (timeout, servidor apagado, IP incorrecta, sin red)
      if (ApiService.esErrorDeRed(e)) {
        _error = 'No se pudo conectar con el servidor. Verificá tu conexión.';
      } else if (e is FormatException) {
        // El servidor respondió algo que no es JSON (por ejemplo, una página de error)
        _error = 'El servidor respondió con un formato inesperado. Intentá más tarde.';
      } else {
        _error = 'Error al iniciar sesión: $e';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String passwordConfirmation) async {
    // Reinicia el estado de error antes de intentar registrar
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': 'mobile_app',
      });

      final data = jsonDecode(response.body);

      // Igual que en login: busca el token en las claves más comunes
      // que devuelven los backends de Sanctum.
      final token = data['token'] ??
          data['access_token'] ??
          (data['data'] is Map ? data['data']['token'] : null);

      if ((response.statusCode == 200 || response.statusCode == 201)) {
        if (token != null) {
          // El backend devolvió sesión directamente: registra y loguea de una.
          await _apiService.saveToken(token.toString());
          _user = data['user'] ?? (data['data'] is Map ? data['data']['user'] : null);
          _isAuthenticated = true;
        }
        notifyListeners();
        return true;
      } else {
        // Maneja errores de validación de Laravel (422), que vienen en 'errors'.
        if (data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
          final firstError = (data['errors'] as Map).values.first;
          _error = firstError is List ? firstError.first.toString() : firstError.toString();
        } else {
          _error = data['message'] ?? 'Error al registrar (código ${response.statusCode})';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      notifyListeners();
      return false;
    }
  }

  /// Devuelve false si no se pudo cerrar sesión (ver [error]).
  Future<bool> logout() async {
    // No se permite cerrar sesión con cambios offline sin enviar:
    // se perderían o se registrarían a nombre del próximo usuario.
    final pendientes = await LocalDb.instance.contarPendientes();
    if (pendientes > 0) {
      _error = 'Tenés $pendientes cambios sin sincronizar. '
          'Conectate y sincronizá antes de cerrar sesión.';
      notifyListeners();
      return false;
    }
    try{
      await _apiService.post('/logout', {});
    } catch (e) {
      // Manejo de errores de conexión o excepciones durante el cierre de sesión
      _error = 'Error al cerrar sesión: $e';
      // Actualiza el estado de autenticación a falso
      notifyListeners();
      return false;

    }
    // Elimina el token de autenticación utilizando el servicio de API
    await _apiService.deleteToken();
    // Actualiza el estado de autenticación a falso y borra los datos del usuario
    _isAuthenticated = false;
    _user = null;
    // Notifica a los listeners que el estado ha cambiado el cambio de interface
    notifyListeners();
    return true;
  }

  Future<void> checkAuthStatus()async {

    String? token =await _apiService.getToken();
    if(token!=null){
      try {
        final response = await _apiService.get('/user');
        if(response.statusCode ==200){
          _user =jsonDecode(response.body);
          _isAuthenticated=true;
        }else{
          await _apiService.deleteToken();
          _isAuthenticated=false;

        }
      }catch(e){
        _isAuthenticated=false;
      }
    }else{
      _isAuthenticated=false;
    }
    notifyListeners();
  }
}