// lib/widgets/currency_selector.dart

import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../widgets/currency_flag_widget.dart';

class CurrencySelector extends StatelessWidget {
  final String value;
  final String label;
  final Function(String) onSelected;
  final List<String>? currencyList;

  const CurrencySelector({
    Key? key,
    required this.value,
    required this.label,
    required this.onSelected,
    this.currencyList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: () => _showCurrencySearch(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface.withAlpha(76), // ~0.3 opacity
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label, 
              style: TextStyle(
                fontSize: 12, 
                color: colorScheme.onSurfaceVariant.withAlpha(204) // ~0.8 opacity
              )
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Agregar bandera
                      CurrencyFlagWidget(
                        currencyCode: value,
                        size: 24,
                        showCode: false,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyData.currencyNames[value] ?? value,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCurrencySearch(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final currencies = currencyList ?? CurrencyData.popularCurrencies;
    
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        List<String> filteredCurrencies = List.from(currencies);
        
        return StatefulBuilder(
          builder: (context, setState) {
            // Filtrar las monedas según la búsqueda
            filteredCurrencies = currencies.where((currency) {
              final currencyCode = currency.toLowerCase();
              final currencyName = (CurrencyData.currencyNames[currency] ?? '').toLowerCase();
              final query = searchQuery.toLowerCase();
              return currencyCode.contains(query) || currencyName.contains(query);
            }).toList();
            
            return AlertDialog(
              title: Text('Selecciona moneda'),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Campo de búsqueda
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Buscar moneda...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Lista de monedas filtradas con banderas
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCurrencies.length,
                        itemBuilder: (context, index) {
                          final currency = filteredCurrencies[index];
                          final isSelected = currency == value;
                          
                          return ListTile(
                            leading: CurrencyFlagWidget(
                              currencyCode: currency,
                              size: 32,
                              showCode: false,
                            ),
                            title: Text(currency),
                            subtitle: Text(
                              CurrencyData.currencyNames[currency] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: isSelected,
                            selectedTileColor: colorScheme.primaryContainer,
                            onTap: () {
                              Navigator.pop(context, currency);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          }
        );
      },
    );
    
    if (selected != null) {
      onSelected(selected);
    }
  }
}

// Widget simplificado para la pantalla de gráficos
class SimpleCurrencySelector extends StatelessWidget {
  final String value;
  final Function(String) onSelected;
  final List<String> currencyList;

  const SimpleCurrencySelector({
    Key? key,
    required this.value,
    required this.onSelected,
    required this.currencyList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: () => _showSimpleSelector(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface.withAlpha(76),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Agregar bandera
            CurrencyFlagWidget(
              currencyCode: value,
              size: 20,
              showCode: false,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_drop_down, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _showSimpleSelector(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona moneda'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: currencyList.length,
              itemBuilder: (context, index) {
                final currency = currencyList[index];
                final isSelected = currency == value;
                
                return ListTile(
                  leading: CurrencyFlagWidget(
                    currencyCode: currency,
                    size: 32,
                    showCode: false,
                  ),
                  title: Text(currency),
                  subtitle: Text(
                    CurrencyData.currencyNames[currency] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isSelected,
                  selectedTileColor: colorScheme.primaryContainer,
                  onTap: () {
                    Navigator.pop(context, currency);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
    
    if (selected != null) {
      onSelected(selected);
    }
  }
}