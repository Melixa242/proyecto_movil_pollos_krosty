import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Una opción de un desplegable cargado desde la API (id + texto visible).
class OpcionApi {
  final int id;
  final String nombre;
  const OpcionApi(this.id, this.nombre);
}

/// Carga una lista del backend (acepta lista plana o paginada en 'data')
/// y la convierte en opciones usando 'name' / 'nombre' como texto.
/// [api] elige el backend (web por defecto).
Future<List<OpcionApi>> cargarOpciones(String endpoint, {ApiService api = ApiService.web}) async {
  final response = await api.get(endpoint);
  if (response.statusCode != 200) return [];
  final decoded = jsonDecode(response.body);
  final lista = decoded is List
      ? decoded
      : (decoded is Map && decoded['data'] is List ? decoded['data'] as List : const []);
  return [
    for (final item in lista)
      if (item is Map && item['id'] != null)
        OpcionApi(
          int.parse('${item['id']}'),
          '${item['nombre'] ?? item['name'] ?? '#${item['id']}'}',
        ),
  ];
}

/// Desplegable de opciones cargadas con [cargarOpciones].
class SelectorApi extends StatelessWidget {
  final String label;
  final List<OpcionApi> opciones;
  final int? valor;
  final ValueChanged<int?> onChanged;

  const SelectorApi({
    super.key,
    required this.label,
    required this.opciones,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Si el valor guardado no está entre las opciones (p. ej. registro inactivo), se deja vacío.
    final existe = opciones.any((o) => o.id == valor);
    return DropdownButtonFormField<int>(
      initialValue: existe ? valor : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final o in opciones)
          DropdownMenuItem(value: o.id, child: Text(o.nombre, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onChanged,
    );
  }
}
