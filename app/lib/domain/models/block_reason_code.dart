enum BlockReasonCode {
  userBlocklist('user_blocklist', 'Personal Blocklist'),
  temporaryBlock('temporary_block', 'Temporary Block'),
  database('database', 'Spam Database'),
  dbPrefixExpansion('db_prefix_expansion', 'Database Prefix'),
  prefixRule('prefix_rule', 'Premium / Wangiri Prefix'),
  wildcard('wildcard', 'Pattern / Wildcard Rule'),
  rangePattern('range_pattern', 'Length-Locked Range'),
  temporaryAllow('temporary_allow', 'Temporary Allow'),
  manualWhitelist('manual_whitelist', 'Personal Whitelist'),
  contactWhitelist('contact_whitelist', 'Phone Contact'),
  contactsOnly('contacts_only', 'Contacts-Only Mode'),
  stirShakenFailed('stir_shaken_failed', 'STIR/SHAKEN Failed'),
  stirShakenAuthenticated('stir_shaken_authenticated', 'STIR/SHAKEN Verified'),
  systemBlocklist('system_blocklist', 'System Block List'),
  recentlyDialed('recently_dialed', 'Recently Dialed'),
  emergencyCallback('emergency_callback', 'Emergency Callback'),
  answeredCaller('answered_caller', 'Answered Caller'),
  repeatedUrgent('repeated_urgent', 'Repeated Urgent Call'),
  callerNameTrust('caller_name_trust', 'Trusted Caller Name'),
  callerNameRule('caller_name_rule', 'Caller Name Rule'),
  pushAlert('push_alert', 'Push Alert Bridge'),
  regionRule('region_rule', 'Region Block Rule'),
  quietHours('quiet_hours', 'Quiet Hours Schedule'),
  frequencyAutoBlock('frequency_auto_block', 'High Frequency Auto-Block'),
  heuristic('heuristic', 'Heuristic Detection'),
  campaignBurst('campaign_burst', 'Campaign Burst Flood'),
  mlScorer('ml_scorer', 'Machine Learning Model'),
  smsKeyword('sms_keyword', 'SMS Keyword Block'),
  smsContextTrust('sms_context_trust', 'SMS Context Trust'),
  smsBurst('sms_burst', 'SMS Burst Flood'),
  smsContent('sms_content', 'SMS Phishing / Spam Content'),
  unknown('unknown', 'Unknown');

  final String key;
  final String displayName;

  const BlockReasonCode(this.key, this.displayName);

  static BlockReasonCode fromKey(String? key) {
    if (key == null) return BlockReasonCode.unknown;
    for (final code in BlockReasonCode.values) {
      if (code.key == key) return code;
    }
    return BlockReasonCode.unknown;
  }
}
