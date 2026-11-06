import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/parametrizacion/tipo_producto.dart';

class TipoProductProvider with ChangeNotifier {

  /// [api] permite usar este provider contra la API local (p. ej. en ventas).
  TipoProductProvider({ApiService? api}) : _apiService = api ?? ApiService.web;

  final ApiService _apiService;
  List<TipoProducto> _tiposProducto = [];
  bool _isLoading = false;
  String? _error;

  List<TipoProducto> get tiposProducto => _tiposProducto;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTiposProducto() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.get('/tipo-productos');

      debugPrint('GET /tipo-productos -> ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> lista;
        if (decoded is List) {
          lista = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          lista = decoded['data'];
        } else if (decoded is Map && decoded['tipos_productos'] is List) {
          lista = decoded['tipos_productos'];
        } else {
          lista = [];
          _error = 'Formato de respuesta inesperado';
        }

        _tiposProducto = lista
            .map((item) => TipoProducto.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('Tipos producto parseados: ${_tiposProducto.length}');
      } else {
        _error = 'Error ${response.statusCode} al cargar tipos de producto';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      debugPrint('Error fetch tipos producto: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTipoProducto(TipoProducto tipoProducto) async {
    try {
      final response = await _apiService.post('/tipo-productos', tipoProducto.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTiposProducto();
        return true;
      }
    } catch (e) {
      debugPrint('Error createTipoProducto: $e');
    }
    return false;
  }

  Future<bool> updateTipoProducto(TipoProducto tipoProducto) async {
    try {
      final response = await _apiService.post('/tipo-productos/${tipoProducto.id}?_method=PUT', tipoProducto.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTiposProducto();
        return true;
      }
    } catch (e) {
      debugPrint('Error updateTipoProducto: $e');
    }
    return false;
  }

  Future<bool> deleteTipoProducto(int id) async {
    try {
      final response = await _apiService.post('/tipo-productos/$id?_method=DELETE', {});

      if (response.statusCode == 200) {
        _tiposProducto.removeWhere((t) => t.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteTipoProducto: $e');
    }
    return false;
  }
}
