import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'app_colors.dart';

/// Foto de un producto desde el storage de Laravel. Si no tiene foto, falla la
/// descarga o no hay conexión, muestra un ícono en su lugar.
class ProductoImagen extends StatelessWidget {
  final String? ruta;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const ProductoImagen({
    super.key,
    required this.ruta,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiService.web.urlArchivo(ruta);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        color: AppColors.background,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryRed.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) => Icon(
          Icons.fastfood_outlined,
          color: AppColors.primaryRed.withValues(alpha: 0.45),
          size: (constraints.biggest.shortestSide * 0.45).clamp(16.0, 48.0),
        ),
      ),
    );
  }
}
