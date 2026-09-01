import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../data/ml/spam_ml_scorer.dart';
import '../../../domain/models/call_category.dart';
import '../../state/settings_provider.dart';
import '../../widgets/signal_card.dart';
import '../onboarding/onboarding_wizard_screen.dart';
import '../onboarding/setup_checklist_screen.dart';
import '../scanner/device_scanner_screen.dart';
import '../permissions/permissions_dashboard_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Protection Capabilities & Permissions Dashboard ──
          SignalCard(
            padding: const EdgeInsets.all(12),
            borderColor: Colors.greenAccent.withValues(alpha: 0.4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PermissionsDashboardScreen()),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.greenAccent),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Protection & Permission Matrix', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('View & grant all 8 capabilities, notification access & system health', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Device Scanner & Analyzer ──
          SignalCard(
            padding: const EdgeInsets.all(12),
            borderColor: SignalLedgerTheme.cyan.withValues(alpha: 0.4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceScannerScreen()),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.document_scanner_rounded, color: SignalLedgerTheme.cyan),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Device Scanner & Analyzer', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('Scan Call Log, SMS Inbox, Contacts & sync spam with server', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── System Permissions & Setup Checklist ──
          SignalCard(
            padding: const EdgeInsets.all(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SetupChecklistScreen()),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.checklist_rounded, color: SignalLedgerTheme.cyan),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Setup & Permissions', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('Configure Call Screening role & system permissions', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Onboarding Setup Wizard ──
          SignalCard(
            padding: const EdgeInsets.all(12),
            borderColor: SignalLedgerTheme.purple.withValues(alpha: 0.3),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: SignalLedgerTheme.purple),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Re-run Onboarding Wizard', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('Step-by-step setup guide for permissions and screening role', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Appearance & Themes ──
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          SignalCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.palette_outlined, color: SignalLedgerTheme.cyan),
                    SizedBox(width: 12),
                    Text('Theme Palette', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                DropdownButton<AppThemeMode>(
                  value: settings.themeMode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: AppThemeMode.dark, child: Text('Dark (Default)')),
                    DropdownMenuItem(value: AppThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: AppThemeMode.graphite, child: Text('Graphite')),
                    DropdownMenuItem(value: AppThemeMode.amoled, child: Text('AMOLED Black')),
                    DropdownMenuItem(value: AppThemeMode.system, child: Text('System')),
                  ],
                  onChanged: (mode) {
                    if (mode != null) settings.setThemeMode(mode);
                  },
                ),
              ],
            ),
          ),

          // ── Category-Level Call Policies ──
          const SizedBox(height: 16),
          const Text('Category Call Policies', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          SignalCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: settings.categoryPolicies.entries.map((entry) {
                final category = entry.key;
                final action = entry.value;
                return Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(category.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: DropdownButton<CallAction>(
                        value: action,
                        underline: const SizedBox(),
                        items: CallAction.values.map((a) {
                          return DropdownMenuItem(value: a, child: Text(a.label));
                        }).toList(),
                        onChanged: (newAction) {
                          if (newAction != null) {
                            settings.setCategoryPolicy(category, newAction);
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),

          // ── Quiet Hours ──
          const SizedBox(height: 16),
          const Text('Quiet Hours Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          SignalCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.nightlight_round, color: SignalLedgerTheme.purple),
                  title: const Text('Enable Quiet Hours'),
                  subtitle: Text(
                    settings.quietHoursEnabled
                        ? 'Active between ${settings.quietStartHour}:00 and ${settings.quietEndHour}:00'
                        : 'Block non-contact calls during rest hours',
                  ),
                  value: settings.quietHoursEnabled,
                  activeThumbColor: SignalLedgerTheme.purple,
                  onChanged: (v) {
                    settings.setQuietHours(
                      enabled: v,
                      startHour: settings.quietStartHour,
                      startMinute: settings.quietStartMinute,
                      endHour: settings.quietEndHour,
                      endMinute: settings.quietEndMinute,
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Server & Database Sync ──
          const SizedBox(height: 16),
          const Text('Backend Server & Shards', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          SignalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Server Connection', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: SignalLedgerTheme.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('v${settings.databaseVersion}', style: const TextStyle(color: SignalLedgerTheme.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('URL: ${settings.serverUrl}', style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                const SizedBox(height: 4),
                Text('ML Engine: ${SpamMLScorer.instance.health.name} (GBT 20 features)', style: const TextStyle(fontSize: 12, color: SignalLedgerTheme.cyan)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: settings.isSyncing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.cloud_sync_rounded),
                        label: Text(settings.isSyncing ? 'Syncing...' : 'Sync Database'),
                        onPressed: settings.isSyncing ? null : () => settings.syncDatabase(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      child: const Text('Configure URL'),
                      onPressed: () => _showServerUrlDialog(context, settings),
                    ),
                  ],
                ),
                if (settings.syncStatus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(settings.syncStatus, style: const TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                ],
              ],
            ),
          ),

          // ── Backup & Export ──
          const SizedBox(height: 16),
          const Text('Data & Portable Backup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          SignalCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.enhanced_encryption_rounded, color: SignalLedgerTheme.cyan),
                  title: const Text('Encrypted Backup Export'),
                  subtitle: const Text('AES-256-GCM + PBKDF2 export of all rules'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _showExportDialog(context, settings),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_backup_restore_rounded, color: SignalLedgerTheme.green),
                  title: const Text('Restore Backup'),
                  subtitle: const Text('Import rules from JSON backup'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _showImportDialog(context, settings),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.table_chart_rounded, color: SignalLedgerTheme.amber),
                  title: const Text('Export Call Logs to CSV'),
                  subtitle: const Text('Download activity logs in standard CSV format'),
                  trailing: const Icon(Icons.file_download_outlined, size: 20),
                  onTap: () async {
                    final csv = await settings.exportLogsToCsv();
                    if (context.mounted) {
                      _showCsvDialog(context, csv);
                    }
                  },
                ),
              ],
            ),
          ),

          // ── About ──
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text('CallShield v${AppConstants.appVersion}', style: const TextStyle(fontWeight: FontWeight.bold, color: SignalLedgerTheme.darkTextMuted)),
                const SizedBox(height: 4),
                const Text('Open-source spam call and text blocker', style: TextStyle(fontSize: 12, color: SignalLedgerTheme.darkTextMuted)),
                const SizedBox(height: 2),
                const Text('Zero tracking · 100% on-device ML evaluation', style: TextStyle(fontSize: 11, color: SignalLedgerTheme.cyan)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showServerUrlDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.serverUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:3000',
            labelText: 'Server API Endpoint',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              settings.setServerUrl(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, SettingsProvider settings) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Encrypted Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a passphrase to encrypt your backup with AES-256-GCM. Leave blank for plaintext.'),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passphrase (Optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final exported = await settings.exportEncryptedBackup(passController.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                _showExportResult(context, exported);
              }
            },
            child: const Text('Generate Backup'),
          ),
        ],
      ),
    );
  }

  void _showExportResult(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup Generated'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(content, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, SettingsProvider settings) {
    final jsonController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jsonController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Paste Backup JSON payload',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passphrase (if encrypted)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok = await settings.importBackup(jsonController.text.trim(), passController.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Backup restored successfully!' : 'Failed to restore backup (invalid passphrase or format)'),
                    backgroundColor: ok ? SignalLedgerTheme.green : SignalLedgerTheme.red,
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showCsvDialog(BuildContext context, String csv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Export'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
