import 'transaction.dart';

class Session {
  final String id;
  final String name;
  final int createdTime;
  final int? closedTime;
  final String status; // 'open' | 'closed'
  final List<Transaction> transactions;

  Session({
    required this.id,
    required this.name,
    required this.createdTime,
    this.closedTime,
    required this.status,
    required this.transactions,
  });

  bool get isOpen => status == 'open';

  double get totalSalesCUP {
    return transactions.fold(0.0, (sum, t) => sum + t.totalCUP);
  }

  Map<String, double> get salesByCurrency {
    final map = <String, double>{};
    for (final t in transactions) {
      map[t.paymentCurrency] = (map[t.paymentCurrency] ?? 0.0) + t.paymentAmount;
    }
    return map;
  }

  Session copyWith({
    String? id,
    String? name,
    int? createdTime,
    int? closedTime,
    String? status,
    List<Transaction>? transactions,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      createdTime: createdTime ?? this.createdTime,
      closedTime: closedTime ?? this.closedTime,
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdTime': createdTime,
      if (closedTime != null) 'closedTime': closedTime,
      'status': status,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      name: json['name'] as String,
      createdTime: (json['createdTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      closedTime: (json['closedTime'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'open',
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
