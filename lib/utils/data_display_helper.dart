import 'package:flutter/material.dart';

class DataDisplayHelper {
  // Widget para mostrar un campo etiquetado
  static Widget labeledField(String label, String value, {TextStyle? valueStyle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ?? const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Widget para mostrar estatus con color
  static Widget statusBadge(String status, {double padding = 8}) {
    final colors = {
      'activo': Colors.green,
      'inactivo': Colors.red,
      'pendiente': Colors.orange,
      'completado': Colors.blue,
      'archivado': Colors.grey,
      'pausado': Colors.amber,
      'bajo': Colors.red,
      'ok': Colors.green,
    };

    final color = colors[status.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding + 4, vertical: padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Widget para mostrar fila de datos
  static Widget dataRow(String label, String value, {Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: trailingWidget ?? Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar card de información
  static Widget infoCard({
    required String title,
    required String subtitle,
    required String value,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: accentColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para mostrar indicador de progreso
  static Widget progressIndicator({
    required double value,
    required String label,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  // Widget para mostrar tabla simple
  static Widget simpleTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      columnWidths: {
        for (int i = 0; i < headers.length; i++)
          i: const FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          children: headers
              .map(
                (header) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    header,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows
            .map(
              (row) => TableRow(
                children: row
                    .map(
                      (cell) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          cell,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
      ],
    );
  }

  // Widget para mostrar lista de atributos
  static Widget attributesList({
    required Map<String, String> attributes,
    double spacing = 12,
  }) {
    return Column(
      children: attributes.entries
          .map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: dataRow(entry.key, entry.value),
            ),
          )
          .toList(),
    );
  }

  // Widget para mostrar campo de error
  static Widget errorField(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar campo de éxito
  static Widget successField(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar campo de advertencia
  static Widget warningField(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.amber[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar campo de información
  static Widget infoField(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
