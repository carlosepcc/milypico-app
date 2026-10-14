import 'package:flutter/material.dart';
import '../models/session.dart';

class SessionMetricsDialog extends StatelessWidget {
  final Session session;

  const SessionMetricsDialog({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double totalCUP = session.totalSalesCUP;
    final int count = session.transactions.length;
    final double avgTicket = count > 0 ? (totalCUP / count) : 0.0;
    final salesByCurrency = session.salesByCurrency;

    final productCounts = <String, double>{};
    final productSales = <String, double>{};
    for (final tx in session.transactions) {
      for (final item in tx.items) {
        productCounts[item.name] = (productCounts[item.name] ?? 0.0) + item.quantity;
        productSales[item.name] = (productSales[item.name] ?? 0.0) + item.subtotal;
      }
    }

    final sortedProds = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Métricas: ${session.name}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // KPI Cards Row
              Row(
                children: [
                  Expanded(
                    child: Card.filled(
                      color: colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL VENTAS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${totalCUP.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card.filled(
                      color: colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TICKETS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count',
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card.filled(
                      color: colorScheme.tertiaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROMEDIO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${avgTicket.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: colorScheme.onTertiaryContainer,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text('Ventas por Divisa', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: salesByCurrency.entries.map((e) {
                  return Chip(
                    label: Text('${e.key}: ${e.value.toStringAsFixed(2)}'),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              Text('Productos Más Vendidos', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (sortedProds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No hay ventas en esta sesión',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...sortedProds.take(5).map((e) {
                  final qty = productCounts[e.key] ?? 0;
                  return Card.outlined(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${qty.toStringAsFixed(1)} unidades vendidas'),
                      trailing: Text(
                        '\$${e.value.toStringAsFixed(0)} CUP',
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          child: const Text('Cerrar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
