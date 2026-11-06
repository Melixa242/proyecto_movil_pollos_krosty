import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'custom_button.dart';

/// Descriptor de una columna de [PrettyCrudScreen]: cómo se llama y cómo se
/// obtiene su texto a partir de un item.
class PrettyColumn<T> {
  final String label;
  final int flex;
  final String Function(T item) value;
  const PrettyColumn({required this.label, required this.value, this.flex = 1});
}

/// Pantalla CRUD reutilizable con el look de las pantallas de Parametrización
/// (barra roja + subtítulo, buscador, tabla con acciones Ver/Editar/Eliminar).
/// En pantallas angostas (móvil) la tabla se reemplaza por tarjetas y el botón
/// "Nuevo" pasa a ser un botón flotante.
/// Cada pantalla concreta sólo define columnas, filtro de búsqueda y qué hacer
/// al tocar Nuevo/Ver/Editar/Eliminar (normalmente: abrir un diálogo propio).
class PrettyCrudScreen<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final String searchHint;
  final String newButtonLabel;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final List<T> items;
  final bool Function(T item, String query) matches;
  final List<PrettyColumn<T>> columns;
  final VoidCallback onNew;
  final void Function(T item)? onView;
  /// Texto del botón de [onView] (p. ej. 'Ejecutar').
  final String viewLabel;
  final void Function(T item) onEdit;
  final void Function(T item) onDelete;
  /// Widget opcional al inicio de cada registro (p. ej. la foto de un producto).
  final Widget Function(T item)? leading;

  const PrettyCrudScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.newButtonLabel,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.items,
    required this.matches,
    required this.columns,
    required this.onNew,
    required this.onEdit,
    required this.onDelete,
    this.onView,
    this.viewLabel = 'Ver',
    this.leading,
  });

  @override
  State<PrettyCrudScreen<T>> createState() => _PrettyCrudScreenState<T>();
}

