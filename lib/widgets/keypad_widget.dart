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
    this.height = 280,
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
        color: const Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: Column(
        children: [
          // Drag handle & Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                if (selectedProduct != null) ...[
                  Text(selectedProduct.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedProduct.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '\$${unitPrice.toStringAsFixed(1)} / ${selectedProduct.unit == UnitType.lb ? 'lb' : 'u'}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (cartItem != null) ...[
                    // Tier badge
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => PriceTierDialog(
                            product: selectedProduct,
                            cartItem: cartItem!,
                            cartId: currentCart!.id,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          cartItem.selectedTier.name.toUpperCase(),
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Lock button
                    IconButton(
                      icon: Icon(
                        isLocked ? Icons.lock : Icons.lock_open,
                        size: 18,
                        color: isLocked ? Colors.amber : Colors.white60,
                      ),
                      onPressed: () {
                        pos.toggleCartItemLock(currentCart!.id, cartItem!.id);
                      },
                    ),
                  ],
                  // Subtotal indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${currentQty % 1 == 0 ? currentQty.toInt() : currentQty.toStringAsFixed(2)} × \$${unitPrice.toStringAsFixed(0)} = \$${lineTotal.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ] else ...[
                  const Expanded(
                    child: Text(
                      'Selecciona un producto del catálogo',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Keypad Rows
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                children: [
                  // Numeric 4x3 grid
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildRow(['7', '8', '9'], handleKeyPress),
                        _buildRow(['4', '5', '6'], handleKeyPress),
                        _buildRow(['1', '2', '3'], handleKeyPress),
                        _buildRow(['C', '0', '.'], handleKeyPress),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Action side column
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // Quick +1
                        Expanded(
                          child: _buildActionBtn(
                            label: '+1',
                            color: const Color(0xFF334155),
                            textColor: Colors.white,
                            onTap: () => handleQuickStep(1.0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Quick +5
                        Expanded(
                          child: _buildActionBtn(
                            label: '+5',
                            color: const Color(0xFF334155),
                            textColor: Colors.white,
                            onTap: () => handleQuickStep(5.0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Backspace
                        Expanded(
                          child: _buildActionBtn(
                            label: '⌫',
                            color: const Color(0xFF475569),
                            textColor: Colors.amberAccent,
                            onTap: () => handleKeyPress('⌫'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Cobrar (Checkout) Button
                        Expanded(
                          child: _buildActionBtn(
                            label: 'Cobrar\n\$${cartTotal.toStringAsFixed(0)}',
                            color: cartTotal > 0 ? const Color(0xFF10B981) : const Color(0xFF334155),
                            textColor: Colors.white,
                            isBold: true,
                            onTap: cartTotal > 0
                                ? () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => CheckoutDialog(cart: currentCart!),
                                    );
                                  }
                                : null,
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

  Widget _buildRow(List<String> keys, void Function(String) onPress) {
    return Expanded(
      child: Row(
        children: keys.map((k) {
          final isSpecial = k == 'C';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Material(
                color: isSpecial ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onPress(k),
                  child: Center(
                    child: Text(
                      k,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSpecial ? const Color(0xFFF87171) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
    bool isBold = false,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
