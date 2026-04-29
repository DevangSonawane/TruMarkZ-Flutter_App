// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trumarkz/main.dart';
import 'package:trumarkz/core/theme/theme_controller.dart';

void main() {
  testWidgets('App boots and auto-navigates to onboarding', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ThemeController controller = await ThemeController.create();
    await tester.pumpWidget(
      TickerMode(enabled: false, child: TruMarkZApp(themeController: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Get Started'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
