import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      // Manejo de errores de conexión o excepciones
      _error = ' Error DE  conexion: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try{
      await _apiService.post('/logout', {});
    } catch (e) {
      // Manejo de errores de conexión o excepciones durante el cierre de sesión
      _error = 'Error al cerrar sesión: $e';
      // Actualiza el estado de autenticación a falso
      notifyListeners();
      return;

    }
    // Elimina el token de autenticación utilizando el servicio de API
    await _apiService.deleteToken();
    // Actualiza el estado de autenticación a falso y borra los datos del usuario
    _isAuthenticated = false;
    _user = null;
    // Notifica a los listeners que el estado ha cambiado el cambio de interface
    notifyListeners();
  }

  Future<void> checkAuthentication() async {
    // Ve si el token de autenticación existe y es válido
    String? token = await _apiService.getToken();
    // Si el token existe, intenta obtener los datos del usuario para verificar su validez
    if (token != null) {
      try {
        final response = await _apiService.get('/user');

        if (response.statusCode == 200 ) {
          // Si la respuesta es exitosa, actualiza el estado de autenticación y los datos del usuario
          _user = jsonDecode(response.body);
          _isAuthenticated = true;
        } else {
          // Si la respuesta no es exitosa, elimina el token y actualiza el estado de autenticación
          await _apiService.deleteToken();
          _isAuthenticated = false;

        }
      } catch (e) {
        // Maneja los errores de conexión o excepciones durante la verificación de autenticación
        _isAuthenticated = false;
        _user = null;
      }
    } else {
      // Si el token no existe, asegura que el estado de autenticación sea falso
      _isAuthenticated = false;

    }
    notifyListeners();
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