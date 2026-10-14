import 'dart:convert';
import '../models/backup.dart';
import '../models/product.dart';
import '../models/session.dart';
import '../models/currency.dart';
import '../models/settings.dart';

class BackupService {
  String generateBackupJson({
    required List<Product> products,
    required List<Session> sessions,
    required List<Currency> currencies,
    required Settings settings,
  }) {
    final backup = POSDataBackup(
      version: '1.0.0',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      products: products,
      sessions: sessions,
      currencies: currencies,
      settings: settings,
    );
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  POSDataBackup? parseBackupJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return POSDataBackup.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }
}
