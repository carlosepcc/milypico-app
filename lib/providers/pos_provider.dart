import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/session.dart';
import '../models/currency.dart';
import '../models/settings.dart';
import '../models/cart.dart';
import '../models/transaction.dart';
import '../models/backup.dart';
import '../services/local_storage_service.dart';
import '../services/backup_service.dart';

class POSProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final BackupService _backupService = BackupService();
  final Uuid _uuid = const Uuid();

  List<Product> _products = [];
  List<Session> _sessions = [];
  List<Currency> _currencies = [];
  Settings _settings = Settings();
  List<Cart> _activeCarts = [];
  int _activeCartIndex = 0;
  Session? _currentSession;
  bool _isLoading = true;

  // Selected product & POS filter
  String? _selectedProductId;
  String _selectedCategory = 'Todos';

  // Getters
  List<Product> get products => _products;
  List<Session> get sessions => _sessions;
  List<Currency> get currencies => _currencies;
  Settings get settings => _settings;
  List<Cart> get activeCarts => _activeCarts;
  int get activeCartIndex => _activeCartIndex;
  Session? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get selectedProductId => _selectedProductId;
  String get selectedCategory => _selectedCategory;

  Cart? get currentCart {
    if (_activeCarts.isEmpty) return null;
    if (_activeCartIndex >= _activeCarts.length) {
      _activeCartIndex = 0;
    }
    return _activeCarts[_activeCartIndex];
  }

  Map<String, Product> get productLookup {
    return {for (var p in _products) p.id: p};
  }

  List<String> get categories {
    final set = <String>{'Todos'};
    for (final p in _products) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    return set.toList();
  }

  POSProvider() {
    _init();
  }

  Future<void> _init() async {
    _products = await _storage.loadProducts();
    _sessions = await _storage.loadSessions();
    _currencies = await _storage.loadCurrencies();
    _settings = await _storage.loadSettings();
    _activeCarts = await _storage.loadCarts();

    // Check for open session
    try {
      _currentSession = _sessions.firstWhere((s) => s.isOpen);
    } catch (_) {
      _currentSession = null;
    }

    if (_products.isNotEmpty) {
      _selectedProductId = _products.first.id;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedProductId(String? id) {
    _selectedProductId = id;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void _triggerHaptic() {
    if (_settings.hapticFeedbackEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  // -------------------------------------------------------------
  // Session Actions
  // -------------------------------------------------------------
  Future<void> openSession() async {
    _triggerHaptic();
    final name = _storage.generateSessionName(_sessions);
    final newSession = Session(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      createdTime: DateTime.now().millisecondsSinceEpoch,
      status: 'open',
      transactions: [],
    );

    _sessions.insert(0, newSession);
    _currentSession = newSession;
    await _storage.saveSessions(_sessions);
    notifyListeners();
  }

  Future<void> closeSession() async {
    _triggerHaptic();
    if (_currentSession == null) return;

    final updated = _currentSession!.copyWith(
      status: 'closed',
      closedTime: DateTime.now().millisecondsSinceEpoch,
    );

    final idx = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (idx != -1) {
      _sessions[idx] = updated;
    }
    _currentSession = null;
    await _storage.saveSessions(_sessions);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Product Catalog Actions
  // -------------------------------------------------------------
  Future<void> addProduct(Product product) async {
    _products.insert(0, product);
    await _storage.saveProducts(_products);
    notifyListeners();
  }

  Future<void> updateProduct(Product updated) async {
    final idx = _products.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _products[idx] = updated;
      await _storage.saveProducts(_products);
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    if (_selectedProductId == id) {
      _selectedProductId = _products.isNotEmpty ? _products.first.id : null;
    }
    await _storage.saveProducts(_products);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Currencies Actions
  // -------------------------------------------------------------
  Future<void> updateCurrencyRate(String code, double rate) async {
    final idx = _currencies.indexWhere((c) => c.code == code);
    if (idx != -1) {
      _currencies[idx].rateToBase = rate;
      await _storage.saveCurrencies(_currencies);
      notifyListeners();
    }
  }

  Future<void> addCustomCurrency(Currency currency) async {
    _currencies.add(currency);
    await _storage.saveCurrencies(_currencies);
    notifyListeners();
  }

  Future<void> deleteCustomCurrency(String code) async {
    _currencies.removeWhere((c) => c.code == code && c.isCustom);
    await _storage.saveCurrencies(_currencies);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Settings Actions
  // -------------------------------------------------------------
  Future<void> updateSettings(Settings newSettings) async {
    _settings = newSettings;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Multi-Cart Actions
  // -------------------------------------------------------------
  void setActiveCartIndex(int index) {
    if (index >= 0 && index < _activeCarts.length) {
      _activeCartIndex = index;
      notifyListeners();
    }
  }

  static const List<String> _cartColors = ['sky', 'emerald', 'amber', 'rose', 'purple', 'indigo'];

  Future<void> createCart() async {
    _triggerHaptic();
    final nextNumber = _activeCarts.isEmpty
        ? 1
        : _activeCarts.map((c) => c.number).reduce((a, b) => a > b ? a : b) + 1;
    final color = _cartColors[(nextNumber - 1) % _cartColors.length];

    final newCart = Cart(
      id: 'cart-${DateTime.now().millisecondsSinceEpoch}',
      number: nextNumber,
      color: color,
      items: [],
      createdTime: DateTime.now().millisecondsSinceEpoch,
    );

    _activeCarts.add(newCart);
    _activeCartIndex = _activeCarts.length - 1;
    await _storage.saveCarts(_activeCarts);
    notifyListeners();
  }

  Future<void> deleteCart(String cartId) async {
    _triggerHaptic();
    if (_activeCarts.length <= 1) {
      // Clear items instead of removing last cart
      _activeCarts[0].items.clear();
      await _storage.saveCarts(_activeCarts);
      notifyListeners();
      return;
    }

    final idx = _activeCarts.indexWhere((c) => c.id == cartId);
    if (idx != -1) {
      _activeCarts.removeAt(idx);
      if (_activeCartIndex >= _activeCarts.length) {
        _activeCartIndex = _activeCarts.length - 1;
      }
      await _storage.saveCarts(_activeCarts);
      notifyListeners();
    }
  }

  Future<void> setProductQuantity(String cartId, String productId, double qty) async {
    final cart = _activeCarts.firstWhere((c) => c.id == cartId, orElse: () => _activeCarts[0]);
    final itemIndex = cart.items.indexWhere((i) => i.productId == productId);

    if (itemIndex != -1) {
      if (cart.items[itemIndex].isLocked) return;
      if (qty <= 0) {
        cart.items.removeAt(itemIndex);
      } else {
        cart.items[itemIndex].quantity = qty;
      }
    } else if (qty > 0) {
      cart.items.add(CartItem(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        quantity: qty,
        selectedTier: PriceTier.normal,
      ));
    }

    await _storage.saveCarts(_activeCarts);
    notifyListeners();
  }

  Future<void> addItemToCart(String cartId, String productId) async {
    _triggerHaptic();
    final cart = _activeCarts.firstWhere((c) => c.id == cartId, orElse: () => _activeCarts[0]);
    final itemIndex = cart.items.indexWhere((i) => i.productId == productId);

    if (itemIndex != -1) {
      if (cart.items[itemIndex].isLocked) return;
      cart.items[itemIndex].quantity += 1.0;
    } else {
      cart.items.add(CartItem(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        quantity: 1.0,
        selectedTier: PriceTier.normal,
      ));
    }

    _selectedProductId = productId;
    await _storage.saveCarts(_activeCarts);
    notifyListeners();
  }

  Future<void> updateCartItemTier(String cartId, String itemId, PriceTier tier, {double? customPrice}) async {
    final cart = _activeCarts.firstWhere((c) => c.id == cartId);
    final item = cart.items.firstWhere((i) => i.id == itemId);
    item.selectedTier = tier;
    if (customPrice != null) {
      item.customPrice = customPrice;
    }
    await _storage.saveCarts(_activeCarts);
    notifyListeners();
  }

  Future<void> toggleCartItemLock(String cartId, String itemId) async {
    _triggerHaptic();
    final cart = _activeCarts.firstWhere((c) => c.id == cartId);
    final item = cart.items.firstWhere((i) => i.id == itemId);
    item.isLocked = !item.isLocked;
    await _storage.saveCarts(_activeCarts);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Checkout & Sale Transaction
  // -------------------------------------------------------------
  Future<Transaction?> checkoutCart(String cartId, String paymentCurrencyCode) async {
    _triggerHaptic();
    final cart = _activeCarts.firstWhere((c) => c.id == cartId);
    if (cart.items.isEmpty) return null;

    final lookup = productLookup;
    final double totalCUP = cart.calculateTotal(lookup);

    // Find currency rate
    final currency = _currencies.firstWhere(
      (c) => c.code == paymentCurrencyCode,
      orElse: () => _currencies.first,
    );
    final double rate = currency.rateToBase;
    final double paymentAmount = rate > 0 ? (totalCUP / rate) : totalCUP;

    final txItems = <TransactionItem>[];
    for (final item in cart.items) {
      final p = lookup[item.productId];
      if (p != null) {
        final price = p.getPriceForTier(item.selectedTier, fallbackCustom: item.customPrice);
        txItems.add(TransactionItem(
          name: p.name,
          emoji: p.emoji,
          quantity: item.quantity,
          unit: p.unit,
          price: price,
          subtotal: price * item.quantity,
        ));
      }
    }

    // Auto-open session if none exists
    if (_currentSession == null) {
      await openSession();
    }

    final transaction = Transaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      sessionName: _currentSession!.name,
      cartNumber: cart.number,
      items: txItems,
      totalCUP: totalCUP,
      paymentCurrency: currency.code,
      paymentAmount: paymentAmount,
      exchangeRateUsed: rate,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _currentSession!.transactions.insert(0, transaction);
    await _storage.saveSessions(_sessions);

    // Clear cart items
    cart.items.clear();
    await _storage.saveCarts(_activeCarts);
    notifyListeners();

    return transaction;
  }

  // -------------------------------------------------------------
  // Backup Export & Import
  // -------------------------------------------------------------
  String exportBackupJson() {
    return _backupService.generateBackupJson(
      products: _products,
      sessions: _sessions,
      currencies: _currencies,
      settings: _settings,
    );
  }

  Future<bool> restoreBackupJson(String jsonString) async {
    final backup = _backupService.parseBackupJson(jsonString);
    if (backup == null) return false;

    _products = backup.products;
    _sessions = backup.sessions;
    _currencies = backup.currencies;
    _settings = backup.settings;

    try {
      _currentSession = _sessions.firstWhere((s) => s.isOpen);
    } catch (_) {
      _currentSession = null;
    }

    await _storage.saveProducts(_products);
    await _storage.saveSessions(_sessions);
    await _storage.saveCurrencies(_currencies);
    await _storage.saveSettings(_settings);

    notifyListeners();
    return true;
  }
}
