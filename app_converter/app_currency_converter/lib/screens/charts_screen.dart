import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../services/exchange_service.dart';
import '../utils/preferences_manager.dart';
import '../widgets/chart_widget.dart';

// Página de Gráficos mejorada
class CurrencyChartsPage extends StatefulWidget {
  const CurrencyChartsPage({super.key});

  @override
  State<CurrencyChartsPage> createState() => _CurrencyChartsPageState();
}

class _CurrencyChartsPageState extends State<CurrencyChartsPage> with AutomaticKeepAliveClientMixin {
  final PreferencesManager _prefsManager = PreferencesManager();
  final ExchangeService _exchangeService = ExchangeService();

  String _baseCurrency = 'USD';
  String _targetCurrency = 'EUR';
  bool _isLoading = false;
  bool _loadingCurrencies = true;
  Map<String, double> _historicalRates = {};
  List<String> _timeLabels = [];
  List<String> _availableCurrencies = [];
  String _dataSource = 'Datos reales'; // Para mostrar el origen de los datos
  String _currentPair = ''; // Para rastrear la combinación actual de monedas

  @override
  void initState() {
    super.initState();
    
    // Verificar si los datos ya están cargados antes de hacer la carga completa
    if (_availableCurrencies.isEmpty) {
      _loadData();
    } else {
      // Si ya hay datos, solo cargar las preferencias
      _loadPreferences().then((_) {
        if (_historicalRates.isEmpty && mounted) {
          _fetchHistoricalData();
        }
      });
    }
  }

  // Cargar datos iniciales
  Future<void> _loadData() async {
    setState(() {
      _loadingCurrencies = true;
    });

    await _loadPreferences();
    await _loadAvailableCurrencies();
    await _fetchHistoricalData();

    if (mounted) {
      setState(() {
        _loadingCurrencies = false;
      });
    }
  }

  // Cargar preferencias guardadas
  Future<void> _loadPreferences() async {
    if (!mounted) return;

    final fromCurrency = await _prefsManager.getFromCurrency();
    final toCurrency = await _prefsManager.getToCurrency();

    setState(() {
      _baseCurrency = fromCurrency;
      _targetCurrency = toCurrency;
    });
  }

  // Cargar monedas disponibles
  Future<void> _loadAvailableCurrencies() async {
    // Si ya tenemos monedas disponibles, no recargar
    if (_availableCurrencies.isNotEmpty) {
      return;
    }
    
    try {
      final currencies = await _exchangeService.getAvailableCurrencies();
      if (mounted && currencies.isNotEmpty) {
        setState(() {
          _availableCurrencies = currencies;
        });
      } else {
        setState(() {
          _availableCurrencies = CurrencyData.chartCurrencies;
        });
      }
    } catch (e) {
      setState(() {
        _availableCurrencies = CurrencyData.chartCurrencies;
      });
      print('Error cargando monedas: $e');
    }
  }

  // Obtener datos históricos
  Future<void> _fetchHistoricalData() async {
    if (!mounted) return;

    // Si ya tenemos datos y es la misma combinación de monedas, no actualizar
    final newPair = '${_baseCurrency}_${_targetCurrency}';
    if (_historicalRates.isNotEmpty && _currentPair == newPair && !_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _currentPair = newPair;
    });

