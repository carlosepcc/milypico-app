import 'product.dart';

class TransactionItem {
  final String name;
  final String emoji;
  final double quantity;
  final UnitType unit;
  final double price;
  final double subtotal;

  TransactionItem({
    required this.name,
    required this.emoji,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emoji': emoji,
      'quantity': quantity,
      'unit': unit == UnitType.lb ? 'lb' : 'u',
      'price': price,
      'subtotal': subtotal,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '📦',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: (json['unit'] == 'lb') ? UnitType.lb : UnitType.u,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Transaction {
  final String id;
  final String sessionName;
  final int cartNumber;
  final List<TransactionItem> items;
  final double totalCUP;
  final String paymentCurrency;
  final double paymentAmount;
  final double exchangeRateUsed;
  final int timestamp;

  Transaction({
    required this.id,
    required this.sessionName,
    required this.cartNumber,
    required this.items,
    required this.totalCUP,
    required this.paymentCurrency,
    required this.paymentAmount,
    required this.exchangeRateUsed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionName': sessionName,
      'cartNumber': cartNumber,
      'items': items.map((e) => e.toJson()).toList(),
      'totalCUP': totalCUP,
      'paymentCurrency': paymentCurrency,
      'paymentAmount': paymentAmount,
      'exchangeRateUsed': exchangeRateUsed,
      'timestamp': timestamp,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      sessionName: json['sessionName'] as String? ?? '',
      cartNumber: (json['cartNumber'] as num?)?.toInt() ?? 1,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCUP: (json['totalCUP'] as num?)?.toDouble() ?? 0.0,
      paymentCurrency: json['paymentCurrency'] as String? ?? 'CUP',
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 0.0,
      exchangeRateUsed: (json['exchangeRateUsed'] as num?)?.toDouble() ?? 1.0,
      timestamp: (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
