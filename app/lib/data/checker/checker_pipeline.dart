import '../../domain/models/caller_identity.dart';
import '../../domain/models/spam_check_result.dart';
import 'i_checker.dart';

class CheckerPipeline {
  final List<IChecker> _checkers;

  CheckerPipeline(List<IChecker> checkers)
      : _checkers = List.of(checkers)..sort((a, b) => b.priority.compareTo(a.priority));

  List<IChecker> get checkers => List.unmodifiable(_checkers);

  Future<SpamCheckResult?> run(
    CallerIdentity identity,
    DateTime timestamp, {
    String? messageBody,
  }) async {
    for (final checker in _checkers) {
      try {
        final result = await checker.check(identity, timestamp, messageBody: messageBody);
        if (result != null) {
          return result;
        }
      } catch (e) {
        // Individual layer fault tolerance: continue to next layer
        continue;
      }
    }
    return null;
  }
}
