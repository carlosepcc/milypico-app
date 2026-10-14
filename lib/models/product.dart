enum UnitType { u, lb }

enum PriceTier { normal, mayorista, oferta, personalizado }

class Product {
  final String id;
  final String name;
  final String emoji;
  final UnitType unit;
  final Map<PriceTier, double?> prices;
  final String category;
  final int createdTime;

  Product({
    required this.id,
    required this.name,
    required this.emoji,
    required this.unit,
    required this.prices,
    this.category = 'General',
    required this.createdTime,
  });

  double get normalPrice => prices[PriceTier.normal] ?? 0.0;
  double? get wholesalePrice => prices[PriceTier.mayorista];
  double? get discountPrice => prices[PriceTier.oferta];
  double? get customPrice => prices[PriceTier.personalizado];

  double getPriceForTier(PriceTier tier, {double? fallbackCustom}) {
    switch (tier) {
      case PriceTier.normal:
        return normalPrice;
      case PriceTier.mayorista:
        return wholesalePrice ?? normalPrice;
      case PriceTier.oferta:
        return discountPrice ?? normalPrice;
      case PriceTier.personalizado:
        return fallbackCustom ?? customPrice ?? normalPrice;
    }
  }

  Product copyWith({
    String? id,
    String? name,
    String? emoji,
    UnitType? unit,
    Map<PriceTier, double?>? prices,
    String? category,
    int? createdTime,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      unit: unit ?? this.unit,
      prices: prices ?? this.prices,
      category: category ?? this.category,
      createdTime: createdTime ?? this.createdTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'unit': unit == UnitType.lb ? 'lb' : 'u',
      'prices': {
        'normal': prices[PriceTier.normal],
        if (prices[PriceTier.mayorista] != null) 'mayorista': prices[PriceTier.mayorista],
        if (prices[PriceTier.oferta] != null) 'oferta': prices[PriceTier.oferta],
        if (prices[PriceTier.personalizado] != null) 'personalizado': prices[PriceTier.personalizado],
      },
      'category': category,
      'createdTime': createdTime,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawPrices = json['prices'] as Map<String, dynamic>? ?? {};
    final pricesMap = <PriceTier, double?>{
      PriceTier.normal: (rawPrices['normal'] as num?)?.toDouble() ?? 0.0,
      PriceTier.mayorista: (rawPrices['mayorista'] as num?)?.toDouble(),
      PriceTier.oferta: (rawPrices['oferta'] as num?)?.toDouble(),
      PriceTier.personalizado: (rawPrices['personalizado'] as num?)?.toDouble(),
    };

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '📦',
      unit: (json['unit'] == 'lb') ? UnitType.lb : UnitType.u,
      prices: pricesMap,
      category: json['category'] as String? ?? 'General',
      createdTime: (json['createdTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
