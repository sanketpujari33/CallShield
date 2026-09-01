import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../domain/models/device_scan_models.dart';
import '../../state/protection_provider.dart';
import '../../state/scanner_provider.dart';
import '../../widgets/signal_card.dart';

class DeviceScannerScreen extends StatefulWidget {
  const DeviceScannerScreen({super.key});

  @override
  State<DeviceScannerScreen> createState() => _DeviceScannerScreenState();
}

class _DeviceScannerScreenState extends State<DeviceScannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pipeline = context.read<ProtectionProvider>().pipeline;
      context.read<ScannerProvider>().runScan(DeviceScanType.call, pipeline);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerProvider>();
    final protection = context.read<ProtectionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Scanner & Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_rounded),
            tooltip: 'Sync & Contribute Spam to Server',
            onPressed: scanner.isSyncing
                ? null
                : () async {
                    final count = await scanner.syncSpamToServer();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(count > 0
                              ? 'Contributed $count spam reports to server!'
                              : 'All spam reports are up to date with server.'),
                          backgroundColor: SignalLedgerTheme.green,
                        ),
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan',
            onPressed: scanner.isScanning
                ? null
                : () => scanner.runScan(scanner.currentType, protection.pipeline),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scan Type Tabs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: DeviceScanType.values.map((type) {
                final isSelected = scanner.currentType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? SignalLedgerTheme.cyan : theme.colorScheme.surface,
                        foregroundColor: isSelected ? Colors.black : theme.colorScheme.onSurface,
                        elevation: isSelected ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? SignalLedgerTheme.cyan : theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => scanner.runScan(type, protection.pipeline),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(type.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(type.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Metrics Stat Cards ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildStatCard('Scanned', scanner.summary.totalScanned.toString(), Colors.blueGrey),
                const SizedBox(width: 8),
                _buildStatCard('Spam/Scam', scanner.summary.spamCount.toString(), SignalLedgerTheme.red),
                const SizedBox(width: 8),
                _buildStatCard('Marketing', scanner.summary.marketingCount.toString(), SignalLedgerTheme.amber),
                const SizedBox(width: 8),
                _buildStatCard('Normal', scanner.summary.normalCount.toString(), SignalLedgerTheme.green),
              ],
            ),
          ),

          // ── Filter Chips Bar ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ScanFilter.values.map((filter) {
                final selected = scanner.currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: selected,
                    selectedColor: SignalLedgerTheme.cyan.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: selected ? SignalLedgerTheme.cyan : Colors.transparent,
                    ),
                    onSelected: (_) => scanner.setFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Status Indicator Bar ──
          if (scanner.isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(color: SignalLedgerTheme.cyan),
            )
          else if (scanner.statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  scanner.statusMessage!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 4),

          // ── Items List ──
          Expanded(
            child: scanner.items.isEmpty
                ? Center(
                    child: Text(
                      scanner.isScanning ? 'Analyzing records...' : 'No matching records found in this category',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: scanner.items.length,
                    itemBuilder: (ctx, i) {
                      final item = scanner.items[i];
                      return _buildItemCard(context, item, scanner);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, DeviceScanItem item, ScannerProvider scanner) {
    Color verdictColor;
    IconData verdictIcon;

    switch (item.verdict) {
      case DeviceScanVerdict.spam:
        verdictColor = SignalLedgerTheme.red;
        verdictIcon = Icons.gpp_bad_rounded;
        break;
      case DeviceScanVerdict.marketing:
        verdictColor = SignalLedgerTheme.amber;
        verdictIcon = Icons.campaign_rounded;
        break;
      case DeviceScanVerdict.normal:
        verdictColor = SignalLedgerTheme.green;
        verdictIcon = Icons.verified_user_rounded;
        break;
    }

    return SignalCard(
      borderColor: verdictColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: verdictColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(verdictIcon, color: verdictColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    if (item.number != item.displayName)
                      Text(
                        item.number,
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: verdictColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.verdict.label,
                  style: TextStyle(
                    color: verdictColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.snippet,
            style: const TextStyle(fontSize: 12, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13, color: verdictColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.matchReason,
                  style: TextStyle(fontSize: 11, color: verdictColor, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                DateFormat('MMM d, h:mm a').format(item.timestamp),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: item.number));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Number copied to clipboard')),
                  );
                },
              ),
              if (item.isSpam || item.isMarketing)
                TextButton.icon(
                  icon: const Icon(Icons.block_rounded, size: 14, color: SignalLedgerTheme.red),
                  label: const Text('Block', style: TextStyle(fontSize: 11, color: SignalLedgerTheme.red)),
                  onPressed: () async {
                    await scanner.blockItem(item);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.number} added to Blocklist')),
                      );
                    }
                  },
                ),
              if (item.isNormal)
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 14, color: SignalLedgerTheme.green),
                  label: const Text('Whitelist', style: TextStyle(fontSize: 11, color: SignalLedgerTheme.green)),
                  onPressed: () async {
                    await scanner.whitelistItem(item);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.number} added to Whitelist')),
                      );
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
