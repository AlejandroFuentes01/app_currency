// lib/widgets/conversion_result.dart

import 'package:flutter/material.dart';

import '../widgets/currency_flag_widget.dart';

class ConversionResult extends StatelessWidget {
  final String fromCurrency;
  final String toCurrency;
  final String amount;
  final double result;
  final bool isLoading;
  final String updateInfo;

  const ConversionResult({
    Key? key,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.result,
    required this.isLoading,
    this.updateInfo = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;
    
    // Calcular la tasa de cambio por unidad
    double unitRate = 0;
    if (amount.isNotEmpty && double.tryParse(amount.replaceAll(',', '.')) != null && result > 0) {
      final amountValue = double.parse(amount.replaceAll(',', '.'));
      if (amountValue > 0) {
        unitRate = result / amountValue;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? colorScheme.surface
            : colorScheme.primaryContainer.withAlpha(128), // ~0.5 opacity
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // ~0.1 opacity
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Resultado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          isLoading
              ? CircularProgressIndicator(color: colorScheme.primary)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${amount.isEmpty ? "0" : amount} ',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    CurrencyFlagWidget(
                      currencyCode: fromCurrency,
                      size: 24,
                    ),
                    Text(
                      ' = ',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      result.toStringAsFixed(2) + ' ',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    CurrencyFlagWidget(
                      currencyCode: toCurrency,
                      size: 24,
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CurrencyFlagWidget(
                currencyCode: fromCurrency,
                size: 18,
                showCode: false,
              ),
              const SizedBox(width: 4),
              Text(
                '1 $fromCurrency = ${unitRate > 0 ? unitRate.toStringAsFixed(4) : "?"} ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(204), // ~0.8 opacity
                ),
              ),
              CurrencyFlagWidget(
                currencyCode: toCurrency,
                size: 18,
                showCode: false,
              ),
              const SizedBox(width: 4),
              Text(
                toCurrency,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(204), // ~0.8 opacity
                ),
              ),
            ],
          ),
          
          if (updateInfo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              updateInfo,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withAlpha(150),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}