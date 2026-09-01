import '../../domain/models/caller_identity.dart';
import '../../domain/models/spam_check_result.dart';

abstract class IChecker {
  int get priority;
  String get name;

  Future<SpamCheckResult?> check(
    CallerIdentity identity,
    DateTime timestamp, {
    String? messageBody,
  });
}
