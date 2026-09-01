import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/data/ml/spam_ml_scorer.dart';
import 'package:callshield_app/data/ml/spam_ml_feature_schema.dart';

void main() {
  group('SpamMLScorer', () {
    late SpamMLScorer scorer;

    setUp(() {
      scorer = SpamMLScorer();
    });

    test('extracts exactly 20 features matching contract', () {
      final features = scorer.extractFeatures('+18005551234', 14);
      expect(features.length, equals(20));
      expect(features.length, equals(SpamMLFeatureSchema.featureNames.length));

      // Toll free (800) -> features[0] == 1.0
      expect(features[0], equals(1.0));
      // 555 exchange -> features[6] == 1.0
      expect(features[6], equals(1.0));
      // Plus one prefix -> features[19] == 1.0
      expect(features[19], equals(1.0));
    });

    test('alternating pattern feature extraction', () {
      // 5050505050 -> alternating even=5 and odd=0
      final features = scorer.extractFeatures('5050505050', 12);
      expect(features[10], equals(1.0)); // alternating_pattern
    });

    test('sequential ascending run feature extraction', () {
      // 1234567890 -> seqAscRatio == 8 / 9
      final features = scorer.extractFeatures('1234567890', 12);
      expect(features[4], closeTo(8.0 / 9.0, 0.001)); // sequential_asc_ratio
    });

    test('loads bundled weights JSON and evaluates GBDT tree ensemble', () {
      final weightsFile = File('assets/data/spam_model_weights.json');
      if (weightsFile.existsSync()) {
        final jsonStr = weightsFile.readAsStringSync();
        final ok = scorer.loadFromJson(jsonStr);
        expect(ok, isTrue);
        expect(scorer.health, equals(ModelHealth.gbtActive));

        // Score spam robocall pattern vs clean pattern
        final spamScore = scorer.score('+18005551234', 14);
        expect(spamScore, inInclusiveRange(0.0, 1.0));

        final cleanScore = scorer.score('+12127365000', 14);
        expect(cleanScore, inInclusiveRange(0.0, 1.0));
      }
    });

    test('health defaults when no valid model JSON is provided', () {
      final ok = scorer.loadFromJson('invalid json');
      expect(ok, isFalse);
      expect(scorer.health, equals(ModelHealth.parseFailed));
    });
  });
}
