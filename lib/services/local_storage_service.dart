import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/session.dart';
import '../models/currency.dart';
import '../models/settings.dart';
import '../models/cart.dart';

class LocalStorageService {
  static const String _productsKey = 'milypico_products';
  static const String _sessionsKey = 'milypico_sessions';
  static const String _currenciesKey = 'milypico_currencies';
  static const String _settingsKey = 'milypico_settings';
  static const String _cartsKey = 'milypico_active_carts';

  static final List<Currency> defaultCurrencies = [
    Currency(code: 'CUP', name: 'Peso Cubano', symbol: '\$', rateToBase: 1.0),
    Currency(code: 'USD', name: 'Dólar Americano', symbol: 'US\$', rateToBase: 350.0),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', rateToBase: 360.0),
    Currency(code: 'MLC', name: 'Moneda Libremente Convertible', symbol: 'MLC', rateToBase: 310.0),
  ];

  static final List<Product> defaultProducts = [
    Product(
      id: 'prod-1',
      name: 'Café Expreso',
      emoji: '☕',
      unit: UnitType.u,
      prices: {PriceTier.normal: 120.0, PriceTier.mayorista: 100.0, PriceTier.oferta: 90.0},
      category: 'Bebidas',
      createdTime: 1690000000000,
    ),
    Product(
      id: 'prod-2',
      name: 'Sándwich Jamón y Queso',
      emoji: '🥪',
      unit: UnitType.u,
      prices: {PriceTier.normal: 450.0, PriceTier.mayorista: 400.0, PriceTier.oferta: 380.0},
      category: 'Gastronomía',
      createdTime: 1690000001000,
    ),
    Product(
      id: 'prod-3',
      name: 'Cerveza Cristal',
      emoji: '🍺',
      unit: UnitType.u,
      prices: {PriceTier.normal: 320.0, PriceTier.mayorista: 300.0},
      category: 'Bebidas',
      createdTime: 1690000002000,
    ),
    Product(
      id: 'prod-4',
      name: 'Agua Natural 500ml',
      emoji: '💧',
      unit: UnitType.u,
      prices: {PriceTier.normal: 180.0, PriceTier.mayorista: 150.0},
      category: 'Bebidas',
      createdTime: 1690000003000,
    ),
    Product(
      id: 'prod-5',
      name: 'Helado Artesanal',
      emoji: '🍨',
      unit: UnitType.u,
      prices: {PriceTier.normal: 250.0, PriceTier.oferta: 220.0},
      category: 'Postres',
      createdTime: 1690000004000,
    ),
    Product(
      id: 'prod-6',
      name: 'Queso Criollo (lb)',
      emoji: '🧀',
      unit: UnitType.lb,
      prices: {PriceTier.normal: 850.0, PriceTier.mayorista: 780.0},
      category: 'Víveres',
      createdTime: 1690000005000,
    ),
  ];

  Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_productsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      await saveProducts(defaultProducts);
      return defaultProducts;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return defaultProducts;
    }
  }

  Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(products.map((p) => p.toJson()).toList());
    await prefs.setString(_productsKey, jsonStr);
  }

  Future<List<Session>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_sessionsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Session.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(List<Session> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, jsonStr);
  }

  Future<List<Currency>> loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_currenciesKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      await saveCurrencies(defaultCurrencies);
      return defaultCurrencies;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Currency.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return defaultCurrencies;
    }
  }

  Future<void> saveCurrencies(List<Currency> currencies) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(currencies.map((c) => c.toJson()).toList());
    await prefs.setString(_currenciesKey, jsonStr);
  }

  Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_settingsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      final defaultSetting = Settings();
      await saveSettings(defaultSetting);
      return defaultSetting;
    }
    try {
      return Settings.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return Settings();
    }
  }

  Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<List<Cart>> loadCarts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cartsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [
        Cart(
          id: 'cart-${DateTime.now().millisecondsSinceEpoch}',
          number: 1,
          color: 'sky',
          items: [],
          createdTime: DateTime.now().millisecondsSinceEpoch,
        )
      ];
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Cart.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [
        Cart(
          id: 'cart-${DateTime.now().millisecondsSinceEpoch}',
          number: 1,
          color: 'sky',
          items: [],
          createdTime: DateTime.now().millisecondsSinceEpoch,
        )
      ];
    }
  }

  Future<void> saveCarts(List<Cart> carts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartsKey, jsonEncode(carts.map((c) => c.toJson()).toList()));
  }

  String generateSessionName(List<Session> existingSessions) {
    final now = DateTime.now();
    final formatted = DateFormat('d MMM', 'es_ES').format(now).replaceAll('.', '');
    
    // Capitalize words
    String name = formatted
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    final baseName = name;
    int suffix = 2;

    while (existingSessions.any((s) => s.name.toLowerCase() == name.toLowerCase() && s.isOpen)) {
      name = '$baseName ($suffix)';
      suffix++;
    }

    return name;
  }
}
