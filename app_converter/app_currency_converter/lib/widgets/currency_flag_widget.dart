// lib/widgets/currency_flag_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/currency_flags.dart';

class CurrencyFlagWidget extends StatelessWidget {
  final String currencyCode;
  final double size;
  final bool showCode;
  final TextStyle? textStyle;

  const CurrencyFlagWidget({
    Key? key,
    required this.currencyCode,
    this.size = 24,
    this.showCode = true,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final countryCode = CurrencyFlags.getCountryCode(currencyCode).toLowerCase();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Contenedor para la bandera
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildFlagImage(countryCode),
        ),
        
        // Mostrar el código de moneda si se requiere
        if (showCode) ...[
          const SizedBox(width: 8),
          Text(
            currencyCode,
            style: textStyle ?? TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.7,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildFlagImage(String countryCode) {
    // URL para banderas SVG
    final flagUrl = 'https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/$countryCode.svg';
    
    try {
      return SvgPicture.network(
        flagUrl,
        placeholderBuilder: (context) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.0,
          ),
        ),
        fit: BoxFit.cover,
      );
    } catch (e) {
      // Fallback para cuando no se puede cargar la bandera
      return Container(
        color: Colors.grey.withOpacity(0.3),
        child: Center(
          child: Text(
            currencyCode.substring(0, 1),
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }
  }
}