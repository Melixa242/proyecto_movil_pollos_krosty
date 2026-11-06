import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/parametrizacion/producto_composicion.dart';

/// El backend guarda la composición por producto padre: cada guardado manda la
/// lista COMPLETA de ingredientes de ese producto ({producto_id, ingredientes}).
/// Acá se trabaja por filas padre → hijo y se arma esa lista antes de enviar.
class ProductoComposicionProvider with ChangeNotifier {
  static const _endpoint = '/componentes-producto';

  final ApiService _apiService = ApiService();
  List<ProductoComposicion> _composiciones = [];
  bool _isLoading = false;
  String? _error;

  List<ProductoComposicion> get composiciones => _composiciones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Motivo del último guardado/eliminado fallido (para mostrar en un SnackBar).
  String? errorGuardado;

  Future<void> fetchComposiciones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.get(_endpoint);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> lista;
        if (decoded is List) {
          lista = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          lista = decoded['data'];
        } else {
          lista = [];
          _error = 'Formato de respuesta inesperado';
        }

        // El backend devuelve productos con sus 'ingredientes' (pivot con cantidad):
        // se aplana a una fila por cada par padre → hijo.
        _composiciones = [];
        for (final item in lista) {
          final producto = Map<String, dynamic>.from(item as Map);
          final ingredientes = producto['ingredientes'];
          if (ingredientes is! List) continue;
          for (final ing in ingredientes) {
            final ingrediente = Map<String, dynamic>.from(ing as Map);
            final pivot = ingrediente['pivot'] as Map? ?? {};
            _composiciones.add(ProductoComposicion(
              id: producto['id'],
              productoPadreId: producto['id'] ?? 0,
              productoHijoId: ingrediente['id'] ?? 0,
              // Offline el ingrediente queda como {id, cantidad} sin pivot.
              cantidad: double.tryParse('${pivot['cantidad'] ?? ingrediente['cantidad']}') ?? 0.0,
              estado: '${pivot['estado'] ?? 1}',
              productoPadreNombre: '${producto['nombre'] ?? ''}',
              productoHijoNombre: '${ingrediente['nombre'] ?? ''}',
            ));
          }
        }
      } else {
        _error = 'Error ${response.statusCode} al cargar composiciones';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      debugPrint('Error fetch composiciones: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Ingredientes actuales de un producto padre, sin el hijo indicado.
  List<ProductoComposicion> _ingredientesDe(int padreId, {int? sinHijo}) => _composiciones
      .where((c) => c.productoPadreId == padreId && c.productoHijoId != sinHijo)
      .toList();

  /// Reemplaza todos los ingredientes de [padreId]. Si queda vacío, elimina la composición.
  Future<bool> _guardarIngredientes(int padreId, List<ProductoComposicion> ingredientes,
      {required bool esNuevo}) async {
    final body = {
      'producto_id': padreId,
      'ingredientes': ingredientes.map((c) => c.toIngrediente()).toList(),
    };
    final response = ingredientes.isEmpty
        ? await _apiService.delete('$_endpoint/$padreId')
        : esNuevo
            ? await _apiService.post(_endpoint, body)
            : await _apiService.put('$_endpoint/$padreId', body);
    if (response.statusCode == 200 || response.statusCode == 201) return true;
    errorGuardado = _mensajeError(response.body, response.statusCode);
    return false;
  }

  /// Agrega varios productos hijos a [padreId] en un solo guardado.
  /// Si el padre ya tenía composición se conservan sus ingredientes; un hijo
  /// que ya existía se reemplaza (se actualiza su cantidad).
  Future<bool> createComposiciones(int padreId, List<ProductoComposicion> hijos) async {
    try {
      final nuevos = hijos.map((h) => h.productoHijoId).toSet();
      final previos = _ingredientesDe(padreId);
      final conservados = previos.where((c) => !nuevos.contains(c.productoHijoId)).toList();
      final ok = await _guardarIngredientes(padreId, [...conservados, ...hijos],
          esNuevo: previos.isEmpty);
      if (ok) await fetchComposiciones();
      return ok;
    } catch (e) {
      errorGuardado = 'Error de conexión: $e';
      debugPrint('Error createComposiciones: $e');
    }
    return false;
  }

  /// [original] es la fila que se editó; [actualizada] trae los valores nuevos
  /// (puede cambiar de producto padre o de hijo).
  Future<bool> updateComposicion(
      ProductoComposicion original, ProductoComposicion actualizada) async {
    try {
      final padreViejo = original.productoPadreId;
      final padreNuevo = actualizada.productoPadreId;

      if (padreViejo != padreNuevo) {
        // Se saca del padre anterior...
        final restantes = _ingredientesDe(padreViejo, sinHijo: original.productoHijoId);
        if (!await _guardarIngredientes(padreViejo, restantes, esNuevo: false)) return false;
      }

      // ...y se guarda en el padre nuevo (reemplazando el hijo anterior si es el mismo padre).
      final base = _ingredientesDe(padreNuevo, sinHijo: actualizada.productoHijoId)
          .where((c) => padreViejo != padreNuevo || c.productoHijoId != original.productoHijoId)
          .toList();
      final ok = await _guardarIngredientes(padreNuevo, [...base, actualizada],
          esNuevo: padreViejo != padreNuevo && _ingredientesDe(padreNuevo).isEmpty);
      await fetchComposiciones();
      return ok;
    } catch (e) {
      errorGuardado = 'Error de conexión: $e';
      debugPrint('Error updateComposicion: $e');
    }
    return false;
  }

  Future<bool> deleteComposicion(ProductoComposicion composicion) async {
    try {
      final padre = composicion.productoPadreId;
      final restantes = _ingredientesDe(padre, sinHijo: composicion.productoHijoId);
      final ok = await _guardarIngredientes(padre, restantes, esNuevo: false);
      if (ok) await fetchComposiciones();
      return ok;
    } catch (e) {
      errorGuardado = 'Error de conexión: $e';
      debugPrint('Error deleteComposicion: $e');
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
