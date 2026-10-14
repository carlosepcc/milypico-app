import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = context.watch<POSProvider>();
    final settings = pos.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Apariencia y General
          Text(
            'GENERAL Y APARIENCIA',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card.outlined(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Tema de la Aplicación'),
                  subtitle: Text('Tema actual: ${settings.theme == 'dark' ? 'Oscuro' : settings.theme == 'light' ? 'Claro' : 'Sistema'}'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'light', icon: Icon(Icons.light_mode, size: 16)),
                      ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode, size: 16)),
                    ],
                    selected: {settings.theme == 'light' ? 'light' : 'dark'},
                    onSelectionChanged: (val) {
                      pos.updateSettings(settings.copyWith(theme: val.first));
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Moneda Predeterminada'),
                  subtitle: Text('Moneda por defecto para cobros: ${settings.defaultCurrency}'),
                  trailing: DropdownButton<String>(
                    value: settings.defaultCurrency,
                    items: pos.currencies.map((c) {
                      return DropdownMenuItem(value: c.code, child: Text(c.code));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        pos.updateSettings(settings.copyWith(defaultCurrency: val));
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('Respuesta Háptica (Vibración)'),
                  subtitle: const Text('Vibrar al pulsar el teclado numérico y registrar cobros'),
                  value: settings.hapticFeedbackEnabled,
                  onChanged: (val) {
                    pos.updateSettings(settings.copyWith(hapticFeedbackEnabled: val));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Respaldo y Datos
          Text(
            'RESPALDO Y DATOS',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card.outlined(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Exportar Respaldo (JSON)'),
                  subtitle: const Text('Copia al portapapeles todos los productos, turnos y tasas'),
                  onTap: () {
                    final jsonStr = pos.exportBackupJson();
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Respaldo copiado al portapapeles con éxito!'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Restaurar Respaldo'),
                  subtitle: const Text('Pegar JSON de respaldo para restablecer datos'),
                  onTap: () {
                    final ctrl = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Restaurar Respaldo'),
                        content: SizedBox(
                          width: 420,
                          child: TextField(
                            controller: ctrl,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              hintText: 'Pega el texto JSON de respaldo aquí...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancelar'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          FilledButton(
                            child: const Text('Restaurar'),
                            onPressed: () async {
                              final text = ctrl.text.trim();
                              if (text.isNotEmpty) {
                                final ok = await pos.restoreBackupJson(text);
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok ? 'Datos restaurados con éxito!' : 'Error: Formato inválido'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('Sincronización Google Drive'),
                  subtitle: const Text('Configurar Google OAuth Client ID para sincronizar en la nube'),
                  onTap: () {
                    final clientIdCtrl = TextEditingController(text: settings.googleClientId);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Google OAuth Client ID'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Ingresa tu Google Cloud Client ID (OAuth 2.0 Web Client) para activar sincronización nativa en Google Drive:',
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: clientIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Google Client ID',
                                hintText: 'xxxxxxxx.apps.googleusercontent.com',
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
                            child: const Text('Guardar'),
                            onPressed: () {
                              pos.updateSettings(settings.copyWith(googleClientId: clientIdCtrl.text.trim()));
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Card
          Card.filled(
            color: colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Milypico POS — Flutter Native',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Punto de Venta 100% Flutter con interfaz Material Design 3, soporte multi-moneda en tiempo real, múltiples clientes simultáneos y persistencia offline.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
