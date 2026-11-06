import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../models/parametrizacion/regla_conversion.dart';

class ReglaConversionProvider with ChangeNotifier {

  final ApiService _apiService = ApiService();
  List<ReglaConversion> _reglasConversion = [];
  bool _isLoading = false;
  String? _error;

  List<ReglaConversion> get reglasConversion => _reglasConversion;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReglasConversion() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.get('/regla-conversion');

      debugPrint('GET /regla-conversion -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> lista;
        if (decoded is List) {
          lista = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          lista = decoded['data'];
        } else if (decoded is Map && decoded['reglas'] is List) {
          lista = decoded['reglas'];
        } else {
          lista = [];
          _error = 'Formato de respuesta inesperado';
        }

        // El backend pagina de a 10: se piden las páginas restantes.
        final ultimaPagina = decoded is Map ? int.tryParse('${decoded['last_page']}') ?? 1 : 1;
        for (var pagina = 2; pagina <= ultimaPagina; pagina++) {
          final r = await _apiService.get('/regla-conversion?page=$pagina');
          if (r.statusCode != 200) break;
          final extra = jsonDecode(r.body);
          if (extra is Map && extra['data'] is List) lista = [...lista, ...extra['data']];
        }

        _reglasConversion = lista
            .map((item) => ReglaConversion.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        debugPrint('Reglas parseadas: ${_reglasConversion.length}');
      } else {
        _error = 'Error ${response.statusCode} al cargar reglas de conversión';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      debugPrint('Error fetch reglas: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReglaConversion(ReglaConversion regla) =>
      _guardar(() => _apiService.post('/regla-conversion', regla.toJson()));

  Future<bool> updateReglaConversion(ReglaConversion regla) =>
      _guardar(() => _apiService.put('/regla-conversion/${regla.id}', regla.toJson()));

  Future<bool> deleteReglaConversion(int id) =>
      _guardar(() => _apiService.delete('/regla-conversion/$id'));

  /// Motivo del último guardado/eliminado fallido (para mostrar en un SnackBar).
  String? errorGuardado;

  Future<bool> _guardar(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchReglasConversion();
        return true;
      }
      errorGuardado = _mensajeError(response.body, response.statusCode);
    } catch (e) {
      errorGuardado = 'Error de conexión: $e';
      debugPrint('Error guardando regla: $e');
    }
    return false;
  }

  /// Toma el primer error de validación de Laravel (422) o el 'message'.
  String _mensajeError(String body, int status) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
        final primero = (data['errors'] as Map).values.first;
        return primero is List ? '${primero.first}' : '$primero';
      }
      if (data is Map && data['message'] != null) return '${data['message']}';
    } catch (_) {}
    return 'Error $status al guardar';
  }
}
