import 'package:flutter/material.dart';

/// Línea editable de un ingreso (insumo o producto, cantidad y precio unitario).
class LineaIngreso {
  int? itemId;
  double cantidad;
  double precio;
  LineaIngreso({this.itemId, this.cantidad = 1, this.precio = 0});
}

/// Lista editable de líneas para los ingresos de insumos y de bebidas.
/// Modifica [lineas] en el lugar; [opciones] es id → nombre del ítem.
class LineasIngresoEditor extends StatefulWidget {
  final String itemLabel;
  final Map<int, String> opciones;
  final List<LineaIngreso> lineas;

  /// false oculta el precio (p. ej. insumos de una orden de producción).
  final bool conPrecio;

  const LineasIngresoEditor({
    super.key,
    required this.itemLabel,
    required this.opciones,
    required this.lineas,
    this.conPrecio = true,
  });

  /// Mensaje de error si las líneas no se pueden enviar, o null si están bien.
  static String? validar(List<LineaIngreso> lineas, String itemLabel) {
    if (lineas.isEmpty) return 'Agrega al menos un ${itemLabel.toLowerCase()}.';
    final vistos = <int>{};
    for (final l in lineas) {
      if (l.itemId == null) {
        return 'Selecciona el ${itemLabel.toLowerCase()} de cada línea.';
      }
      if (l.cantidad <= 0) return 'La cantidad debe ser mayor a 0.';
      if (l.precio < 0) return 'El precio no puede ser negativo.';
      if (!vistos.add(l.itemId!)) {
        return 'Hay un ${itemLabel.toLowerCase()} repetido.';
      }
    }
    return null;
  }

  @override
  State<LineasIngresoEditor> createState() => _LineasIngresoEditorState();
}

class _LineasIngresoEditorState extends State<LineasIngresoEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.itemLabel}s',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => widget.lineas.add(LineaIngreso())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        if (widget.lineas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin ${widget.itemLabel.toLowerCase()}s',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        for (final linea in widget.lineas)
          Padding(
            key: ObjectKey(linea),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: widget.opciones.containsKey(linea.itemId)
                        ? linea.itemId
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: widget.itemLabel,
                      isDense: true,
                    ),
                    items: widget.opciones.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(
                              e.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => linea.itemId = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _num(linea.cantidad),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) =>
                        linea.cantidad = double.tryParse(v.trim()) ?? 0,
                  ),
                ),
                if (widget.conPrecio) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: _num(linea.precio),
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) =>
                          linea.precio = double.tryParse(v.trim()) ?? -1,
                    ),
                  ),
                ],
                IconButton(
                  onPressed: () => setState(() => widget.lineas.remove(linea)),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
