import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../widgets/session_metrics_dialog.dart';
import '../widgets/session_history_dialog.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();
    final currentSession = pos.currentSession;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Sesión de Caja', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            tooltip: 'Historial de Sesiones',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const SessionHistoryDialog(),
              );
            },
          ),
          if (currentSession != null)
            IconButton(
              icon: const Icon(Icons.analytics_outlined, color: Color(0xFF34D399)),
              tooltip: 'Métricas de la Sesión',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => SessionMetricsDialog(session: currentSession),
                );
              },
            ),
        ],
      ),
      body: currentSession == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock, size: 64, color: Colors.amberAccent),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No hay ninguna sesión abierta',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Abre una nueva sesión para registrar ventas y cobrar.',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('ABRIR NUEVA SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: () => pos.openSession(),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Session Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1E293B),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34D399),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentSession.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Iniciada el ${DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(DateTime.fromMillisecondsSinceEpoch(currentSession.createdTime))}',
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              foregroundColor: const Color(0xFFF87171),
                              side: const BorderSide(color: Color(0xFFEF4444)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.stop_circle_outlined, size: 18),
                            label: const Text('Cerrar Caja'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E293B),
                                  title: const Text('¿Cerrar Sesión Actual?', style: TextStyle(color: Colors.white)),
                                  content: Text(
                                    'Se registrará el cierre de ${currentSession.name} con un total acumulado de \$${currentSession.totalSalesCUP.toStringAsFixed(0)} CUP.',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                      child: const Text('Cerrar Ahora', style: TextStyle(color: Colors.white)),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        pos.closeSession();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Sales Summary Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOTAL ACUMULADO', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${currentSession.totalSalesCUP.toStringAsFixed(0)} CUP',
                                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('VENTAS REALIZADAS', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${currentSession.transactions.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transactions List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Registro de Ventas',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${currentSession.transactions.length} tickets',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Transactions ListView
                Expanded(
                  child: currentSession.transactions.isEmpty
                      ? const Center(
                          child: Text('No hay transacciones aún en esta sesión.', style: TextStyle(color: Colors.white54)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: currentSession.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = currentSession.transactions[index];
                            final timeStr = DateFormat('HH:mm:ss')
                                .format(DateTime.fromMillisecondsSinceEpoch(tx.timestamp));

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF0F172A),
                                  child: Text(
                                    '#${tx.cartNumber}',
                                    style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                title: Text(
                                  tx.items.map((i) => '${i.quantity % 1 == 0 ? i.quantity.toInt() : i.quantity}x ${i.name}').join(', '),
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '$timeStr • Pago en ${tx.paymentCurrency} (${tx.paymentAmount.toStringAsFixed(2)})',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                trailing: Text(
                                  '\$${tx.totalCUP.toStringAsFixed(0)} CUP',
                                  style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
