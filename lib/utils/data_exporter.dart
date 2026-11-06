import 'dart:convert';

class DataExporter {
  // Exportar a JSON
  static String toJson(List<Map<String, dynamic>> data) {
    return jsonEncode(data);
  }

  // Exportar a JSON formateado
  static String toJsonPretty(List<Map<String, dynamic>> data) {
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  // Exportar a CSV
  static String toCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.toList();
    final rows = <String>[];

    // Agregar encabezados
    rows.add(_escapeCsvField(headers.join(',')));

    // Agregar filas
    for (final row in data) {
      final values = headers.map((key) => row[key]?.toString() ?? '').toList();
      rows.add(_escapeCsvField(values.join(',')));
    }

    return rows.join('\n');
  }

  // Escapar campos CSV
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Importar desde JSON
  static List<Map<String, dynamic>> fromJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      throw Exception('Error al decodificar JSON: $e');
    }
  }

  // Importar desde CSV
  static List<Map<String, dynamic>> fromCsv(String csvString) {
    try {
      final lines = csvString.split('\n');
      if (lines.isEmpty) return [];

      final headers = _parseCsvLine(lines[0]);
      final data = <Map<String, dynamic>>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = _parseCsvLine(line);
        final row = <String, dynamic>{};

        for (int j = 0; j < headers.length && j < values.length; j++) {
          row[headers[j]] = values[j];
        }

        data.add(row);
      }

      return data;
    } catch (e) {
      throw Exception('Error al decodificar CSV: $e');
    }
  }

  // Parsear línea CSV
  static List<String> _parseCsvLine(String line) {
    final values = <String>[];
    var currentValue = '';
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          currentValue += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(currentValue.trim());
        currentValue = '';
      } else {
        currentValue += char;
      }
    }

    values.add(currentValue.trim());
    return values;
  }

  // Crear tabla HTML
  static String toHtmlTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '<table><tr><td>No hay datos</td></tr></table>';

    final headers = data.first.keys.toList();
    final buffer = StringBuffer();

    buffer.writeln('<table border="1" cellpadding="5">');
    buffer.writeln('<thead><tr>');

    for (final header in headers) {
      buffer.writeln('<th>$header</th>');
    }

    buffer.writeln('</tr></thead>');
    buffer.writeln('<tbody>');

    for (final row in data) {
      buffer.writeln('<tr>');
      for (final header in headers) {
        final value = row[header]?.toString() ?? '';
        buffer.writeln('<td>$value</td>');
      }
      buffer.writeln('</tr>');
    }

    buffer.writeln('</tbody>');
    buffer.writeln('</table>');

    return buffer.toString();
  }

  // Crear reporte de texto
  static String toTextReport(List<Map<String, dynamic>> data, {String title = 'Reporte'}) {
    if (data.isEmpty) return '$title\n\nNo hay datos disponibles.';

    final buffer = StringBuffer();
    buffer.writeln('═' * 80);
    buffer.writeln(title);
    buffer.writeln('═' * 80);
    buffer.writeln('Registros totales: ${data.length}');
    buffer.writeln('');

    for (int i = 0; i < data.length; i++) {
      buffer.writeln('Registro ${i + 1}:');
      final row = data[i];
      for (final entry in row.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln('');
    }

    buffer.writeln('═' * 80);

    return buffer.toString();
  }

  // Obtener resumen de datos
  static Map<String, dynamic> getSummary(List<Map<String, dynamic>> data) {
    return {
      'total_registros': data.length,
      'fecha_generacion': DateTime.now().toString(),
      'campos': data.isNotEmpty ? data.first.keys.toList() : [],
    };
  }
}
