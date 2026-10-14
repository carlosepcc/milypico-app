import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/currency.dart';

class CurrenciesScreen extends StatelessWidget {
  const CurrenciesScreen({super.key});

  void _showEditRateDialog(BuildContext context, Currency currency) {
    final pos = context.read<POSProvider>();
    final rateCtrl = TextEditingController(text: currency.rateToBase.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tasa de Cambio: ${currency.code}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1 ${currency.code} equivale a cuántos Pesos Cubanos (CUP):', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Color(0xFF34D399), fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Tasa a CUP',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Guardar Tasa', style: TextStyle(color: Colors.white)),
            onPressed: () {
              final newRate = double.tryParse(rateCtrl.text);
              if (newRate != null && newRate > 0) {
                pos.updateCurrencyRate(currency.code, newRate);
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showAddCurrencyDialog(BuildContext context) {
    final pos = context.read<POSProvider>();
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final symbolCtrl = TextEditingController(text: '\$');
    final rateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Añadir Divisa Personalizada', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Código (ej: CAD, GBP, USDT)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nombre completo (ej: Dólar Canadiense)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: symbolCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Símbolo (ej: C\$, £)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Tasa en CUP (1 unidad = ? CUP)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Añadir', style: TextStyle(color: Colors.white)),
            onPressed: () {
              final code = codeCtrl.text.trim().toUpperCase();
              final name = nameCtrl.text.trim();
              final symbol = symbolCtrl.text.trim();
              final rate = double.tryParse(rateCtrl.text) ?? 1.0;

              if (code.isNotEmpty && name.isNotEmpty) {
                pos.addCustomCurrency(Currency(
                  code: code,
                  name: name,
                  symbol: symbol.isEmpty ? '\$' : symbol,
                  rateToBase: rate,
                  isCustom: true,
                ));
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Tasas de Cambio / Multi-Divisa', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF34D399), size: 28),
            tooltip: 'Añadir Divisa',
            onPressed: () => _showAddCurrencyDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Todas las tasas son relativas a la moneda base (CUP). Al registrar un cobro en otra divisa, el sistema calcula automáticamente la equivalencia y el vuelto.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...pos.currencies.map((currency) {
            final isBase = currency.code == 'CUP';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBase ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0F172A),
                  child: Text(
                    currency.symbol,
                    style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  '${currency.name} (${currency.code})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isBase ? 'Moneda Base del Sistema (1.00)' : '1 ${currency.code} = \$${currency.rateToBase.toStringAsFixed(0)} CUP',
                  style: TextStyle(color: isBase ? const Color(0xFF34D399) : Colors.white60, fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isBase)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.amberAccent, size: 20),
                        tooltip: 'Modificar Tasa',
                        onPressed: () => _showEditRateDialog(context, currency),
                      ),
                    if (currency.isCustom)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFF87171), size: 20),
                        tooltip: 'Eliminar Divisa',
                        onPressed: () => pos.deleteCustomCurrency(currency.code),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
