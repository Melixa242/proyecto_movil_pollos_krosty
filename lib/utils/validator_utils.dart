class ValidatorUtils {
  // Validar campos requeridos
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  // Validar email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email es requerido';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  // Validar teléfono
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Teléfono es requerido';
    }
    final phoneRegex = RegExp(r'^\d{7,15}$');
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (!phoneRegex.hasMatch(clean)) {
      return 'Teléfono debe tener entre 7 y 15 dígitos';
    }
    return null;
  }

  // Validar número
  static String? validateNumber(String? value, String fieldName, {double? minValue, double? maxValue}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }
    if (minValue != null && number < minValue) {
      return '$fieldName no puede ser menor a $minValue';
    }
    if (maxValue != null && number > maxValue) {
      return '$fieldName no puede ser mayor a $maxValue';
    }
    return null;
  }

  // Validar número entero
  static String? validateInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    if (int.tryParse(value) == null) {
      return '$fieldName debe ser un número entero válido';
    }
    return null;
  }

  // Validar longitud mínima
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    if (value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }
    return null;
  }

  // Validar longitud máxima
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    if (value.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }
    return null;
  }

  // Validar coincidencia de campos
  static String? validateMatch(String? value1, String? value2, String fieldName) {
    if (value1 != value2) {
      return '$fieldName no coinciden';
    }
    return null;
  }

  // Validar URL
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL es requerida';
    }
    try {
      Uri.parse(value);
      if (!value.startsWith('http://') && !value.startsWith('https://')) {
        return 'URL debe comenzar con http:// o https://';
      }
      return null;
    } catch (e) {
      return 'URL inválida';
    }
  }

  // Validar fecha
  static String? validateDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Fecha es requerida';
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Formato de fecha inválido (use YYYY-MM-DD)';
    }
  }

  // Validar rango de números
  static String? validateRange(String? value, double min, double max, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }
    if (number < min || number > max) {
      return '$fieldName debe estar entre $min y $max';
    }
    return null;
  }

  // Validar solo números
  static String? validateNumericOnly(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return '$fieldName debe contener solo números';
    }
    return null;
  }

  // Validar solo letras
  static String? validateAlphaOnly(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName debe contener solo letras';
    }
    return null;
  }

  // Validar alfanumérico
  static String? validateAlphanumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return '$fieldName debe contener solo letras y números';
    }
    return null;
  }

  // Validar contraseña segura
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contraseña es requerida';
    }
    if (value.length < 8) {
      return 'Contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Contraseña debe contener al menos una mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Contraseña debe contener al menos una minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Contraseña debe contener al menos un número';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Contraseña debe contener al menos un carácter especial';
    }
    return null;
  }
}
