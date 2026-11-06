import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/parametrizacion/insumo.dart';

class InsumoProvider with ChangeNotifier {

  final ApiService _apiService = ApiService();
  List<Insumo> _insumos = [];
  bool _isLoading = false;
  String? _error;

  List<Insumo> get insumos => _insumos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInsumos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.get('/insumos');

      debugPrint('GET /insumos -> ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> lista;
        if (decoded is List) {
          lista = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          lista = decoded['data'];
        } else if (decoded is Map && decoded['insumos'] is List) {
          lista = decoded['insumos'];
        } else {
          lista = [];
          _error = 'Formato de respuesta inesperado';
        }

        _insumos = lista
            .map((item) => Insumo.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('Insumos parseados: ${_insumos.length}');
      } else {
        _error = 'Error ${response.statusCode} al cargar insumos';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      debugPrint('Error fetch insumos: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createInsumo(Insumo insumo) async {
    try {
      final response = await _apiService.post('/insumos', insumo.toJson());

      if (response.statusCode == 201) {
        await fetchInsumos();
        return true;
      }
    } catch (e) {
      debugPrint('Error createInsumo: $e');
    }
    return false;
  }

  Future<bool> updateInsumo(Insumo insumo) async {
    try {
      final response = await _apiService.post('/insumos/${insumo.id}?_method=PUT', insumo.toJson());

      if (response.statusCode == 201) {
        await fetchInsumos();
        return true;
      }
    } catch (e) {
      debugPrint('Error updateInsumo: $e');
    }
    return false;
  }

  Future<bool> deleteInsumo(int id) async {
    try {
      final response = await _apiService.post('/insumos/$id?_method=DELETE', {});

      if (response.statusCode == 200) {
        _insumos.removeWhere((i) => i.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteInsumo: $e');
    }
    return false;
  }
}
