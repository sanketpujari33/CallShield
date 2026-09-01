import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:callshield_app/app.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('CallShield app launches OnboardingWizardScreen on first run', (WidgetTester tester) async {
    await tester.pumpWidget(const CallShieldApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Onboarding Wizard renders on first launch
    expect(find.text('CallShield Setup'), findsOneWidget);
    expect(find.text('100% On-Device Protection'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
