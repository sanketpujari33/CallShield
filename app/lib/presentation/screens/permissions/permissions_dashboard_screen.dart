import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/permission_models.dart';
import '../../state/permissions_provider.dart';

class PermissionsDashboardScreen extends StatefulWidget {
  const PermissionsDashboardScreen({super.key});

  @override
  State<PermissionsDashboardScreen> createState() => _PermissionsDashboardScreenState();
}

class _PermissionsDashboardScreenState extends State<PermissionsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PermissionsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PermissionsProvider>();
    final score = provider.readinessScore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protection & Permissions'),
        actions: [
          IconButton(
            icon: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Re-scan system permissions',
            onPressed: () => provider.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Direct Open App Notification Settings',
            onPressed: () => provider.openNotificationSettings(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Direct Open App System Settings',
            onPressed: () => provider.openAppSettings(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildReadinessHeroCard(context, provider, score),
            const SizedBox(height: 16),
            _buildSectionHeader('CORE TELEPHONY PROTECTION', Icons.phone_in_talk_outlined),
            _buildCapabilityTile(
              context,
              provider,
              PermissionCapabilityId.callScreeningRole,
              Icons.shield_outlined,
            ),
            _buildCapabilityTile(
              context,
              provider,
              PermissionCapabilityId.readCallLog,
              Icons.call_outlined,
            ),
            _buildCapabilityTile(
              context,
              provider,
              PermissionCapabilityId.readContacts,
              Icons.contacts_outlined,
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('MESSAGING & NOTIFICATION SHIELD', Icons.mark_chat_unread_outlined),
            _buildCapabilityTile(
              context,
              provider,
              PermissionCapabilityId.readSms,
              Icons.sms_outlined,
            ),
            _buildCapabilityTile(
              context,
              provider,
              PermissionCapabilityId.receiveSms,
              Icons.move_to_inbox_outlined,
            ),
            _buildCapabilityTile(
              context,
              provider,
              PermissionCapabilityId.notificationAccess,
              Icons.notifications_active_outlined,
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('SYSTEM DURABILITY & HEADS-UP ALERTS', Icons.security_outlined),
            _buildCapabilityTile(
              context,
              provider,
              PermissionCapabilityId.overlay,
              Icons.layers_outlined,
            ),
            _buildCapabilityTile(
              context,
              provider,
              PermissionCapabilityId.batteryExempt,
              Icons.battery_charging_full_outlined,
            ),
            _buildCapabilityTile(
              context,
              provider,
              PermissionCapabilityId.postNotifications,
              Icons.notification_important_outlined,
            ),
            const SizedBox(height: 24),
            _buildPrivacyCard(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessHeroCard(BuildContext context, PermissionsProvider provider, int score) {
    final theme = Theme.of(context);
    final isFull = score >= 95;
    final color = isFull
        ? Colors.greenAccent
        : score >= 60
            ? Colors.orangeAccent
            : Colors.redAccent;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: score / 100.0,
                        strokeWidth: 6,
                        backgroundColor: color.withValues(alpha: 0.15),
                        color: color,
                      ),
                    ),
                    Text(
                      '$score%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFull
                            ? 'System Shield 100% Ready'
                            : score >= 60
                                ? 'Protection Partially Enabled'
                                : 'Action Required for Protection',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFull
                            ? 'All 8 telephony, SMS, notification, and system capabilities are granted.'
                            : '${provider.missingRequired.length} required capability permissions are missing.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (provider.missingRequired.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.bolt),
                  label: const Text('Grant All Missing Required'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () => provider.requestAllMissingRequired(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityTile(
    BuildContext context,
    PermissionsProvider provider,
    PermissionCapabilityId id,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final contract = PermissionSnapshot.contracts.firstWhere((c) => c.id == id);
    final isGranted = provider.snapshot.isCapabilityGranted(id);
    final isRequired = contract.priority == PermissionPriority.required;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isGranted
              ? Colors.green.withValues(alpha: 0.2)
              : isRequired
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isGranted
              ? Colors.green.withValues(alpha: 0.15)
              : isRequired
                  ? Colors.red.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
          child: Icon(
            icon,
            size: 20,
            color: isGranted
                ? Colors.greenAccent
                : isRequired
                    ? Colors.redAccent
                    : Colors.orangeAccent,
          ),
        ),
        title: Text(
          contract.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isGranted ? contract.grantedDetail : contract.degradedDetail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isGranted ? Colors.greenAccent : (isRequired ? Colors.redAccent : Colors.orangeAccent),
          ),
        ),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(60, 32),
                ),
                onPressed: () => provider.requestCapability(id),
                child: const Text('Grant'),
              ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why CallShield requires this:',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                contract.whyNeeded,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (!isGranted) ...[
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.orangeAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        contract.recoveryHint,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.orangeAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (id == PermissionCapabilityId.postNotifications)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_active_outlined, size: 16),
                      label: const Text('Direct Open App Notification Settings'),
                      onPressed: () => provider.openNotificationSettings(),
                    ),
                  )
                else if (id == PermissionCapabilityId.notificationAccess)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Direct Open Notification Access Settings'),
                      onPressed: () => provider.openNotificationListenerSettings(),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Direct Open App Settings'),
                      onPressed: () => provider.openAppSettings(),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zero-Knowledge Privacy Commitment',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'CallShield processes your call logs, contacts, messages, and notifications entirely on your device. Your data never leaves your phone unless you explicitly submit a spam number report.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
