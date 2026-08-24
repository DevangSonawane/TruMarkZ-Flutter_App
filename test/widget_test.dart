import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trumarkz/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  testWidgets('Onboarding page renders the primary CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
  });
}
