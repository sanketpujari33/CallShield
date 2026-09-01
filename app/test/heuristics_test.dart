import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/data/heuristics/spam_heuristics.dart';

void main() {
  group('SpamHeuristics', () {
    final heuristics = SpamHeuristics.instance;

    test('detects neighbor spoofing (same NPA + NXX)', () {
      final isSpoof = heuristics.isNeighborSpoof('+12123459999', '+12123451111');
      expect(isSpoof, isTrue);

      final notSpoof = heuristics.isNeighborSpoof('+14155551234', '+12123451111');
      expect(notSpoof, isFalse);

      final sameNumber = heuristics.isNeighborSpoof('+12123451111', '+12123451111');
      expect(sameNumber, isFalse); // Calling oneself is not a spoof detection
    });

    test('detects toll-free numbers', () {
      expect(heuristics.isTollFree('+18001234567'), isTrue);
      expect(heuristics.isTollFree('+18881234567'), isTrue);
      expect(heuristics.isTollFree('+12127365000'), isFalse);
    });

    test('detects Caribbean Wangiri scams', () {
      expect(heuristics.isCaribbeanWangiri('+18091234567'), isTrue); // Dominican Republic
      expect(heuristics.isCaribbeanWangiri('+18761234567'), isTrue); // Jamaica
      expect(heuristics.isCaribbeanWangiri('+12127365000'), isFalse); // Manhattan
    });

    test('detects International Wangiri scams', () {
      expect(heuristics.isInternationalWangiri('+2321234567'), isTrue); // Sierra Leone
      expect(heuristics.isInternationalWangiri('+2221234567'), isTrue); // Mauritania
      expect(heuristics.isInternationalWangiri('+12127365000'), isFalse);
    });

    test('evaluates comprehensive heuristics score and signals', () {
      final eval = heuristics.evaluate('+12123459999', userNumber: '+12123451111');
      expect(eval.isSpam, isTrue);
      expect(eval.reasons, contains('neighbor_spoof'));
    });
  });
}
