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

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.point_of_sale, color: Color(0xFF34D399)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cobrar Carrito #${widget.cart.number}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Total banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    const Text('TOTAL A PAGAR', style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${totalCUP.toStringAsFixed(0)} CUP',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    if (activeCurrency.code != 'CUP') ...[
                      const SizedBox(height: 4),
                      Text(
                        '≈ ${requiredAmount.toStringAsFixed(2)} ${activeCurrency.code} (Tasa: \$${rate.toStringAsFixed(0)})',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Currency Selector Chips
              const Text('Moneda de Pago:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pos.currencies.map((curr) {
                  final isSelected = curr.code == _selectedCurrencyCode;
                  return ChoiceChip(
                    label: Text('${curr.code} (${curr.symbol})'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFF334155),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
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

              // Received Amount Field
              TextField(
                controller: _receivedCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Monto Recibido (${activeCurrency.code})',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Color(0xFF34D399)),
                    onPressed: () {
                      _receivedCtrl.text = requiredAmount % 1 == 0
                          ? requiredAmount.toInt().toString()
                          : requiredAmount.toStringAsFixed(2);
                      setState(() {});
                    },
                    tooltip: 'Exacto',
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 12),

              // Change (Vuelto) display
              if (received >= requiredAmount && requiredAmount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Vuelto a Entregar:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${change.toStringAsFixed(2)} ${activeCurrency.code}',
                            style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          if (activeCurrency.code != 'CUP')
                            Text(
                              '≈ \$${changeCUP.toStringAsFixed(0)} CUP',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Confirm Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final tx = await pos.checkoutCart(widget.cart.id, activeCurrency.code);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (tx != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Venta de \$${tx.totalCUP.toStringAsFixed(0)} CUP completada con éxito!'),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    }
                  }
                },
                child: const Text('CONFIRMAR PAGO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
