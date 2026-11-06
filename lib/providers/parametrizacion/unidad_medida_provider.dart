import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/parametrizacion/unidad_medida.dart';

class UnidadMedidaProvider with ChangeNotifier {

  final ApiService _apiService = ApiService();
  List<UnidadMedida> _unidadesMedida = [];
  bool _isLoading = false;
  String? _error;

  List<UnidadMedida> get unidadesMedida => _unidadesMedida;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUnidadesMedida() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.get('/unidad-medidas');

      debugPrint('GET /unidad-medidas -> ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> lista;
        if (decoded is List) {
          lista = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          lista = decoded['data'];
        } else if (decoded is Map && decoded['unidades_medida'] is List) {
          lista = decoded['unidades_medida'];
        } else {
          lista = [];
          _error = 'Formato de respuesta inesperado';
        }

        _unidadesMedida = lista
            .map((item) => UnidadMedida.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('Unidades medida parseadas: ${_unidadesMedida.length}');
      } else {
        _error = 'Error ${response.statusCode} al cargar unidades de medida';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      debugPrint('Error fetch unidades medida: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createUnidadMedida(UnidadMedida unidadMedida) async {
    try {
      final response = await _apiService.post('/unidad-medidas', unidadMedida.toJson());

      if (response.statusCode == 201) {
        await fetchUnidadesMedida();
        return true;
      }
    } catch (e) {
      debugPrint('Error createUnidadMedida: $e');
    }
    return false;
  }

  Future<bool> updateUnidadMedida(UnidadMedida unidadMedida) async {
    try {
      final response = await _apiService.post('/unidad-medidas/${unidadMedida.id}?_method=PUT', unidadMedida.toJson());

      if (response.statusCode == 201) {
        await fetchUnidadesMedida();
        return true;
      }
    } catch (e) {
      debugPrint('Error updateUnidadMedida: $e');
    }
    return false;
  }

  Future<bool> deleteUnidadMedida(int id) async {
    try {
      final response = await _apiService.post('/unidad-medidas/$id?_method=DELETE', {});

      if (response.statusCode == 200) {
        _unidadesMedida.removeWhere((u) => u.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteUnidadMedida: $e');
    }
    return false;
  }
}
