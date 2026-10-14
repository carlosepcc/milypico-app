import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/product.dart';
import '../models/cart.dart';
import 'price_tier_dialog.dart';
import 'checkout_dialog.dart';

class KeypadWidget extends StatefulWidget {
  final double height;
  final ValueChanged<double>? onHeightChanged;

  const KeypadWidget({
    super.key,
    this.height = 290,
    this.onHeightChanged,
  });

  @override
  State<KeypadWidget> createState() => _KeypadWidgetState();
}

class _KeypadWidgetState extends State<KeypadWidget> {
  String _inputBuffer = '';
  bool _isFirstKey = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = context.watch<POSProvider>();
    final currentCart = pos.currentCart;
    final selectedProduct = pos.selectedProductId != null ? pos.productLookup[pos.selectedProductId] : null;

    CartItem? cartItem;
    if (currentCart != null && selectedProduct != null) {
      try {
        cartItem = currentCart.items.firstWhere((i) => i.productId == selectedProduct.id);
      } catch (_) {
        cartItem = null;
      }
    }

    final double currentQty = cartItem?.quantity ?? 0.0;
    final bool isLocked = cartItem?.isLocked ?? false;
    final double unitPrice = selectedProduct?.getPriceForTier(
          cartItem?.selectedTier ?? PriceTier.normal,
          fallbackCustom: cartItem?.customPrice,
        ) ?? 0.0;
    final double lineTotal = currentQty * unitPrice;
    final double cartTotal = currentCart?.calculateTotal(pos.productLookup) ?? 0.0;

    void handleKeyPress(String key) {
      if (currentCart == null || selectedProduct == null) return;
      if (isLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este producto está bloqueado y no se puede editar')),
        );
        return;
      }

      if (key == 'C') {
        setState(() {
          _inputBuffer = '';
          _isFirstKey = true;
        });
        pos.setProductQuantity(currentCart.id, selectedProduct.id, 0);
        return;
      }

      if (key == '⌫') {
        if (_inputBuffer.isNotEmpty) {
          final next = _inputBuffer.substring(0, _inputBuffer.length - 1);
          setState(() {
            _inputBuffer = next;
          });
          final val = double.tryParse(next) ?? 0.0;
          pos.setProductQuantity(currentCart.id, selectedProduct.id, val);
        } else {
          pos.setProductQuantity(currentCart.id, selectedProduct.id, 0);
        }
        return;
      }

      String next = _inputBuffer;
      if (_isFirstKey) {
        if (key == '.') {
          next = '0.';
        } else {
          next = key;
        }
        _isFirstKey = false;
      } else {
        if (key == '.' && _inputBuffer.contains('.')) return;
        next = _inputBuffer + key;
      }

      setState(() {
        _inputBuffer = next;
      });

      final val = double.tryParse(next);
      if (val != null) {
        pos.setProductQuantity(currentCart.id, selectedProduct.id, val);
      }
    }

    void handleQuickStep(double step) {
      if (currentCart == null || selectedProduct == null) return;
      if (isLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este producto está bloqueado')),
        );
        return;
      }
      final nextQty = (currentQty + step) < 0 ? 0.0 : (currentQty + step);
      pos.setProductQuantity(currentCart.id, selectedProduct.id, nextQty);
      setState(() {
        _inputBuffer = nextQty > 0 ? (nextQty % 1 == 0 ? nextQty.toInt().toString() : nextQty.toString()) : '';
        _isFirstKey = true;
      });
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Active Line Product Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                if (selectedProduct != null) ...[
                  Text(selectedProduct.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedProduct.name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '\$${unitPrice.toStringAsFixed(0)} CUP / ${selectedProduct.unit == UnitType.lb ? 'lb' : 'u'}',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (cartItem != null) ...[
                    // Price Tier Chip
                    ActionChip(
                      avatar: const Icon(Icons.sell_outlined, size: 14),
                      label: Text(
                        cartItem.selectedTier.name.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => PriceTierDialog(
                            product: selectedProduct,
                            cartItem: cartItem!,
                            cartId: currentCart!.id,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    // Line Lock Toggle Button
                    IconButton(
                      icon: Icon(
                        isLocked ? Icons.lock : Icons.lock_open_outlined,
                        size: 20,
                        color: isLocked ? colorScheme.error : colorScheme.onSurfaceVariant,
                      ),
                      tooltip: isLocked ? 'Desbloquear línea' : 'Bloquear línea',
                      onPressed: () {
                        pos.toggleCartItemLock(currentCart!.id, cartItem!.id);
                      },
                    ),
                  ],
                  // Subtotal Indicator
                  Card.filled(
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        '${currentQty % 1 == 0 ? currentQty.toInt() : currentQty.toStringAsFixed(2)} × \$${unitPrice.toStringAsFixed(0)} = \$${lineTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      'Toca un producto del catálogo para despachar',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Keypad Buttons Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                children: [
                  // 3x4 Numeric pad
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildRow(['7', '8', '9'], handleKeyPress, colorScheme),
                        _buildRow(['4', '5', '6'], handleKeyPress, colorScheme),
                        _buildRow(['1', '2', '3'], handleKeyPress, colorScheme),
                        _buildRow(['C', '0', '.'], handleKeyPress, colorScheme),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Actions Column
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => handleQuickStep(1.0),
                            child: const Text('+1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => handleQuickStep(5.0),
                            child: const Text('+5', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => handleKeyPress('⌫'),
                            child: const Icon(Icons.backspace_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Cobrar (Checkout) Button
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: cartTotal > 0
                                ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => CheckoutDialog(cart: currentCart!),
                                    );
                                  }
                                : null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('COBRAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                Text(
                                  '\$${cartTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys, void Function(String) onPress, ColorScheme colorScheme) {
    return Expanded(
      child: Row(
        children: keys.map((k) {
          final isClear = k == 'C';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: isClear ? colorScheme.errorContainer : colorScheme.surfaceContainerHigh,
                  foregroundColor: isClear ? colorScheme.onErrorContainer : colorScheme.onSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => onPress(k),
                child: Text(
                  k,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isClear ? colorScheme.error : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
