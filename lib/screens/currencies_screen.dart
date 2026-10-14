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
        title: Text('Tasa de Cambio: ${currency.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1 unidad de esta divisa equivale a cuántos Pesos Cubanos (CUP):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Tasa en CUP',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            child: const Text('Guardar Tasa'),
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
        title: const Text('Añadir Divisa Personalizada'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código (ej: CAD, GBP, USDT)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre descriptivo (ej: Dólar Canadiense)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: symbolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Símbolo (ej: C\$, £)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tasa en CUP (1 unidad = ? CUP)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            child: const Text('Añadir Divisa'),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = context.watch<POSProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasas de Cambio', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Añadir Divisa'),
        onPressed: () => _showAddCurrencyDialog(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card.filled(
            color: colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Todas las tasas son relativas al Peso Cubano (CUP). Al cobrar en otra divisa, el sistema calcula automáticamente la equivalencia y el cambio.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...pos.currencies.map((currency) {
            final isBase = currency.code == 'CUP';
            return Card.outlined(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBase ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                  child: Text(
                    currency.symbol,
                    style: TextStyle(
                      color: isBase ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${currency.name} (${currency.code})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isBase
                      ? 'Moneda Base de Referencia (1.00)'
                      : '1 ${currency.code} = \$${currency.rateToBase.toStringAsFixed(0)} CUP',
                  style: TextStyle(
                    color: isBase ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isBase)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar Tasa',
                        onPressed: () => _showEditRateDialog(context, currency),
                      ),
                    if (currency.isCustom)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: colorScheme.error),
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
