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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = context.watch<POSProvider>();
    final closedSessions = pos.sessions.where((s) => !s.isOpen).toList();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Historial de Sesiones',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 480,
        child: closedSessions.isEmpty
            ? Center(
                child: Text(
                  'No hay sesiones anteriores cerradas',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            : ListView.separated(
                itemCount: closedSessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final s = closedSessions[index];
                  final dateStr = DateFormat('dd/MM/yyyy HH:mm')
                      .format(DateTime.fromMillisecondsSinceEpoch(s.createdTime));

                  return Card.outlined(
                    child: ListTile(
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '$dateStr • ${s.transactions.length} tickets',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${s.totalSalesCUP.toStringAsFixed(0)} CUP',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.analytics_outlined),
                            tooltip: 'Ver Métricas',
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
      actions: [
        FilledButton(
          child: const Text('Cerrar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
