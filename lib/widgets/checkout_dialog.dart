import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/cart.dart';
import '../models/currency.dart';

class CheckoutDialog extends StatefulWidget {
  final Cart cart;

  const CheckoutDialog({super.key, required this.cart});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  late String _selectedCurrencyCode;
  final TextEditingController _receivedCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final pos = Provider.of<POSProvider>(context, listen: false);
    _selectedCurrencyCode = pos.settings.defaultCurrency;
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = context.watch<POSProvider>();
    final double totalCUP = widget.cart.calculateTotal(pos.productLookup);

    Currency activeCurrency;
    try {
      activeCurrency = pos.currencies.firstWhere((c) => c.code == _selectedCurrencyCode);
    } catch (_) {
      activeCurrency = pos.currencies.first;
    }

    final double rate = activeCurrency.rateToBase;
    final double requiredAmount = rate > 0 ? (totalCUP / rate) : totalCUP;
    final double received = double.tryParse(_receivedCtrl.text) ?? 0.0;
    final double change = received >= requiredAmount ? (received - requiredAmount) : 0.0;
    final double changeCUP = change * rate;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cobro: Cliente #${widget.cart.number}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total Card
          Card.filled(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'TOTAL A COBRAR',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${totalCUP.toStringAsFixed(0)} CUP',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (activeCurrency.code != 'CUP') ...[
                    const SizedBox(height: 4),
                    Text(
                      '≈ ${requiredAmount.toStringAsFixed(2)} ${activeCurrency.code} (Tasa: \$${rate.toStringAsFixed(0)} CUP)',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text('Moneda de Pago', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pos.currencies.map((curr) {
              final isSelected = curr.code == _selectedCurrencyCode;
              return ChoiceChip(
                label: Text('${curr.code} (${curr.symbol})'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCurrencyCode = curr.code;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _receivedCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Monto recibido (${activeCurrency.code})',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Exacto',
                onPressed: () {
                  _receivedCtrl.text = requiredAmount % 1 == 0
                      ? requiredAmount.toInt().toString()
                      : requiredAmount.toStringAsFixed(2);
                  setState(() {});
                },
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          if (received >= requiredAmount && requiredAmount > 0) ...[
            const SizedBox(height: 12),
            Card.outlined(
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vuelto a devolver:', style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${change.toStringAsFixed(2)} ${activeCurrency.code}',
                          style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (activeCurrency.code != 'CUP')
                          Text(
                            '≈ \$${changeCUP.toStringAsFixed(0)} CUP',
                            style: TextStyle(color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7), fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.done_all),
            label: const Text('CONFIRMAR COBRO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final tx = await pos.checkoutCart(widget.cart.id, activeCurrency.code);
              if (context.mounted) {
                Navigator.of(context).pop();
                if (tx != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Venta de \$${tx.totalCUP.toStringAsFixed(0)} CUP registrada con éxito!'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
