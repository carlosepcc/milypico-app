import 'package:flutter/material.dart';
import '../models/session.dart';

class SessionMetricsDialog extends StatelessWidget {
  final Session session;

  const SessionMetricsDialog({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final double totalCUP = session.totalSalesCUP;
    final int count = session.transactions.length;
    final double avgTicket = count > 0 ? (totalCUP / count) : 0.0;
    final salesByCurrency = session.salesByCurrency;

    // Product breakdown
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

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Color(0xFF34D399)),
                      const SizedBox(width: 8),
                      Text(
                        'Métricas: ${session.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPI Cards
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard('Total Ventas', '\$${totalCUP.toStringAsFixed(0)} CUP', const Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiCard('Tickets', '$count', const Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiCard('Ticket Promedio', '\$${avgTicket.toStringAsFixed(0)}', const Color(0xFFF59E0B)),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text('Ventas por Divisa:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: salesByCurrency.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      '${e.key}: ${e.value.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Text('Productos Más Vendidos:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),

              if (sortedProds.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No hay ventas registradas en esta sesión', style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                Column(
                  children: sortedProds.take(5).map((e) {
                    final qty = productCounts[e.key] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${qty.toStringAsFixed(1)} vendidos',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '\$${e.value.toStringAsFixed(0)} CUP',
                            style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
