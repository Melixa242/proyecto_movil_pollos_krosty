int modelInt(dynamic value) {
  return value is int ? value : int.tryParse('$value') ?? 0;
}

double modelDouble(dynamic value) {
  return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

String modelString(dynamic value) {
  return value?.toString() ?? '';
}

/// Para ids opcionales: la API Dart los devuelve como texto ("23").
int? modelIntOrNull(dynamic value) {
  return value is int ? value : int.tryParse('${value ?? ''}');
}
