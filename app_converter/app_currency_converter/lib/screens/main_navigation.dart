import 'package:flutter/material.dart';

import '../services/exchange_service.dart';
import 'charts_screen.dart';
import 'converter_screen.dart';

// Página principal con navegación inferior mejorada
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  final ExchangeService _exchangeService = ExchangeService();
  
  // Lista de páginas a mostrar con clave global para mantener estado
  late final List<Widget> _pages;
  
  // Inicializar para preservar estado
  @override
  void initState() {
    super.initState();
    
    // Configurar el servicio para reducir actualizaciones automáticas
    _exchangeService.setUpdateMode(true); // Solo actualización manual
    
    // Usar PageStorage para preservar el estado de las páginas
    final converterKey = PageStorageKey('converter_page');
    final chartsKey = PageStorageKey('charts_page');
    
    _pages = [
      CurrencyConverterPage(key: converterKey),
      CurrencyChartsPage(key: chartsKey),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      // Usar IndexedStack para preservar el estado de las páginas
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.currency_exchange),
            label: 'Convertir',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up),
            label: 'Gráficos',
          ),
        ],
      ),
    );
  }
}