class _PrettyCrudScreenState<T> extends State<PrettyCrudScreen<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String text) => setState(() => _query = text.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 700;
    final visible = _query.isEmpty
        ? widget.items
        : widget.items.where((item) => widget.matches(item, _query)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      // Botón de alta flotante y siempre visible, aunque se haga scroll en la lista.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onNew,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline, size: 24),
        label: Text(widget.newButtonLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primaryRed,
          onRefresh: () async => widget.onRetry(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Espacio inferior extra para que el botón flotante no tape la última tarjeta.
            padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, isNarrow ? 16 : 24, isNarrow ? 16 : 24, 96),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.subtitle, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    _SearchField(
                      hint: widget.searchHint,
                      controller: _searchController,
                      onChanged: _setQuery,
                      onClear: () {
                        _searchController.clear();
                        _setQuery('');
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!widget.isLoading && widget.error == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 2),
                        child: Text(
                          '${visible.length} ${visible.length == 1 ? 'registro' : 'registros'}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
                    if (widget.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (widget.error != null)
                      _ErrorBox(message: widget.error!, onRetry: widget.onRetry)
                    else if (visible.isEmpty)
                      _EmptyState(filtered: _query.isNotEmpty)
                    else if (isNarrow)
                      _MobileList<T>(
                        columns: widget.columns,
                        rows: visible,
                        leading: widget.leading,
                        onView: widget.onView,
                        viewLabel: widget.viewLabel,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                      )
                    else
                      _PrettyTable<T>(
                        columns: widget.columns,
                        rows: visible,
                        leading: widget.leading,
                        onView: widget.onView,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                        viewLabel: widget.viewLabel,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Buscador que filtra mientras se escribe.
class _SearchField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.hint,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(tooltip: 'Limpiar', icon: const Icon(Icons.close), onPressed: onClear),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.primaryRed),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.primaryRedDark))),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  /// true si no hay resultados por la búsqueda (no porque la lista esté vacía).
  final bool filtered;
  const _EmptyState({required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
            child: Icon(filtered ? Icons.search_off : Icons.inbox_outlined, color: AppColors.primaryRed, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            filtered ? 'Sin resultados para la búsqueda.' : 'Todavía no hay registros.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Vista móvil: una tarjeta por registro. La primera columna es el título;
/// el resto se muestra como pares etiqueta/valor.
class _MobileList<T> extends StatelessWidget {
  final List<PrettyColumn<T>> columns;
  final List<T> rows;
  final void Function(T item)? onView;
  final String viewLabel;
  final void Function(T item) onEdit;
  final void Function(T item) onDelete;
  final Widget Function(T item)? leading;

  const _MobileList({
    required this.columns,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
    this.onView,
    this.viewLabel = 'Ver',
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _card(i + 1, rows[i]),
          ),
      ],
    );
  }

  Widget _card(int numero, T item) {
    final first = columns.isEmpty ? null : columns.first;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                if (leading != null) ...[
                  SizedBox(width: 52, height: 52, child: leading!(item)),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('#$numero',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryRed)),
                ),
                const SizedBox(width: 10),
                if (first != null)
                  Expanded(
                    child: Text(
                      first.value(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
              ],
            ),
          ),
          for (final column in columns.skip(1))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 3, 16, 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(column.label,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text(column.value(item),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onView != null)
                  TextButton.icon(
                    onPressed: () => onView!(item),
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: Text(viewLabel),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
                  ),
                TextButton.icon(
                  onPressed: () => onEdit(item),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.accentGreen),
                ),
                TextButton.icon(
                  onPressed: () => onDelete(item),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryRed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrettyTable<T> extends StatelessWidget {
  final List<PrettyColumn<T>> columns;
  final List<T> rows;
  final void Function(T item)? onView;
  final String viewLabel;
  final void Function(T item) onEdit;
  final void Function(T item) onDelete;
  final Widget Function(T item)? leading;

  const _PrettyTable({
    required this.columns,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
    this.onView,
    this.viewLabel = 'Ver',
    this.leading,
  });

  static const double _leadingWidth = 60;

  static const TextStyle _headerStyle =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    final actionsWidth = onView != null ? 290.0 : 176.0;
    final tableWidth = 60.0 + (leading != null ? _leadingWidth : 0) + columns.length * 160.0 + actionsWidth;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rowDivider),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              // Ocupa todo el ancho disponible; sólo hace scroll si las columnas no caben.
              width: tableWidth > constraints.maxWidth ? tableWidth : constraints.maxWidth,
              child: Column(
                children: [
                  _headerRow(actionsWidth),
                  ...List.generate(rows.length, (i) => _dataRow(i + 1, rows[i], actionsWidth)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow(double actionsWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: AppColors.primaryRed,
      child: Row(
        children: [
          const SizedBox(width: 36, child: Text('#', style: _headerStyle)),
          if (leading != null) const SizedBox(width: _leadingWidth),
          for (final column in columns)
            Expanded(flex: column.flex, child: Text(column.label.toUpperCase(), style: _headerStyle)),
          SizedBox(width: actionsWidth, child: const Text('ACCIONES', textAlign: TextAlign.right, style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _dataRow(int numero, T item, double actionsWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        // Filas alternadas para facilitar la lectura.
        color: numero.isEven ? AppColors.tableHeaderBg : AppColors.cardBackground,
        border: const Border(bottom: BorderSide(color: AppColors.rowDivider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('$numero', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          if (leading != null)
            SizedBox(
              width: _leadingWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(width: 44, height: 44, child: leading!(item)),
              ),
            ),
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Text(column.value(item), style: const TextStyle(color: AppColors.textPrimary)),
            ),
          SizedBox(
            width: actionsWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onView != null) ...[
                  AppButton(label: viewLabel, variant: ButtonVariant.outline, onPressed: () => onView!(item)),
                  const SizedBox(width: 8),
                ],
                AppButton(label: 'Editar', variant: ButtonVariant.outlineGreen, onPressed: () => onEdit(item)),
                const SizedBox(width: 8),
                AppButton(label: 'Eliminar', variant: ButtonVariant.danger, onPressed: () => onDelete(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmación estándar de eliminación, reutilizada por todas las pantallas.
Future<bool> confirmDelete(BuildContext context, {String entity = 'este registro'}) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed, size: 32),
      title: const Text('Confirmar eliminación'),
      content: Text('¿Seguro que quieres eliminar $entity? Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Eliminar')),
      ],
    ),
  );
  return confirm == true;
}
