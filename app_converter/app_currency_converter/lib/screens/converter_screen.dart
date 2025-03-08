import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/currency.dart';
import '../services/exchange_service.dart';
import '../utils/preferences_manager.dart';

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _amountController = TextEditingController(
    text: "1",
  );
  final ExchangeService _exchangeService = ExchangeService();
  final PreferencesManager _prefsManager = PreferencesManager();

  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _result = 0.0;
  bool _isLoading = false;
  List<String> _favorites = [];
  List<String> _recentConversions = [];
  List<String> _availableCurrencies = CurrencyData.popularCurrencies;
  bool _loadingCurrencies = true;
  String _lastConversionParams = '';

  @override
  void initState() {
    super.initState();

    if (_availableCurrencies.length <= CurrencyData.popularCurrencies.length) {
      _loadData();
    } else {
      _loadPreferences().then((_) {
        if (_result == 0.0 && mounted) {
          _convertCurrency();
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
    await _convertCurrency();

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
    final favorites = await _prefsManager.getFavorites();
    final recentConversions = await _prefsManager.getRecentConversions();

    setState(() {
      _fromCurrency = fromCurrency;
      _toCurrency = toCurrency;
      _favorites = favorites;
      _recentConversions = recentConversions;
    });
  }

  // Cargar monedas disponibles
  Future<void> _loadAvailableCurrencies() async {
    if (_availableCurrencies.length > CurrencyData.popularCurrencies.length) {
      return;
    }

    try {
      final currencies = await _exchangeService.getAvailableCurrencies();
      if (mounted && currencies.isNotEmpty) {
        setState(() {
          _availableCurrencies = currencies;
        });
      }
    } catch (e) {
      debugPrint('Error cargando monedas: $e');
    }
  }

  // Función para convertir divisas
  Future<void> _convertCurrency() async {
    if (_amountController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa una cantidad')),
        );
      }
      return;
    }

    // Validar que la cantidad sea un número válido
    double amount;
    try {
      amount = double.parse(_amountController.text.replaceAll(',', '.'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor ingresa una cantidad válida'),
          ),
        );
      }
      return;
    }

    // Verificar si necesitamos convertir
    final currentParams = '${amount}_${_fromCurrency}_${_toCurrency}';
    if (_lastConversionParams == currentParams && _result > 0 && !_isLoading) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _lastConversionParams = currentParams;
      });
    }

    try {
      // Realizar la conversión usando el servicio
      final result = await _exchangeService.convertCurrency(
        amount,
        _fromCurrency,
        _toCurrency,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _isLoading = false;
      });

      // Actualizar conversiones recientes
      await _prefsManager.addRecentConversion(_fromCurrency, _toCurrency);
      if (mounted) {
        final recentConversions = await _prefsManager.getRecentConversions();
        setState(() {
          _recentConversions = recentConversions;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  // Agregar o quitar de favoritos
  Future<void> _toggleFavorite() async {
    final isFav = await _prefsManager.isFavorite(_fromCurrency, _toCurrency);

    if (isFav) {
      await _prefsManager.removeFavorite(_fromCurrency, _toCurrency);
    } else {
      await _prefsManager.addFavorite(_fromCurrency, _toCurrency);
    }

    if (mounted) {
      final favorites = await _prefsManager.getFavorites();
      setState(() {
        _favorites = favorites;
      });
    }
  }

  // Cambiar monedas de origen y destino
  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;

      _prefsManager.setFromCurrency(_fromCurrency);
      _prefsManager.setToCurrency(_toCurrency);

      if (_amountController.text.isNotEmpty) {
        _convertCurrency();
      }
    });
  }

  // Cuando se selecciona una moneda de origen
  void _onFromCurrencySelected(String currency) {
    if (currency == _fromCurrency) return;

    setState(() {
      _fromCurrency = currency;
      _prefsManager.setFromCurrency(currency);

      if (_amountController.text.isNotEmpty) {
        _convertCurrency();
      }
    });
  }

  // Cuando se selecciona una moneda de destino
  void _onToCurrencySelected(String currency) {
    if (currency == _toCurrency) return;

    setState(() {
      _toCurrency = currency;
      _prefsManager.setToCurrency(currency);

      if (_amountController.text.isNotEmpty) {
        _convertCurrency();
      }
    });
  }

  // Mostrar diálogo de conversiones recientes
  void _showRecentConversions() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                const Text('Conversiones recientes'),
              ],
            ),
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  _recentConversions.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_toggle_off,
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              ),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text('No hay conversiones recientes'),
                          ],
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _recentConversions.length,
                        itemBuilder: (context, index) {
                          final parts = _recentConversions[index].split(' to ');
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  parts[0][0],
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                parts.join(' → '),
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Pulse para convertir',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _fromCurrency = parts[0];
                                  _toCurrency = parts[1];

                                  _prefsManager.setFromCurrency(_fromCurrency);
                                  _prefsManager.setToCurrency(_toCurrency);

                                  if (_amountController.text.isNotEmpty) {
                                    _convertCurrency();
                                  }
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  // Mostrar todos los favoritos en un diálogo
  void _showFavoritesDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 10),
                    const Text('Conversiones favoritas'),
                  ],
                ),
                backgroundColor: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child:
                      _favorites.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_border,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                const Text('No hay conversiones favoritas'),
                                const SizedBox(height: 8),
                                Text(
                                  'Agrega tus pares favoritos con ⭐',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _favorites.length,
                            itemBuilder: (context, index) {
                              final parts = _favorites[index].split('/');
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.withOpacity(
                                      0.2,
                                    ),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    parts.join(' → '),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  subtitle: FutureBuilder<double>(
                                    future: _exchangeService.convertCurrency(
                                      1,
                                      parts[0],
                                      parts[1],
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Text(
                                          '1 ${parts[0]} = ${snapshot.data!.toStringAsFixed(4)} ${parts[1]}',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        );
                                      } else {
                                        return Text(
                                          'Cargando...',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: colorScheme.error,
                                    ),
                                    onPressed: () async {
                                      await _prefsManager.removeFavorite(
                                        parts[0],
                                        parts[1],
                                      );

                                      // Actualizar tanto el diálogo como la pantalla principal
                                      final updatedFavorites =
                                          await _prefsManager.getFavorites();

                                      // Actualizar el estado del diálogo
                                      setDialogState(() {
                                        // Actualizar la lista local usada por el diálogo
                                        _favorites = updatedFavorites;
                                      });

                                      // Actualizar también el estado de la pantalla principal
                                      if (mounted) {
                                        setState(() {
                                          // Asegurar que la pantalla principal tenga la misma lista actualizada
                                          _favorites = updatedFavorites;
                                        });
                                      }

                                      // Cerrar el diálogo si ya no hay favoritos
                                      if (_favorites.isEmpty &&
                                          Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _fromCurrency = parts[0];
                                      _toCurrency = parts[1];

                                      _prefsManager.setFromCurrency(
                                        _fromCurrency,
                                      );
                                      _prefsManager.setToCurrency(_toCurrency);

                                      if (_amountController.text.isNotEmpty) {
                                        _convertCurrency();
                                      }
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cerrar',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Mostrar configuración
  void _showSettings() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.settings, color: colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                const Text('Configuración'),
              ],
            ),
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    'Borrar favoritos',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.errorContainer,
                    child: Icon(
                      Icons.delete,
                      color: colorScheme.error,
                      size: 20,
                    ),
                  ),
                  onTap: () async {
                    await _prefsManager.clearFavorites();
                    if (!context.mounted) return;

                    setState(() {
                      _favorites = [];
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Favoritos borrados')),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  // Remover un favorito de la lista
  Future<void> _removeFavorite(String fromCurrency, String toCurrency) async {
    await _prefsManager.removeFavorite(fromCurrency, toCurrency);

    // Obtener la lista actualizada de favoritos
    final updatedFavorites = await _prefsManager.getFavorites();

    if (mounted) {
      setState(() {
        // Actualizar la lista de favoritos en la pantalla principal
        _favorites = updatedFavorites;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para el AutomaticKeepAliveClientMixin

    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;
    bool isFavorite = _favorites.contains('$_fromCurrency/$_toCurrency');
    String updateInfo = _exchangeService.getUpdateTimeInfo();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Convertidor de Divisas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : colorScheme.onSurfaceVariant,
            ),
            onPressed: _toggleFavorite,
            tooltip: isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
          ),
          IconButton(
            icon: Icon(Icons.history, color: colorScheme.onSurfaceVariant),
            onPressed: _showRecentConversions,
            tooltip: 'Conversiones recientes',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
            onPressed: _showSettings,
            tooltip: 'Configuración',
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
              : Container(
                decoration: BoxDecoration(
                  gradient:
                      isDarkMode
                          ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.surface,
                              colorScheme.surface.withOpacity(0.8),
                            ],
                          )
                          : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.primaryContainer.withOpacity(0.2),
                              colorScheme.surface,
                            ],
                          ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tarjeta de conversión principal
                          Card(
                            elevation: 4,
                            shadowColor: colorScheme.shadow.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Conversor',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ingresa la cantidad y selecciona las monedas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Campo de entrada de cantidad mejorado
                                  TextField(
                                    controller: _amountController,
                                    decoration: InputDecoration(
                                      labelText: 'Cantidad',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline,
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.attach_money,
                                        color: colorScheme.primary,
                                      ),
                                      hintText:
                                          'Ingresa la cantidad a convertir',
                                      filled: true,
                                      fillColor:
                                          isDarkMode
                                              ? colorScheme.surfaceVariant
                                                  .withOpacity(0.3)
                                              : colorScheme.surfaceVariant
                                                  .withOpacity(0.1),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    onChanged: (_) {
                                      if (_amountController.text.isNotEmpty) {
                                        _convertCurrency();
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Selección de monedas con diseño mejorado
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'De:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            InkWell(
                                              onTap:
                                                  () => showCurrencySelector(
                                                    context,
                                                    _fromCurrency,
                                                    _onFromCurrencySelected,
                                                    _availableCurrencies,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: colorScheme.outline
                                                        .withOpacity(0.5),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color:
                                                      isDarkMode
                                                          ? colorScheme
                                                              .surfaceVariant
                                                              .withOpacity(0.3)
                                                          : colorScheme
                                                              .surfaceVariant
                                                              .withOpacity(0.1),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 14,
                                                      backgroundColor:
                                                          colorScheme
                                                              .primaryContainer,
                                                      child: Text(
                                                        _fromCurrency[0],
                                                        style: TextStyle(
                                                          color:
                                                              colorScheme
                                                                  .primary,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            _fromCurrency,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color:
                                                                  colorScheme
                                                                      .onSurface,
                                                            ),
                                                          ),
                                                          Text(
                                                            CurrencyData
                                                                    .currencyNames[_fromCurrency] ??
                                                                '',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  colorScheme
                                                                      .onSurfaceVariant,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.arrow_drop_down,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Botón de intercambio mejorado
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Material(
                                          color: colorScheme.primaryContainer
                                              .withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: InkWell(
                                            onTap: _swapCurrencies,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              child: Icon(
                                                Icons.swap_horiz,
                                                color: colorScheme.primary,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'A:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            InkWell(
                                              onTap:
                                                  () => showCurrencySelector(
                                                    context,
                                                    _toCurrency,
                                                    _onToCurrencySelected,
                                                    _availableCurrencies,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: colorScheme.outline
                                                        .withOpacity(0.5),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color:
                                                      isDarkMode
                                                          ? colorScheme
                                                              .surfaceVariant
                                                              .withOpacity(0.3)
                                                          : colorScheme
                                                              .surfaceVariant
                                                              .withOpacity(0.1),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 14,
                                                      backgroundColor:
                                                          colorScheme
                                                              .primaryContainer,
                                                      child: Text(
                                                        _toCurrency[0],
                                                        style: TextStyle(
                                                          color:
                                                              colorScheme
                                                                  .primary,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            _toCurrency,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color:
                                                                  colorScheme
                                                                      .onSurface,
                                                            ),
                                                          ),
                                                          Text(
                                                            CurrencyData
                                                                    .currencyNames[_toCurrency] ??
                                                                '',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  colorScheme
                                                                      .onSurfaceVariant,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.arrow_drop_down,
                                                      color:
                                                          colorScheme.primary,
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
                          ),

                          const SizedBox(height: 24),

                          // Resultado de conversión con nuevo diseño
                          Card(
                            elevation: 4,
                            shadowColor: colorScheme.shadow.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            color: colorScheme.primaryContainer.withOpacity(
                              0.7,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.currency_exchange,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Resultado',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _isLoading
                                      ? CircularProgressIndicator(
                                        color: colorScheme.primary,
                                      )
                                      : Column(
                                        children: [
                                          Text(
                                            '${_amountController.text.isEmpty ? "0" : _amountController.text} $_fromCurrency =',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_result.toStringAsFixed(2)} $_toCurrency',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  colorScheme
                                                      .onPrimaryContainer,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface
                                                  .withOpacity(0.8),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '1 $_fromCurrency = ${(_result / double.parse(_amountController.text.isEmpty ? "1" : _amountController.text.replaceAll(',', '.'))).toStringAsFixed(4)} $_toCurrency',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  if (updateInfo.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: colorScheme.onSurfaceVariant
                                              .withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          updateInfo,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: colorScheme.onSurfaceVariant
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Sección de favoritos mejorada
                          if (_favorites.isNotEmpty) ...[
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Favoritos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _showFavoritesDialog,
                                  icon: const Icon(Icons.more_horiz),
                                  label: const Text('Ver todos'),
                                  style: TextButton.styleFrom(
                                    backgroundColor: colorScheme.surfaceVariant
                                        .withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Mostrar los favoritos en tarjetas mejoradas
                            for (
                              int i = 0;
                              i <
                                  (_favorites.length > 2
                                      ? 2
                                      : _favorites.length);
                              i++
                            )
                              _buildFavoriteCard(i, colorScheme, isDarkMode),

                            if (_favorites.length > 2)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: _showFavoritesDialog,
                                  child: Text(
                                    'Ver ${_favorites.length - 2} más...',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildFavoriteCard(
    int index,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    final parts = _favorites[index].split('/');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color:
          isDarkMode
              ? colorScheme.surfaceVariant.withOpacity(0.3)
              : colorScheme.surface,
      child: InkWell(
        onTap: () {
          setState(() {
            _fromCurrency = parts[0];
            _toCurrency = parts[1];
            _prefsManager.setFromCurrency(_fromCurrency);
            _prefsManager.setToCurrency(_toCurrency);
            if (_amountController.text.isNotEmpty) {
              _convertCurrency();
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          parts[0],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          parts[1],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<double>(
                      future: _exchangeService.convertCurrency(
                        1,
                        parts[0],
                        parts[1],
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            '1 ${parts[0]} = ${snapshot.data!.toStringAsFixed(4)} ${parts[1]}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        } else {
                          return Text(
                            'Cargando...',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                onPressed: () => _removeFavorite(parts[0], parts[1]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para mostrar el selector de moneda mejorado
  Future<void> showCurrencySelector(
    BuildContext context,
    String currentValue,
    Function(String) onSelected,
    List<String> currencyList,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        String searchQuery = '';
        List<String> filteredCurrencies = List.from(currencyList);

        return StatefulBuilder(
          builder: (context, setState) {
            // Filtrar las monedas según la búsqueda
            filteredCurrencies =
                currencyList.where((currency) {
                  final currencyCode = currency.toLowerCase();
                  final currencyName =
                      (CurrencyData.currencyNames[currency] ?? '')
                          .toLowerCase();
                  final query = searchQuery.toLowerCase();
                  return currencyCode.contains(query) ||
                      currencyName.contains(query);
                }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Barra de título
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? colorScheme.surfaceVariant.withOpacity(0.3)
                              : colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.currency_exchange,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Selecciona moneda',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Campo de búsqueda
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode
                                ? colorScheme.surfaceVariant.withOpacity(0.3)
                                : colorScheme.surfaceVariant.withOpacity(0.1),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),

                  // Lista de monedas filtradas
                  Expanded(
                    child:
                        filteredCurrencies.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.currency_exchange,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No se encontraron monedas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: filteredCurrencies.length,
                              itemBuilder: (context, index) {
                                final currency = filteredCurrencies[index];
                                final isSelected = currency == currentValue;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  color:
                                      isSelected
                                          ? colorScheme.primaryContainer
                                          : null,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          isSelected
                                              ? colorScheme.primary.withOpacity(
                                                0.3,
                                              )
                                              : colorScheme.surfaceVariant,
                                      child: Text(
                                        currency[0],
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      currency,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isSelected
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      CurrencyData.currencyNames[currency] ??
                                          '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? colorScheme.primary
                                                    .withOpacity(0.7)
                                                : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing:
                                        isSelected
                                            ? Icon(
                                              Icons.check_circle,
                                              color: colorScheme.primary,
                                            )
                                            : null,
                                    onTap: () {
                                      Navigator.pop(context, currency);
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
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
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; // Mantener el estado cuando se cambia de tab
}