    try {
      // Obtener datos históricos del servicio
      final historicalData = await _exchangeService.getHistoricalRates(
        _baseCurrency,
        _targetCurrency,
      );

      if (!mounted) return;

      if (historicalData.isNotEmpty) {
        // Ordenar las fechas cronológicamente
        final sortedDates =
            historicalData.keys.toList()..sort((a, b) {
              final partsA = a.split('/').map(int.parse).toList();
              final partsB = b.split('/').map(int.parse).toList();

              // Comparar mes primero, luego día
              final dateA = DateTime(2025, partsA[1], partsA[0]);
              final dateB = DateTime(2025, partsB[1], partsB[0]);
              return dateA.compareTo(dateB);
            });

        setState(() {
          _timeLabels = sortedDates;
          _historicalRates = historicalData;
          _isLoading = false;
          _dataSource = 'Datos reales de los últimos 7 días';
        });
      } else {
        throw Exception('No se obtuvieron datos históricos');
      }
    } catch (e) {
      print('Error al obtener datos históricos: $e');

      if (mounted) {
        setState(() {
          _dataSource = 'Datos simulados (servicio no disponible)';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudieron obtener datos históricos reales. Mostrando simulación.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Cambiar la moneda base
  void _onBaseCurrencySelected(String currency) {
    if (currency == _baseCurrency) return; // No hacer nada si es la misma moneda
    
    setState(() {
      _baseCurrency = currency;
      _prefsManager.setFromCurrency(currency);
    });
    _fetchHistoricalData();
  }

  // Cambiar la moneda objetivo
  void _onTargetCurrencySelected(String currency) {
    if (currency == _targetCurrency) return; // No hacer nada si es la misma moneda
    
    setState(() {
      _targetCurrency = currency;
      _prefsManager.setToCurrency(currency);
    });
    _fetchHistoricalData();
  }

  // Mostrar selector de moneda con búsqueda y nombres completos
  Future<void> _showEnhancedCurrencySearch(
    BuildContext context,
    String currentValue,
    Function(String) onSelected,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        List<String> filteredCurrencies = List.from(_availableCurrencies);

        return StatefulBuilder(
          builder: (context, setState) {
            // Filtrar las monedas según la búsqueda (código o nombre)
            filteredCurrencies =
                _availableCurrencies.where((currency) {
                  final currencyCode = currency.toLowerCase();
                  final currencyName =
                      (CurrencyData.currencyNames[currency] ?? '')
                          .toLowerCase();
                  final query = searchQuery.toLowerCase();
                  return currencyCode.contains(query) ||
                      currencyName.contains(query);
                }).toList();

            return AlertDialog(
              title: Text('Selecciona moneda'),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Campo de búsqueda mejorado
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Buscar por código o nombre...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                                : null,
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

                    // Lista de monedas filtradas
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCurrencies.length,
                        itemBuilder: (context, index) {
                          final currency = filteredCurrencies[index];
                          final isSelected = currency == currentValue;

                          return ListTile(
                            title: Row(
                              children: [
                                Text(
                                  currency,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    CurrencyData.currencyNames[currency] ?? '',
                                    style: TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedTileColor: colorScheme.primaryContainer
                                .withOpacity(0.4),
                            leading:
                                isSelected
                                    ? Icon(
                                      Icons.check_circle,
                                      color: colorScheme.primary,
                                    )
                                    : null,
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
          },
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para el AutomaticKeepAliveClientMixin
    
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gráficos de Cambio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Añadimos un IconButton para actualizar que aparece junto con la acción
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            tooltip: 'Actualizar datos',
            onPressed: () {
              _exchangeService.clearCache();
              _fetchHistoricalData();
            },
          ),
        ],
      ),
      body:
          _loadingCurrencies
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando monedas disponibles...',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título y explicación
                    Text(
                      'Tendencia de Cambio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visualiza la evolución del tipo de cambio durante los últimos 7 días',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selección de monedas mejorada
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? colorScheme.surface.withOpacity(0.6)
                                : colorScheme.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Selecciona las monedas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'De:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap:
                                          () => _showEnhancedCurrencySearch(
                                            context,
                                            _baseCurrency,
                                            _onBaseCurrencySelected,
                                          ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: colorScheme.outline
                                                .withOpacity(0.3),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: colorScheme.surface
                                              .withOpacity(0.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              _baseCurrency,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                CurrencyData
                                                        .currencyNames[_baseCurrency] ??
                                                    '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.trending_up,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'A:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap:
                                          () => _showEnhancedCurrencySearch(
                                            context,
                                            _targetCurrency,
                                            _onTargetCurrencySelected,
                                          ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: colorScheme.outline
                                                .withOpacity(0.3),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: colorScheme.surface
                                              .withOpacity(0.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              _targetCurrency,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                CurrencyData
                                                        .currencyNames[_targetCurrency] ??
                                                    '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Gráfico de cambio mejorado
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? colorScheme.surfaceVariant.withOpacity(0.3)
                                  : colorScheme.surfaceVariant.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              spreadRadius: 1,
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Título con estilo mejorado
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? colorScheme.surface.withOpacity(0.4)
                                        : colorScheme.surface.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.1),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_baseCurrency',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    ' → ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '$_targetCurrency',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '- Última semana',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: HistoricalRatesChart(
                                ratesByDate: _historicalRates,
                                timeLabels: _timeLabels,
                                isLoading: _isLoading,
                                lineColor: colorScheme.primary,
                                pointColor:
                                    isDarkMode
                                        ? colorScheme.primaryContainer
                                        : colorScheme.primaryContainer,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Información adicional con mejor diseño
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? colorScheme.surface.withOpacity(0.3)
                                        : colorScheme.surface.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Origen de los datos en una fila separada
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _dataSource,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: colorScheme.onSurfaceVariant
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Valores mínimos y máximos en una fila separada
                                  if (_historicalRates.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.error
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Min: ${_getMinRate().toStringAsFixed(4)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.error,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Max: ${_getMaxRate().toStringAsFixed(4)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Obtener la tasa mínima para mostrar en la gráfica
  double _getMinRate() {
    if (_historicalRates.isEmpty) return 0.0;
    return _historicalRates.values.reduce((a, b) => a < b ? a : b);
  }

  // Obtener la tasa máxima para mostrar en la gráfica
  double _getMaxRate() {
    if (_historicalRates.isEmpty) return 0.0;
    return _historicalRates.values.reduce((a, b) => a > b ? a : b);
  }
  
  @override
  bool get wantKeepAlive => true; // Mantener el estado cuando se cambia de tab
}