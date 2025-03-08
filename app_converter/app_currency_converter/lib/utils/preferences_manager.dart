import 'package:shared_preferences/shared_preferences.dart';

// Gestor de preferencias de usuario
class PreferencesManager {
  // Singleton pattern
  static final PreferencesManager _instance = PreferencesManager._internal();
  factory PreferencesManager() => _instance;
  PreferencesManager._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Inicializar preferencias
  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Moneda de origen predeterminada
  Future<String> getFromCurrency() async {
    await init();
    return _prefs.getString('fromCurrency') ?? 'USD';
  }

  Future<void> setFromCurrency(String currency) async {
    await init();
    await _prefs.setString('fromCurrency', currency);
  }

  // Moneda de destino predeterminada
  Future<String> getToCurrency() async {
    await init();
    return _prefs.getString('toCurrency') ?? 'EUR';
  }

  Future<void> setToCurrency(String currency) async {
    await init();
    await _prefs.setString('toCurrency', currency);
  }

  // Favoritos
  Future<List<String>> getFavorites() async {
    await init();
    return _prefs.getStringList('favorites') ?? [];
  }

  Future<void> setFavorites(List<String> favorites) async {
    await init();
    await _prefs.setStringList('favorites', favorites);
  }

  Future<void> addFavorite(String fromCurrency, String toCurrency) async {
    await init();
    final favorites = await getFavorites();
    final pair = '$fromCurrency/$toCurrency';
    if (!favorites.contains(pair)) {
      favorites.add(pair);
      await setFavorites(favorites);
    }
  }

  Future<void> removeFavorite(String fromCurrency, String toCurrency) async {
    await init();
    final favorites = await getFavorites();
    final pair = '$fromCurrency/$toCurrency';
    favorites.remove(pair);
    await setFavorites(favorites);
  }

  Future<bool> isFavorite(String fromCurrency, String toCurrency) async {
    await init();
    final favorites = await getFavorites();
    final pair = '$fromCurrency/$toCurrency';
    return favorites.contains(pair);
  }

  Future<void> clearFavorites() async {
    await init();
    await setFavorites([]);
  }

  // Historial de conversiones recientes
  Future<List<String>> getRecentConversions() async {
    await init();
    return _prefs.getStringList('recentConversions') ?? [];
  }

  Future<void> setRecentConversions(List<String> conversions) async {
    await init();
    await _prefs.setStringList('recentConversions', conversions);
  }

  Future<void> addRecentConversion(String fromCurrency, String toCurrency) async {
    await init();
    final recent = await getRecentConversions();
    final conversion = '$fromCurrency to $toCurrency';
    
    // Eliminar si ya existe y añadir al principio
    recent.remove(conversion);
    recent.insert(0, conversion);
    
    // Mantener solo las 10 más recientes
    if (recent.length > 10) {
      recent.length = 10;
    }
    
    await setRecentConversions(recent);
  }

  Future<void> clearRecentConversions() async {
    await init();
    await setRecentConversions([]);
  }
}