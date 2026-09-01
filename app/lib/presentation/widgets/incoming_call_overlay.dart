import 'package:flutter/material.dart';
import '../../domain/models/caller_identity_models.dart';

class IncomingCallOverlay extends StatelessWidget {
  final CallerIdentity caller;
  final VoidCallback? onClose;
  final VoidCallback? onBlock;
  final VoidCallback? onViewDetails;

  const IncomingCallOverlay({
    super.key,
    required this.caller,
    this.onClose,
    this.onBlock,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final cardBgColor = _getCardColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24), // Dark header container
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top Header Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Incoming Call',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'callshield ai',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Vibrant Caller Details Card ──
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 6, right: 6, bottom: 6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with Avatar, Title, Number, and Close button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Icon
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Icon(
                        _getAvatarIcon(),
                        color: cardBgColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title & Number info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  caller.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (caller.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${caller.formattedNumber} • ${caller.location}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close "X" Button
                    if (onClose != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        onPressed: onClose,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Big Highlight Context Message
                Text(
                  caller.highlightMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 14),

                // Metadata Chips & Quick Action Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        caller.categoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (onViewDetails != null)
                      InkWell(
                        onTap: onViewDetails,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: const Row(
                            children: [
                              Text(
                                'Full Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCardColor() {
    switch (caller.type) {
      case CallerType.verifiedDelivery:
        return const Color(0xFF00A843); // Vibrant Green (matching screenshot)
      case CallerType.verifiedBusiness:
        return const Color(0xFF00897B); // Teal Green
      case CallerType.personalContact:
        return const Color(0xFF1976D2); // Trust Blue
      case CallerType.telemarketing:
        return const Color(0xFFE65100); // Warning Amber
      case CallerType.scamPhishing:
      case CallerType.spamRobocall:
        return const Color(0xFFD32F2F); // Scam Red
      case CallerType.unknown:
        return const Color(0xFF455A64); // Slate Grey
    }
  }

  IconData _getAvatarIcon() {
    switch (caller.type) {
      case CallerType.verifiedDelivery:
        return Icons.delivery_dining_rounded;
      case CallerType.verifiedBusiness:
        return Icons.business_rounded;
      case CallerType.personalContact:
        return Icons.person_rounded;
      case CallerType.telemarketing:
        return Icons.campaign_rounded;
      case CallerType.scamPhishing:
      case CallerType.spamRobocall:
        return Icons.gpp_bad_rounded;
      case CallerType.unknown:
        return Icons.phone_in_talk_rounded;
    }
  }
}
