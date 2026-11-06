import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';
import 'pendientes_screen.dart';

/// Indicador de conexión y cambios pendientes. Al tocarlo abre la revisión.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final (color, icono, texto) = switch (sync) {
      SyncService(sincronizando: true) => (Colors.blue, Icons.sync, 'Sincronizando…'),
      SyncService(online: false) => (Colors.red, Icons.cloud_off, 'Sin conexión · ${sync.pendientes}'),
      SyncService(pendientes: > 0) => (Colors.orange, Icons.cloud_upload, '${sync.pendientes} pendientes'),
      _ => (Colors.green, Icons.cloud_done, 'En línea'),
    };
    return ActionChip(
      avatar: Icon(icono, color: color, size: 18),
      label: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      side: BorderSide(color: color),
      backgroundColor: Colors.white,
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PendientesScreen())),
    );
  }
}
