class AppConstants {
  static const String appName = 'CallShield';
  static const String appVersion = '1.7.38';

  // Backend API URLs (Local server default, configurable in settings)
  static const String defaultApiUrl = 'http://10.0.2.2:3000'; // Android emulator host
  static const String defaultDesktopApiUrl = 'http://localhost:3000';

  // Decision priorities (matching original Kotlin engine)
  static const int priorityManualWhitelist = 10000;
  static const int priorityContactWhitelist = 9000;
  static const int priorityContactsOnly = 8800;
  static const int priorityStirShakenFailed = 8500;
  static const int priorityUserBlocklist = 7000;
  static const int prioritySystemBlocklist = 6900;
  static const int priorityWildcardRule = 5500;
  static const int priorityRangePattern = 5400;
  static const int priorityTemporaryAllow = 5350;
  static const int priorityPrefixRule = 5320;
  static const int priorityStirShakenAuthenticated = 5300;
  static const int prioritySpamDatabase = 5200;
  static const int priorityDatabasePrefixExpansion = 5150;
  static const int priorityRecentlyDialed = 5000;
  static const int priorityEmergencyCallback = 4980;
  static const int priorityAnsweredCaller = 4950;
  static const int priorityRepeatedUrgent = 4900;
  static const int priorityCallerNameTrust = 4850;
  static const int priorityPushAlert = 4700;
  static const int prioritySmsContextTrust = 4700;
  static const int prioritySmsBurst = 4650;
  static const int priorityCampaignRecorder = 4500;
  static const int priorityRegionRule = 4300;
  static const int priorityQuietHours = 4000;
  static const int priorityFrequencyAutoBlock = 3500;
  static const int priorityHeuristics = 3000;
  static const int priorityCampaignBurst = 2500;
  static const int priorityCallerNameRule = 2250;
  static const int priorityMlSpamScorer = 2000;
  static const int prioritySmsContent = 1900;
}
