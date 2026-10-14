import 'product.dart';

class CartItem {
  final String id;
  final String productId;
  double quantity;
  PriceTier selectedTier;
  double? customPrice;
  bool isLocked;

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    this.selectedTier = PriceTier.normal,
    this.customPrice,
    this.isLocked = false,
  });

  CartItem copyWith({
    String? id,
    String? productId,
    double? quantity,
    PriceTier? selectedTier,
    double? customPrice,
    bool? isLocked,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      selectedTier: selectedTier ?? this.selectedTier,
      customPrice: customPrice ?? this.customPrice,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'selectedTier': selectedTier.name,
      if (customPrice != null) 'customPrice': customPrice,
      'isLocked': isLocked,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    PriceTier parseTier(String? tierStr) {
      switch (tierStr) {
        case 'mayorista':
          return PriceTier.mayorista;
        case 'oferta':
          return PriceTier.oferta;
        case 'personalizado':
          return PriceTier.personalizado;
        default:
          return PriceTier.normal;
      }
    }

    return CartItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      selectedTier: parseTier(json['selectedTier'] as String?),
      customPrice: (json['customPrice'] as num?)?.toDouble(),
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }
}

class Cart {
  final String id;
  final int number;
  final String color;
  final List<CartItem> items;
  final int createdTime;

  Cart({
    required this.id,
    required this.number,
    required this.color,
    required this.items,
    required this.createdTime,
  });

  double calculateTotal(Map<String, Product> productLookup) {
    double total = 0.0;
    for (final item in items) {
      final product = productLookup[item.productId];
      if (product != null) {
        final price = product.getPriceForTier(item.selectedTier, fallbackCustom: item.customPrice);
        total += price * item.quantity;
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'color': color,
      'items': items.map((i) => i.toJson()).toList(),
      'createdTime': createdTime,
    };
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] as String,
      number: (json['number'] as num?)?.toInt() ?? 1,
      color: json['color'] as String? ?? 'sky',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdTime: (json['createdTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
