// Basic Flutter widget test for Cloak app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloak/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CloakApp(),
      ),
    );

    // Verify that the app title is shown
    expect(find.text('Cloak'), findsOneWidget);
  });
}
