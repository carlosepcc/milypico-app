import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../providers/pos_provider.dart';

class PriceTierDialog extends StatefulWidget {
  final Product product;
  final CartItem cartItem;
  final String cartId;

  const PriceTierDialog({
    super.key,
    required this.product,
    required this.cartItem,
    required this.cartId,
  });

  @override
  State<PriceTierDialog> createState() => _PriceTierDialogState();
}

class _PriceTierDialogState extends State<PriceTierDialog> {
  late PriceTier _selectedTier;
  final TextEditingController _customPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.cartItem.selectedTier;
    if (widget.cartItem.customPrice != null) {
      _customPriceCtrl.text = widget.cartItem.customPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _customPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.read<POSProvider>();

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(widget.product.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Seleccionar Tarifa de Precio:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),

            _buildTierOption(
              PriceTier.normal,
              'Normal',
              widget.product.normalPrice,
              Colors.sky,
            ),
            if (widget.product.wholesalePrice != null)
              _buildTierOption(
                PriceTier.mayorista,
                'Mayorista',
                widget.product.wholesalePrice!,
                Colors.emerald,
              ),
            if (widget.product.discountPrice != null)
              _buildTierOption(
                PriceTier.oferta,
                'Oferta',
                widget.product.discountPrice!,
                Colors.amber,
              ),
            _buildTierOption(
              PriceTier.personalizado,
              'Personalizado',
              double.tryParse(_customPriceCtrl.text) ?? widget.product.normalPrice,
              Colors.purple,
              isCustomInput: true,
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final customVal = double.tryParse(_customPriceCtrl.text);
                pos.updateCartItemTier(
                  widget.cartId,
                  widget.cartItem.id,
                  _selectedTier,
                  customPrice: _selectedTier == PriceTier.personalizado ? customVal : null,
                );
                Navigator.of(context).pop();
              },
              child: const Text('APLICAR TARIFA', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierOption(PriceTier tier, String label, double price, MaterialColor color, {bool isCustomInput = false}) {
    final isSelected = _selectedTier == tier;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedTier = tier;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF334155) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? const Color(0xFF34D399) : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (!isCustomInput)
                Text(
                  '\$${price.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                )
              else
                SizedBox(
                  width: 90,
                  height: 36,
                  child: TextField(
                    controller: _customPriceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      prefixText: '\$',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _selectedTier = PriceTier.personalizado;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
