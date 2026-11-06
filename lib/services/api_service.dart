import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'local_db.dart';
import 'sync_service.dart';

class ApiService {
  const ApiService._(this.nombre, this.baseUrl, {required this.usaToken});

  /// Por compatibilidad: `ApiService()` es la API web.
  factory ApiService() => web;

  // Windows / Chrome (misma PC que el servidor):
  static const web = ApiService._('web', 'http://127.0.0.1:8000/api', usaToken: true);
  //static const web = ApiService._('web', 'http://10.0.2.2:8000/api', usaToken: true);

  // Servidor transaccional en Dart (E:\proyectoKrosty, puerto 8081), misma PC:
  static const local = ApiService._('local', 'http://127.0.0.1:8081/api', usaToken: false);
  //static const local = ApiService._('local', 'http://10.0.2.2:8081/api', usaToken: false);

  /// Instancia según el nombre guardado en SQLite ('web' | 'local').
  static ApiService porNombre(String? nombre) => nombre == local.nombre ? local : web;

  final String nombre;
  final String baseUrl;
  final bool usaToken;

  static const _timeout = Duration(seconds: 10);

  /// Endpoints que requieren servidor y nunca se encolan offline.
  static const _soloOnline = ['login', 'register', 'logout'];

  static const _tokenKey = 'auth_token';
  static const _storage = FlutterSecureStorage();

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) return token;
    // Migra el token de versiones anteriores (guardado en texto plano en SharedPreferences).
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_tokenKey);
    if (legacy != null) {
      await _storage.write(key: _tokenKey, value: legacy);
      await prefs.remove(_tokenKey);
    }
    return legacy;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = usaToken ? await getToken() : null;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// URL pública de un archivo del storage de Laravel ('productos/abc.png'),
  /// armada con el mismo servidor que usa la app (sin el sufijo '/api').
  String? urlArchivo(String? ruta) {
    if (ruta == null || ruta.isEmpty) return null;
    if (ruta.startsWith('http')) return ruta;
    final origen = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$origen/storage/${ruta.replaceFirst(RegExp(r'^/'), '')}';
  }

  String _path(String endpoint) => endpoint.replaceFirst(RegExp(r'^/'), '');
  Uri _uri(String path) => Uri.parse('$baseUrl/$path');

  Future<http.Response> get(String endpoint) async {
    final path = _path(endpoint);
    try {
      final response = await http.get(_uri(path), headers: await _getHeaders()).timeout(_timeout);
      if (response.statusCode == 200) await LocalDb.instance.guardarCache(nombre, path, response.body);
      return response;
    } on Exception catch (e) {
      if (!esErrorDeRed(e)) rethrow;
      final cached = await LocalDb.instance.leerCache(nombre, path);
      if (cached == null) rethrow;
      return http.Response(cached, 200, headers: {'x-offline': '1'});
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) =>
      _enviarOEncolar('POST', _path(endpoint), jsonEncode(data));

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) =>
      _enviarOEncolar('PUT', _path(endpoint), jsonEncode(data));

  Future<http.Response> delete(String endpoint) =>
      _enviarOEncolar('DELETE', _path(endpoint), null);

  /// POST multipart (campos + un archivo opcional). Sólo online: un archivo no
  /// se puede encolar offline, así que un error de red se propaga al llamador.
  Future<http.Response> postMultipart(
    String endpoint,
    Map<String, String> campos, {
    String? campoArchivo,
    List<int>? bytes,
    String? nombreArchivo,
  }) async {
    final request = http.MultipartRequest('POST', _uri(_path(endpoint)))
      ..headers.addAll(await _getHeaders())
      ..fields.addAll(campos);
    // El boundary multipart lo pone MultipartRequest; el Content-Type JSON no aplica.
    request.headers.remove('Content-Type');
    if (campoArchivo != null && bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(campoArchivo, bytes, filename: nombreArchivo ?? 'archivo'));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    return http.Response.fromStream(streamed);
  }

  /// Envía directo al servidor sin encolar. También lo usa SyncService.
  Future<http.Response> enviar(String metodo, String path, String? body) async {
    final uri = _uri(path);
    final headers = await _getHeaders();
    final request = switch (metodo) {
      'POST' => http.post(uri, headers: headers, body: body),
      'PUT' => http.put(uri, headers: headers, body: body),
      'DELETE' => http.delete(uri, headers: headers),
      _ => throw ArgumentError('Método no soportado: $metodo'),
    };
    return request.timeout(_timeout);
  }

  Future<http.Response> _enviarOEncolar(String metodo, String path, String? body) async {
    try {
      return await enviar(metodo, path, body);
    } on Exception catch (e) {
      if (!esErrorDeRed(e) || _soloOnline.any(path.startsWith)) rethrow;
      final idPendiente = await LocalDb.instance.encolar(nombre, metodo, path, body);
      SyncService.instance.refrescarContador();
      final tipo = tipoCambio(metodo, path);
      await _aplicarEnCache(tipo, path, body, idPendiente);
      return http.Response(
        jsonEncode({'offline': true, 'pendiente_id': idPendiente}),
        tipo == 'crear' ? 201 : 200,
        headers: {'x-offline': '1'},
      );
    }
  }

  static bool esErrorDeRed(Object e) => e is http.ClientException || e is TimeoutException;

  /// 'crear' | 'editar' | 'eliminar' según el método real (Laravel usa ?_method=).
  static String tipoCambio(String metodo, String path) {
    final m = Uri.parse(path).queryParameters['_method']?.toUpperCase() ?? metodo;
    if (m == 'DELETE') return 'eliminar';
    if (m == 'PUT' || m == 'PATCH') return 'editar';
    return 'crear';
  }

  /// Refleja el cambio offline en la lista cacheada para que la pantalla lo muestre.
  /// Los registros creados offline reciben id temporal negativo (-idPendiente).
  Future<void> _aplicarEnCache(String tipo, String path, String? body, int idPendiente) async {
    final segmentos = Uri.parse(path).path.split('/');
    final esCrear = tipo == 'crear';
    final recurso = (esCrear ? segmentos : segmentos.sublist(0, segmentos.length - 1)).join('/');
    final id = esCrear ? -idPendiente : int.tryParse(segmentos.last);
    final cached = await LocalDb.instance.leerCache(nombre, recurso);
    if (cached == null || id == null) return;

    final decoded = jsonDecode(cached);
    final lista = _extraerLista(decoded, recurso.split('/').last);
    if (lista == null) return;

    final datos = body == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(body) as Map);
    bool mismoId(dynamic e) => e is Map && e['id']?.toString() == id.toString();
    switch (tipo) {
      case 'crear':
        lista.add({...datos, 'id': id});
      case 'editar':
        final i = lista.indexWhere(mismoId);
        if (i >= 0) lista[i] = {...(lista[i] as Map), ...datos, 'id': id};
      case 'eliminar':
        lista.removeWhere(mismoId);
    }
    await LocalDb.instance.guardarCache(nombre, recurso, jsonEncode(decoded));
  }

  List<dynamic>? _extraerLista(dynamic decoded, String clave) {
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) return decoded['data'];
    if (decoded is Map && decoded[clave] is List) return decoded[clave];
    return null;
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
