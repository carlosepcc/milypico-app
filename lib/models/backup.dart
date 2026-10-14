import 'product.dart';
import 'session.dart';
import 'currency.dart';
import 'settings.dart';

class POSDataBackup {
  final String version;
  final int timestamp;
  final List<Product> products;
  final List<Session> sessions;
  final List<Currency> currencies;
  final Settings settings;

  POSDataBackup({
    required this.version,
    required this.timestamp,
    required this.products,
    required this.sessions,
    required this.currencies,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'timestamp': timestamp,
      'products': products.map((p) => p.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'currencies': currencies.map((c) => c.toJson()).toList(),
      'settings': settings.toJson(),
    };
  }

  factory POSDataBackup.fromJson(Map<String, dynamic> json) {
    return POSDataBackup(
      version: json['version'] as String? ?? '1.0.0',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      products: (json['products'] as List<dynamic>? ?? [])
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList(),
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((s) => Session.fromJson(s as Map<String, dynamic>))
          .toList(),
      currencies: (json['currencies'] as List<dynamic>? ?? [])
          .map((c) => Currency.fromJson(c as Map<String, dynamic>))
          .toList(),
      settings: json['settings'] != null
          ? Settings.fromJson(json['settings'] as Map<String, dynamic>)
          : Settings(),
    );
  }
}
