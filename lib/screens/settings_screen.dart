import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();
    final settings = pos.settings;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Configuración del Sistema', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: General Settings
          const Text('GENERAL', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Moneda Predeterminada', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Moneda por defecto para cobros: ${settings.defaultCurrency}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  trailing: DropdownButton<String>(
                    value: settings.defaultCurrency,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
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
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  title: const Text('Respuesta Háptica (Vibración)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Vibrar al pulsar teclado numérico y botones de cobro', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  value: settings.hapticFeedbackEnabled,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    pos.updateSettings(settings.copyWith(hapticFeedbackEnabled: val));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Backup & Storage
          const Text('RESPALDO Y DATOS', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFF34D399)),
                  title: const Text('Exportar Respaldo (JSON)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Copia o descarga todos tus productos, sesiones y divisas', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  onTap: () {
                    final jsonStr = pos.exportBackupJson();
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Respaldo copiado al portapapeles exitosamente!'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.upload, color: Colors.amberAccent),
                  title: const Text('Restaurar Respaldo', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Pegar JSON de respaldo para restablecer datos', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  onTap: () {
                    final ctrl = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Pegar Respaldo JSON', style: TextStyle(color: Colors.white)),
                        content: SizedBox(
                          width: 400,
                          child: TextField(
                            controller: ctrl,
                            maxLines: 8,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: 'Pega el contenido JSON del respaldo aquí...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                            child: const Text('Restaurar', style: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              final text = ctrl.text.trim();
                              if (text.isNotEmpty) {
                                final success = await pos.restoreBackupJson(text);
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Respaldo restaurado con éxito!' : 'Error: Formato de respaldo inválido'),
                                      backgroundColor: success ? const Color(0xFF059669) : const Color(0xFFDC2626),
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
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_sync, color: Color(0xFF38BDF8)),
                  title: const Text('Sincronización Google Drive', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Respaldo automático en la nube sin servidor', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  onTap: () {
                    final clientIdCtrl = TextEditingController(text: settings.googleClientId);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: const Text('Google Drive OAuth Client ID', style: TextStyle(color: Colors.white)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Ingresa tu Google Cloud Client ID (OAuth 2.0 Web Client) para activar sincronización nativa en Google Drive:',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: clientIdCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Google Client ID',
                                hintText: 'xxxxxxxx.apps.googleusercontent.com',
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
                            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
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

          // Section: About
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Milypico POS - Flutter Edition', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text(
                  'Versión 1.0.0 (Offline-First)\nDiseñado específicamente para el comercio y gastronomía con soporte multi-moneda (CUP, USD, EUR, MLC), carritos dinámicos y arquitectura 100% Flutter.',
                  style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
