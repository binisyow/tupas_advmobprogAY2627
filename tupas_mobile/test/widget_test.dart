import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tupas_mobile/main.dart';
import 'package:tupas_mobile/screens/profile_screen.dart';
import 'package:tupas_mobile/screens/signin_screen.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const TupasAdvMobProg());
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('combined login accepts one username-or-email field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => const MaterialApp(home: SigninScreen()),
      ),
    );

    expect(find.byType(SegmentedButton), findsNothing);
    expect(find.text('Username or email'), findsOneWidget);
  });

  testWidgets('saving the profile username closes its dialog cleanly', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'id': 1,
      'username': 'vince',
      'email': 'vince@example.com',
      'firstName': 'Vince',
      'lastName': 'Tupas',
      'loginType': 'dummyJson',
    });

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) =>
            const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit username'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Update username'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
