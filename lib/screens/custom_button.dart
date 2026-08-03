import 'package:flutter/material.dart';
import '../screens/app_colors.dart';

enum ButtonVariant { primary, outline, outlineGreen, danger }

/// Botón único que cubre todos los estilos usados en el panel:
/// Registrarse / Ingresar / Nuevo cliente (primary, rojo sólido),
/// Limpiar / Ver (outline gris), Editar (outline verde), Eliminar (danger).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool expand;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.expand = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(icon, size: 16),
          ),
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );

    switch (variant) {
      case ButtonVariant.primary:
        return _wrap(ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: child,
        ));
      case ButtonVariant.danger:
        return _wrap(ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: child,
        ));
      case ButtonVariant.outline:
        return _wrap(OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.borderLight),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: child,
        ));
      case ButtonVariant.outlineGreen:
        return _wrap(OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentGreen,
            side: const BorderSide(color: AppColors.accentGreen),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: child,
        ));
    }
  }

  Widget _wrap(Widget button) {
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
