import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tupas_mobile/main.dart';
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
}
