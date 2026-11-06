import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../models/parametrizacion/producto.dart';

/// Foto elegida en el formulario para subir con el producto.
class ProductoFoto {
  final Uint8List bytes;
  final String nombre;
  const ProductoFoto(this.bytes, this.nombre);
}

class ProductoProvider with ChangeNotifier {

  /// [api] permite usar este provider contra la API local (p. ej. en ventas).
  ProductoProvider({ApiService? api}) : _apiService = api ?? ApiService.web;

  final ApiService _apiService;
  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _error;

  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProductos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.get('/productos');

      debugPrint('GET /productos -> ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> lista;
        if (decoded is List) {
          lista = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          lista = decoded['data'];
        } else if (decoded is Map && decoded['productos'] is List) {
          lista = decoded['productos'];
        } else {
          lista = [];
          _error = 'Formato de respuesta inesperado';
        }

        _productos = lista
            .map((item) => Producto.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('Productos parseados: ${_productos.length}');
      } else {
        _error = 'Error ${response.statusCode} al cargar productos';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      debugPrint('Error fetch productos: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Si hay [foto] nueva o [quitarFoto], se envía como multipart (requiere conexión);
  /// si no, como JSON, que admite la cola offline.
  Future<http.Response> _guardar(String endpoint, Producto producto, ProductoFoto? foto, bool quitarFoto) {
    if (foto == null && !quitarFoto) return _apiService.post(endpoint, producto.toJson());
    final campos = {
      for (final e in producto.toJson().entries)
        if (e.key != 'id' && e.value != null) e.key: _campo(e.value),
      if (quitarFoto) 'quitar_imagen': '1',
    };
    return _apiService.postMultipart(endpoint, campos,
        campoArchivo: foto == null ? null : 'imagen', bytes: foto?.bytes, nombreArchivo: foto?.nombre);
  }

  /// Números enteros sin '.0' (Laravel valida cantidad_actual como integer).
  static String _campo(Object value) =>
      value is double && value == value.roundToDouble() ? value.toInt().toString() : '$value';

  Future<bool> createProducto(Producto producto, {ProductoFoto? foto}) async {
    try {
      final response = await _guardar('/productos', producto, foto, false);

      if (response.statusCode == 201) {
        await fetchProductos();
        return true;
      }
      debugPrint('createProducto -> ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('Error createProducto: $e');
    }
    return false;
  }

  Future<bool> updateProducto(Producto producto, {ProductoFoto? foto, bool quitarFoto = false}) async {
    try {
      final response = await _guardar('/productos/${producto.id}?_method=PUT', producto, foto, quitarFoto);

      // Laravel responde 200 al actualizar (201 sólo al crear).
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchProductos();
        return true;
      }
      debugPrint('updateProducto -> ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('Error updateProducto: $e');
    }
    return false;
  }

  Future<bool> deleteProducto(int id) async {
    try {
      final response = await _apiService.post('/productos/$id?_method=DELETE', {});

      if (response.statusCode == 200) {
        _productos.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteProducto: $e');
    }
    return false;
  }
}
