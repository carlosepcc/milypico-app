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
    final theme = Theme.of(context);
    final pos = context.read<POSProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(widget.product.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Selecciona la tarifa de precio aplicada',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          RadioListTile<PriceTier>(
            value: PriceTier.normal,
            groupValue: _selectedTier,
            title: const Text('Normal'),
            subtitle: Text('\$${widget.product.normalPrice.toStringAsFixed(0)} CUP'),
            onChanged: (val) => setState(() => _selectedTier = val!),
          ),

          if (widget.product.wholesalePrice != null)
            RadioListTile<PriceTier>(
              value: PriceTier.mayorista,
              groupValue: _selectedTier,
              title: const Text('Mayorista'),
              subtitle: Text('\$${widget.product.wholesalePrice!.toStringAsFixed(0)} CUP'),
              onChanged: (val) => setState(() => _selectedTier = val!),
            ),

          if (widget.product.discountPrice != null)
            RadioListTile<PriceTier>(
              value: PriceTier.oferta,
              groupValue: _selectedTier,
              title: const Text('Oferta'),
              subtitle: Text('\$${widget.product.discountPrice!.toStringAsFixed(0)} CUP'),
              onChanged: (val) => setState(() => _selectedTier = val!),
            ),

          RadioListTile<PriceTier>(
            value: PriceTier.personalizado,
            groupValue: _selectedTier,
            title: const Text('Precio Personalizado'),
            subtitle: _selectedTier == PriceTier.personalizado
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _customPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          suffixText: 'CUP',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  )
                : const Text('Ingresa un monto específico'),
            onChanged: (val) => setState(() => _selectedTier = val!),
          ),

          const SizedBox(height: 16),

          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }
}
