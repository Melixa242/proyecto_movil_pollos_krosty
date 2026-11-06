import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';

/// Revisión de los cambios hechos sin conexión que aún no llegaron al servidor.
class PendientesScreen extends StatefulWidget {
  const PendientesScreen({super.key});
  @override
  State<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends State<PendientesScreen> {
  List<Map<String, Object?>> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final items = await LocalDb.instance.listarPendientes();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _sincronizar() async {
    final sync = context.read<SyncService>();
    final messenger = ScaffoldMessenger.of(context);
    await sync.sincronizar();
    await _cargar();
    messenger.showSnackBar(SnackBar(
      content: Text(sync.online ? (sync.ultimoMensaje ?? 'Nada para sincronizar') : 'Sin conexión con el servidor'),
    ));
  }

  Future<void> _descartar(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Descartar cambio'),
        content: const Text('Este cambio no se enviará al servidor y se perderá. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Descartar')),
        ],
      ),
    );
    if (ok != true) return;
    await LocalDb.instance.eliminarPendiente(id);
    if (!mounted) return;
    await context.read<SyncService>().refrescarContador();
    await _cargar();
  }

  Future<void> _reintentar(int id) async {
    await LocalDb.instance.reintentar(id);
    await _cargar();
  }

  String _formatearBody(String? body) {
    if (body == null) return '(sin datos)';
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } catch (_) {
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambios pendientes'),
        actions: [
          TextButton.icon(
            onPressed: sync.sincronizando ? null : _sincronizar,
            icon: const Icon(Icons.sync),
            label: const Text('Sincronizar ahora'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _items.isEmpty
            ? ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('No hay cambios pendientes')),
              ])
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final p = _items[i];
                  final id = p['id'] as int;
                  final conError = p['estado'] == 'error';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ExpansionTile(
                      leading: Icon(
                        conError ? Icons.error : Icons.schedule,
                        color: conError ? Colors.red : Colors.orange,
                      ),
                      title: Text('[${p['api']}]  ${p['metodo']}  /${p['endpoint']}'),
                      subtitle: Text('#$id · ${p['creado_en']} · intentos: ${p['intentos']}'),
                      childrenPadding: const EdgeInsets.all(12),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (conError)
                          Text('Error: ${p['ultimo_error']}', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        SelectableText(_formatearBody(p['body'] as String?),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (conError)
                              TextButton.icon(
                                onPressed: () => _reintentar(id),
                                icon: const Icon(Icons.replay),
                                label: const Text('Reintentar'),
                              ),
                            TextButton.icon(
                              onPressed: () => _descartar(id),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text('Descartar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
