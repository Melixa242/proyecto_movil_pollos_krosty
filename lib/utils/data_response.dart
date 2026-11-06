class DataResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  DataResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory DataResponse.success(T data, {String? message}) {
    return DataResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory DataResponse.error(String error) {
    return DataResponse(
      success: false,
      error: error,
    );
  }

  factory DataResponse.loading() {
    return DataResponse(
      success: false,
      message: 'Cargando...',
    );
  }
}

class ListResponse<T> {
  final bool success;
  final List<T> items;
  final int total;
  final String? message;
  final String? error;

  ListResponse({
    required this.success,
    this.items = const [],
    this.total = 0,
    this.message,
    this.error,
  });

  factory ListResponse.success(List<T> items, {int? total}) {
    return ListResponse(
      success: true,
      items: items,
      total: total ?? items.length,
    );
  }

  factory ListResponse.error(String error) {
    return ListResponse(
      success: false,
      error: error,
    );
  }

  factory ListResponse.empty() {
    return ListResponse(
      success: true,
      items: [],
      total: 0,
      message: 'No hay registros',
    );
  }
}

class PaginatedResponse<T> {
  final bool success;
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int total;
  final String? error;

  PaginatedResponse({
    required this.success,
    this.items = const [],
    this.currentPage = 1,
    this.totalPages = 0,
    this.pageSize = 10,
    this.total = 0,
    this.error,
  });

  factory PaginatedResponse.success({
    required List<T> items,
    required int currentPage,
    required int totalPages,
    required int pageSize,
    required int total,
  }) {
    return PaginatedResponse(
      success: true,
      items: items,
      currentPage: currentPage,
      totalPages: totalPages,
      pageSize: pageSize,
      total: total,
    );
  }

  factory PaginatedResponse.error(String error) {
    return PaginatedResponse(
      success: false,
      error: error,
    );
  }

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}

class OperationResult {
  final bool success;
  final String message;
  final dynamic data;
  final List<String> errors;

  OperationResult({
    required this.success,
    required this.message,
    this.data,
    this.errors = const [],
  });

  factory OperationResult.success({
    required String message,
    dynamic data,
  }) {
    return OperationResult(
      success: true,
      message: message,
      data: data,
    );
  }

  factory OperationResult.error({
    required String message,
    List<String> errors = const [],
  }) {
    return OperationResult(
      success: false,
      message: message,
      errors: errors,
    );
  }

  String getErrorMessage() {
    if (errors.isEmpty) return message;
    return '$message\n${errors.join('\n')}';
  }
}
