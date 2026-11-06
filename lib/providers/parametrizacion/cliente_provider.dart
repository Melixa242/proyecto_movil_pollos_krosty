import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/parametrizacion/cliente.dart';

class ClienteProvider with ChangeNotifier{

  /// [api] permite usar este provider contra la API local (p. ej. en ventas).
  ClienteProvider({ApiService? api}) : _apiService = api ?? ApiService.web;

  final ApiService _apiService;
  List<Cliente> _clientes =[];
  bool _isLoading =false;
  String? _error;
  List<Cliente> get  clientes=> _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // La ruta de ventas crea su propio ClienteProvider y lo descarta al salir;
  // si un fetch sigue en curso, no hay que notificar a un provider descartado.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future <void> fetchClientes() async {
    _isLoading =true;
    _error = null;
    notifyListeners();
    try{
      final response = await _apiService.get('/clientes');

      // Diagnóstico: imprime el código y el cuerpo real que devuelve la API.
      debugPrint('GET /clientes -> ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Acepta tanto un array directo [...] como uno envuelto { "data": [...] }
        // o { "clientes": [...] } (formatos típicos de Laravel Resource/paginación).
        List<dynamic> lista;
        if (decoded is List) {
          lista = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          lista = decoded['data'];
        } else if (decoded is Map && decoded['clientes'] is List) {
          lista = decoded['clientes'];
        } else {
          lista = [];
          _error = 'Formato de respuesta inesperado de /clientes';
        }

        _clientes = lista
            .map((item) => Cliente.fromJson(item as Map<String, dynamic>))
            .toList();
        // Diagnóstico: cuántos clientes quedaron parseados.
        debugPrint('Clientes parseados: ${_clientes.length}');
      } else {
        _error = 'Error ${response.statusCode} al cargar clientes';
      }
    }catch(e){
      _error = 'Error de conexión: $e';
      debugPrint('Error fetch clientes: $e');
    }
    _isLoading=false;
    notifyListeners();
  }

  Future<bool> createCliente(Cliente cliente) async{
    try{

      final response =await _apiService.post('/clientes', cliente.toJson());

    if(response.statusCode==201){
      await fetchClientes();
      return true;


    }

    }catch (e){
      debugPrint('Error createCliente:$e');
    }
    return false;
  }
  Future<bool> updateCliente(Cliente cliente) async{
    try{

      final response =await _apiService.post('/clientes/${cliente.id}?_method=PUT', cliente.toJson());

      if(response.statusCode==201){
        await fetchClientes();
        return true;

      }

    }catch (e){
      debugPrint('Error UPDATECliente:$e');
    }
    return false;
  }

  Future<bool> deleteCliente(int id) async{
    try{

      final response =await _apiService.post('/clientes/$id?_method=DELETE',{});

      if(response.statusCode==200){
        //
        _clientes.removeWhere((c)=> c.id ==id);
        notifyListeners();

        return true;

      }

    }catch (e){
      debugPrint('Error deleteCliente:$e');
    }
    return false;
  }

}






