import 'package:flutter/material.dart';
import '../providers/crud_provider.dart';
import 'app_colors.dart';

class CrudScreen extends StatefulWidget {
  const CrudScreen({super.key, required this.title, required this.provider, required this.load, required this.rows, required this.fields, required this.create, required this.update, required this.remove});
  final String title;
  final CrudProvider provider;
  final Future<void> Function() load;
  final List<Map<String, dynamic>> Function() rows;
  final Map<String, dynamic> fields;
  final Future<bool> Function(Map<String, dynamic>) create;
  final Future<bool> Function(int, Map<String, dynamic>) update;
  final Future<bool> Function(int) remove;

  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(widget.load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [IconButton(onPressed: widget.load, icon: const Icon(Icons.refresh), tooltip: 'Actualizar')],
      ),
      body: AnimatedBuilder(
        animation: widget.provider,
        builder: (context, _) {
          final rows = widget.rows().where((row) => row.values.any((value) => '$value'.toLowerCase().contains(query))).toList();
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: TextField(onChanged: (value) => setState(() => query = value.trim().toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Buscar'))),
                  const SizedBox(width: 12),
                  FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Nuevo')),
                ]),
                const SizedBox(height: 18),
                Expanded(child: _content(rows)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _content(List<Map<String, dynamic>> rows) {
    if (widget.provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (widget.provider.error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(widget.provider.error!), TextButton(onPressed: widget.load, child: const Text('Reintentar'))]));
    if (rows.isEmpty) return const Center(child: Text('No hay registros para mostrar.'));
    final columns = rows.first.keys.toList();
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      columns: [...columns.map((key) => DataColumn(label: Text(key))), const DataColumn(label: Text('Acciones'))],
      rows: rows.map((row) => DataRow(cells: [...columns.map((key) => DataCell(Text('${row[key] ?? ''}'))), DataCell(Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => _edit(row), icon: const Icon(Icons.edit_outlined), tooltip: 'Editar'), IconButton(onPressed: row['id'] == null ? null : () => widget.remove(row['id'] as int), icon: const Icon(Icons.delete_outline), tooltip: 'Eliminar')]))])).toList(),
    ));
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final values = {...widget.fields, if (row != null) ...row}..remove('id');
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _CrudForm(title: row == null ? 'Nuevo ${widget.title.toLowerCase()}' : 'Editar ${widget.title.toLowerCase()}', values: values));
    if (result == null) return;
    if (row == null) {
      await widget.create(result);
    } else {
      await widget.update(row['id'] as int, result);
    }
  }
}

class _CrudForm extends StatefulWidget {
  const _CrudForm({required this.title, required this.values});
  final String title;
  final Map<String, dynamic> values;
  @override State<_CrudForm> createState() => _CrudFormState();
}

class _CrudFormState extends State<_CrudForm> {
  late final Map<String, TextEditingController> controllers = {for (final entry in widget.values.entries) entry.key: TextEditingController(text: '${entry.value ?? ''}')};
  @override void dispose() { for (final controller in controllers.values) { controller.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: entry.value,
                keyboardType: widget.values[entry.key] is num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                decoration: InputDecoration(labelText: entry.key),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final result = <String, dynamic>{};
            for (final entry in controllers.entries) {
              final original = widget.values[entry.key];
              result[entry.key] = original is int ? int.tryParse(entry.value.text) ?? 0 : original is double ? double.tryParse(entry.value.text) ?? 0 : entry.value.text.trim();
            }
            Navigator.pop(context, result);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}