import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

abstract class CrudProvider<T> extends ChangeNotifier {
  /// [api] elige el backend: web (por defecto) o local (transaccional).
  CrudProvider(this.endpoint, this.fromJson, this.toJson, {ApiService? api})
      : api = api ?? ApiService.web;
  final String endpoint;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final ApiService api;
  final List<T> items = [];
  bool isLoading = false;
  String? error;

  // Evita notificar si la pantalla dueña del provider se cerró durante un await.
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

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await api.get(endpoint);
      if (response.statusCode != 200) {
        error = 'Error ${response.statusCode} al cargar $endpoint';
      } else {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawData;
        if (decoded is List) {
          rawData = List<dynamic>.from(decoded);
        } else if (decoded is Map && decoded['data'] is List) {
          rawData = List<dynamic>.from(decoded['data'] as List);
        } else if (decoded is Map && decoded[endpoint.split('/').last] is List) {
          rawData = List<dynamic>.from(decoded[endpoint.split('/').last] as List);
        } else {
          rawData = <dynamic>[];
        }

        final parsedItems = <T>[];
        for (final item in rawData) {
          parsedItems.add(fromJson(Map<String, dynamic>.from(item as Map)));
        }
        items.clear();
        items.addAll(parsedItems);
      }
    } catch (e) {
      error = 'Error de conexión: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> create(T item) => _mutate('POST', endpoint, item);
  Future<bool> update(int id, T item) => _mutate('PUT', '$endpoint/$id', item);

  Future<bool> remove(int id) async {
    try {
      // PUT/DELETE reales: la API Dart (shelf) no entiende ?_method=; Laravel acepta ambos.
      final response = await api.delete('$endpoint/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        items.removeWhere((item) => _id(item) == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      error = 'Error de conexión: $e';
    }
    return false;
  }

  Future<bool> _mutate(String method, String path, T item) async {
    try {
      final response = method == 'POST' ? await api.post(path, toJson(item)) : await api.put(path, toJson(item));
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        await fetch();
        return true;
      }
      error = 'Error ${response.statusCode} al guardar';
    } catch (e) {
      error = 'Error de conexión: $e';
    }
    notifyListeners();
    return false;
  }

  /// POST (o PUT si hay [id]) de la cabecera con sus líneas bajo [key] en el mismo
  /// body: el servidor guarda todo en una transacción. Devuelve null si se guardó,
  /// o el mensaje de error (sin tocar [error], que la pantalla usa para el listado).
  Future<String?> saveWithLines(T item, String key, List<Map<String, dynamic>> lines, {int? id}) async {
    try {
      final body = {...toJson(item), key: lines};
      final response = id == null ? await api.post(endpoint, body) : await api.put('$endpoint/$id', body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetch();
        return null;
      }
      return _serverError(response.body) ?? 'Error ${response.statusCode} al guardar';
    } catch (e) {
      return 'Error de conexión: $e';
    }
  }

  /// Líneas de un registro (p. ej. `/ingreso-insumos/3/detalles`).
  Future<List<Map<String, dynamic>>> fetchLines(String path) async {
    final response = await api.get(path);
    final decoded = response.statusCode == 200 ? jsonDecode(response.body) : null;
    if (decoded is! List) return [];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  String? _serverError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) return decoded['error'].toString();
    } catch (_) {}
    return null;
  }

  int? _id(T item) => (item as dynamic).id as int?;
}