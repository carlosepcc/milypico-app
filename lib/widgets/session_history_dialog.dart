import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/session.dart';
import 'session_metrics_dialog.dart';

class SessionHistoryDialog extends StatelessWidget {
  const SessionHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();
    final closedSessions = pos.sessions.where((s) => !s.isOpen).toList();

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 550,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF34D399)),
                    SizedBox(width: 8),
                    Text(
                      'Historial de Sesiones',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: closedSessions.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay sesiones anteriores cerradas',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: closedSessions.length,
                      itemBuilder: (context, index) {
                        final s = closedSessions[index];
                        final dateStr = DateFormat('dd/MM/yyyy HH:mm')
                            .format(DateTime.fromMillisecondsSinceEpoch(s.createdTime));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: ListTile(
                            title: Text(
                              s.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '$dateStr • ${s.transactions.length} transacciones',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${s.totalSalesCUP.toStringAsFixed(0)} CUP',
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.analytics_outlined, color: Colors.amberAccent, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => SessionMetricsDialog(session: s),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
