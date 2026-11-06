import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'local_db.dart';

/// Envía al servidor los cambios hechos sin conexión, cada uno a su API (web o local).
class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  final LocalDb _db = LocalDb.instance;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;

  bool online = true;
  bool sincronizando = false;
  int pendientes = 0;
  String? ultimoMensaje;

  Future<void> iniciar() async {
    await refrescarContador();
    online = !(await Connectivity().checkConnectivity()).contains(ConnectivityResult.none);
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      final antes = online;
      online = !r.contains(ConnectivityResult.none);
      notifyListeners();
      if (online && !antes) sincronizar();
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Reintenta aunque esté offline: el servidor pudo volver sin cambio de red.
      if (pendientes > 0) sincronizar();
    });
    if (online) sincronizar();
  }

  Future<void> refrescarContador() async {
    pendientes = await _db.contarPendientes();
    notifyListeners();
  }

  Future<void> sincronizar() async {
    if (sincronizando) return;
    sincronizando = true;
    notifyListeners();
    var enviados = 0, conError = 0;
    // APIs que dejaron de responder (o sesión vencida) en esta pasada: sus
    // pendientes esperan a la próxima para respetar el orden; las demás siguen.
    final bloqueadas = <String>{};
    final sinRed = <String>{};

    try {
      for (final fila in await _db.listarPendientes(incluirConError: false)) {
        final api = ApiService.porNombre(fila['api'] as String?);
        if (bloqueadas.contains(api.nombre)) continue;
        final id = fila['id'] as int;
        // Se relee porque un envío anterior pudo reemplazar ids temporales en
        // este pendiente (p. ej. venta_id de un detalle), o pudo descartarse.
        final p = await _db.obtenerPendiente(id);
        if (p == null || p['estado'] != 'pendiente') continue;
        final metodo = p['metodo'] as String;
        final endpoint = p['endpoint'] as String;
        final body = p['body'] as String?;
        try {
          final r = await api.enviar(metodo, endpoint, body);
          if (r.statusCode >= 200 && r.statusCode < 300) {
            if (ApiService.tipoCambio(metodo, endpoint) == 'crear') {
              final idReal = _extraerId(r.body);
              if (idReal != null) await _reemplazarIdTemporal(api.nombre, -id, idReal);
            }
            await _db.eliminarPendiente(id);
            enviados++;
          } else if (r.statusCode == 401 && api.usaToken) {
            ultimoMensaje = 'Sesión vencida: iniciá sesión para sincronizar';
            bloqueadas.add(api.nombre);
          } else {
            final detalle = r.body.length > 300 ? r.body.substring(0, 300) : r.body;
            await _db.marcarError(id, 'HTTP ${r.statusCode}: $detalle');
            conError++;
          }
        } on Exception catch (e) {
          if (ApiService.esErrorDeRed(e)) {
            bloqueadas.add(api.nombre);
            sinRed.add(api.nombre);
            continue;
          }
          await _db.marcarError(id, e.toString());
          conError++;
        }
      }
      online = sinRed.isEmpty || enviados > 0;
      final sinConexion = sinRed.isEmpty ? '' : 'Sin conexión con: ${sinRed.join(', ')}';
      if (enviados > 0 || conError > 0) {
        ultimoMensaje = 'Sincronizados: $enviados'
            '${conError > 0 ? ' · Con error: $conError (revisar)' : ''}'
            '${sinConexion.isEmpty ? '' : ' · $sinConexion'}';
      } else if (sinConexion.isNotEmpty) {
        ultimoMensaje = sinConexion;
      }
    } finally {
      sincronizando = false;
      await refrescarContador();
    }
  }

  int? _extraerId(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map) {
        if (d['id'] is int) return d['id'] as int;
        for (final v in d.values) {
          if (v is Map && v['id'] is int) return v['id'] as int;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Reemplaza el id temporal (negativo) por el real en los pendientes restantes de la misma API.
  Future<void> _reemplazarIdTemporal(String api, int idTemporal, int idReal) async {
    final temp = idTemporal.toString();
    for (final p in await _db.listarPendientes()) {
      if (ApiService.porNombre(p['api'] as String?).nombre != api) continue;
      final endpoint = (p['endpoint'] as String)
          .split('/')
          .map((s) => s.split('?').first == temp ? s.replaceFirst(temp, '$idReal') : s)
          .join('/');
      final body = p['body'] as String?;
      String? nuevoBody = body;
      if (body != null) {
        nuevoBody = jsonEncode(_reemplazarEnJson(jsonDecode(body), idTemporal, idReal));
      }
      if (endpoint != p['endpoint'] || nuevoBody != body) {
        await _db.actualizarPendiente(p['id'] as int, endpoint, nuevoBody);
      }
    }
  }

  dynamic _reemplazarEnJson(dynamic v, int temp, int real) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(
            k,
            (k == 'id' || k.toString().endsWith('_id')) && val == temp
                ? real
                : _reemplazarEnJson(val, temp, real),
          ));
    }
    if (v is List) return v.map((e) => _reemplazarEnJson(e, temp, real)).toList();
    return v;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
