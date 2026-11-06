class FormatUtils {
  // Formatear moneda
  static String formatCurrency(double value, {String symbol = '\$', int decimals = 2}) {
    return '$symbol${value.toStringAsFixed(decimals)}';
  }

  // Formatear cantidad
  static String formatQuantity(double value, {int decimals = 2}) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(decimals);
  }

  // Formatear porcentaje
  static String formatPercentage(double value, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Capitalizar primera letra
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Formatear estado con color
  static String getStatusDisplay(String status) {
    final statusMap = {
      'activo': 'Activo',
      'inactivo': 'Inactivo',
      'pendiente': 'Pendiente',
      'completado': 'Completado',
      'archivado': 'Archivado',
    };
    return statusMap[status.toLowerCase()] ?? capitalize(status);
  }

  // Formatear fecha
  static String formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  // Validar email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  // Validar teléfono
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\d{7,15}$');
    return phoneRegex.hasMatch(phone.replaceAll('-', '').replaceAll(' ', ''));
  }

  // Truncar texto
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Colorear estado
  static Map<String, String> getStatusColor(String status) {
    final colorMap = {
      'activo': '#4CAF50',      // Green
      'inactivo': '#F44336',    // Red
      'pendiente': '#FF9800',   // Orange
      'completado': '#2196F3',  // Blue
      'archivado': '#9E9E9E',   // Grey
    };
    return {'color': colorMap[status.toLowerCase()] ?? '#757575'};
  }
}
