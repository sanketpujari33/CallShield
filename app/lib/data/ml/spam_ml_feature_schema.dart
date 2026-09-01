class SpamMLFeatureSchema {
  static const int version = 1;

  static const List<String> featureNames = [
    'toll_free',
    'high_spam_npa',
    'voip_range',
    'repeated_digits_ratio',
    'sequential_asc_ratio',
    'all_same_digit',
    'nxx_555',
    'last4_zero',
    'invalid_nxx',
    'subscriber_all_same',
    'alternating_pattern',
    'sequential_desc_ratio',
    'nxx_below_200',
    'low_digit_entropy',
    'subscriber_sequential',
    'time_of_day_sin',
    'time_of_day_cos',
    'geographic_distance',
    'short_number',
    'plus_one_prefix',
  ];
}
