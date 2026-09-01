import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/signal_ledger_theme.dart';
import '../../../domain/models/smart_sms_models.dart';
import '../../widgets/signal_card.dart';

class SmartSmsInboxScreen extends StatefulWidget {
  const SmartSmsInboxScreen({super.key});

  @override
  State<SmartSmsInboxScreen> createState() => _SmartSmsInboxScreenState();
}

class _SmartSmsInboxScreenState extends State<SmartSmsInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<SmartSmsMessage> _messages = [
    // Personal
    SmartSmsMessage(
      id: '1',
      sender: 'Mom (+1 415 555 9281)',
      body: 'Hi sweetie, let us know when you arrive home for dinner tonight!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      category: SmsCategory.personal,
    ),
    SmartSmsMessage(
      id: '2',
      sender: 'Alex Developer',
      body: 'Can you review the PR on GitHub when you have a moment?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      category: SmsCategory.personal,
    ),

    // Transactions / OTPs
    SmartSmsMessage(
      id: '3',
      sender: 'CHASE-BANK',
      body: 'Your Chase Online Security verification code is 849201. Valid for 10 minutes. Do not share this code with anyone.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      category: SmsCategory.transactions,
      otpCode: '849201',
    ),
    SmartSmsMessage(
      id: '4',
      sender: 'HDFC-ALERT',
      body: 'Rs. 4,250.00 spent on your HDFC Bank Card ending 9102 at SWIGGY FOODS. Available balance: Rs. 84,120.00.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      category: SmsCategory.transactions,
    ),
    SmartSmsMessage(
      id: '5',
      sender: 'UBER-AUTH',
      body: 'Your Uber login OTP is 3910. Never give this code to your driver.',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      category: SmsCategory.transactions,
      otpCode: '3910',
    ),

    // Promotions
    SmartSmsMessage(
      id: '6',
      sender: 'DOMINOS-PIZZA',
      body: 'Craving cheesy goodness? Flat 50% OFF on all gourmet pizzas today! Use code CHEESE50 at checkout: https://dominos.app/deal',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      category: SmsCategory.promotions,
      extractedUrl: 'https://dominos.app/deal',
    ),
    SmartSmsMessage(
      id: '7',
      sender: 'AMAZON-DEALS',
      body: 'Great Indian Festival is live! Up to 70% off on Smart Electronics and Laptops. Shop before midnight.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      category: SmsCategory.promotions,
      extractedUrl: 'https://amazon.com/deals',
    ),

    // Spam & Fraud
    SmartSmsMessage(
      id: '8',
      sender: '+1 (800) 412-9981',
      body: 'USPS Notice: Your parcel #US948192 is on hold due to unpaid customs fee of \$1.99. Pay immediately to avoid return: http://usps-parcel-redelivery-fee.ru/pay',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      category: SmsCategory.spam,
      extractedUrl: 'http://usps-parcel-redelivery-fee.ru/pay',
      isPhishing: true,
    ),
    SmartSmsMessage(
      id: '9',
      sender: 'TAX-REFUND-ALERT',
      body: 'INTERNAL REVENUE: You have an unclaimed tax rebate of \$1,480.00. Click here to confirm bank deposit info: https://irs-tax-refund-portal.cc',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      category: SmsCategory.spam,
      extractedUrl: 'https://irs-tax-refund-portal.cc',
      isPhishing: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _deleteSpam() {
    setState(() {
      _messages.removeWhere((m) => m.category == SmsCategory.spam);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All Spam & Phishing SMS cleaned!')),
    );
  }

  void _copyOtp(String otp) {
    Clipboard.setData(ClipboardData(text: otp));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP $otp copied to clipboard!'),
        backgroundColor: SignalLedgerTheme.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart SMS & Fraud Shield'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'Clean Spam SMS',
            onPressed: _deleteSpam,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: SignalLedgerTheme.cyan,
          labelColor: SignalLedgerTheme.cyan,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Personal (${_countCategory(SmsCategory.personal)})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Transactions (${_countCategory(SmsCategory.transactions)})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Promotions (${_countCategory(SmsCategory.promotions)})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  Text('Spam (${_countCategory(SmsCategory.spam)})', style: const TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessageList(SmsCategory.personal),
          _buildMessageList(SmsCategory.transactions),
          _buildMessageList(SmsCategory.promotions),
          _buildMessageList(SmsCategory.spam),
        ],
      ),
    );
  }

  int _countCategory(SmsCategory cat) {
    return _messages.where((m) => m.category == cat).length;
  }

  Widget _buildMessageList(SmsCategory category) {
    final list = _messages.where((m) => m.category == category).toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No messages in ${category.label}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final msg = list[index];
        return SignalCard(
          padding: const EdgeInsets.all(14),
          borderColor: msg.isPhishing ? SignalLedgerTheme.red.withValues(alpha: 0.5) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header line: Sender + Category + Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: _getCategoryColor(category).withValues(alpha: 0.2),
                          child: Icon(_getCategoryIcon(category), color: _getCategoryColor(category), size: 14),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            msg.sender,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(msg.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Message Body
              Text(
                msg.body,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),

              // OTP Chip
              if (msg.otpCode != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SignalLedgerTheme.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SignalLedgerTheme.green.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.key_rounded, size: 14, color: SignalLedgerTheme.green),
                          const SizedBox(width: 6),
                          Text(
                            'OTP: ${msg.otpCode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: SignalLedgerTheme.green,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _copyOtp(msg.otpCode!),
                      icon: const Icon(Icons.copy_rounded, size: 12),
                      label: const Text('Copy OTP', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],

              // Phishing / Scam Alert Box
              if (msg.isPhishing) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SignalLedgerTheme.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SignalLedgerTheme.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: SignalLedgerTheme.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🚨 Phishing Link Intercepted: ${msg.extractedUrl ?? "Malicious URL"}. Do not open or provide card details.',
                          style: const TextStyle(color: SignalLedgerTheme.red, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getCategoryColor(SmsCategory cat) {
    switch (cat) {
      case SmsCategory.personal:
        return SignalLedgerTheme.cyan;
      case SmsCategory.transactions:
        return SignalLedgerTheme.green;
      case SmsCategory.promotions:
        return SignalLedgerTheme.amber;
      case SmsCategory.spam:
        return SignalLedgerTheme.red;
    }
  }

  IconData _getCategoryIcon(SmsCategory cat) {
    switch (cat) {
      case SmsCategory.personal:
        return Icons.person_rounded;
      case SmsCategory.transactions:
        return Icons.account_balance_rounded;
      case SmsCategory.promotions:
        return Icons.local_offer_rounded;
      case SmsCategory.spam:
        return Icons.gpp_bad_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
