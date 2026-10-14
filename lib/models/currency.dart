class Currency {
  final String code;
  final String name;
  final String symbol;
  double rateToBase; // CUP per 1 unit of this currency
  final bool isCustom;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.rateToBase,
    this.isCustom = false,
  });

  Currency copyWith({
    String? code,
    String? name,
    String? symbol,
    double? rateToBase,
    bool? isCustom,
  }) {
    return Currency(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      rateToBase: rateToBase ?? this.rateToBase,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'rateToBase': rateToBase,
      'isCustom': isCustom,
    };
  }

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String? ?? '\$',
      rateToBase: (json['rateToBase'] as num?)?.toDouble() ?? 1.0,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}
