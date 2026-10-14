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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = context.watch<POSProvider>();
    final currentSession = pos.currentSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turnos de Caja', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de Turnos',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const SessionHistoryDialog(),
              );
            },
          ),
          if (currentSession != null)
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      child: Icon(Icons.lock_clock, size: 40, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No hay ningún turno abierto',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Abre una nueva sesión de caja para despachar y registrar cobros en el sistema.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('ABRIR NUEVA SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => pos.openSession(),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Active Session Summary Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card.filled(
                    color: colorScheme.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                                      Badge(
                                        backgroundColor: colorScheme.primary,
                                        smallSize: 10,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        currentSession.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Iniciada: ${DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(DateTime.fromMillisecondsSinceEpoch(currentSession.createdTime))}',
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                  side: BorderSide(color: colorScheme.error),
                                ),
                                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                                label: const Text('Cerrar Turno'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('¿Cerrar Sesión Actual?'),
                                      content: Text(
                                        'Se registrará el cierre de ${currentSession.name} con un total acumulado de \$${currentSession.totalSalesCUP.toStringAsFixed(0)} CUP.',
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancelar'),
                                          onPressed: () => Navigator.of(ctx).pop(),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                          child: const Text('Cerrar Ahora'),
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
                          Row(
                            children: [
                              Expanded(
                                child: Card.filled(
                                  color: colorScheme.primaryContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TOTAL VENTAS',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${currentSession.totalSalesCUP.toStringAsFixed(0)} CUP',
                                          style: TextStyle(
                                            color: colorScheme.onPrimaryContainer,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Card.filled(
                                  color: colorScheme.secondaryContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TICKETS COBRADOS',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${currentSession.transactions.length}',
                                          style: TextStyle(
                                            color: colorScheme.onSecondaryContainer,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Registro de Ventas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${currentSession.transactions.length} ventas', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),

                Expanded(
                  child: currentSession.transactions.isEmpty
                      ? Center(
                          child: Text(
                            'No se han registrado ventas en este turno aún',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: currentSession.transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final tx = currentSession.transactions[index];
                            final timeStr = DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(tx.timestamp));

                            return Card.outlined(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  child: Text(
                                    '#${tx.cartNumber}',
                                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  tx.items.map((i) => '${i.quantity % 1 == 0 ? i.quantity.toInt() : i.quantity}x ${i.name}').join(', '),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '$timeStr • Pago en ${tx.paymentCurrency} (${tx.paymentAmount.toStringAsFixed(2)})',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                                ),
                                trailing: Text(
                                  '\$${tx.totalCUP.toStringAsFixed(0)} CUP',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
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
