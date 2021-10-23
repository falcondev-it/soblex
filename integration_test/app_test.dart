import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:soblex_ios/main.dart' as app;
import 'package:soblex_ios/widget_offline.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('Start writing when App opens', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      // Oder
      // await tester.pumpWidget(MyApp());

      // Is the Offline Page displayed
      expect(find.byType(OfflinePage), findsOneWidget);

      // Searchinput desiplayed?
      expect(find.byType(TextField), findsOneWidget);

      // keine ergebnisse
      expect(find.text('Suchbegriff eingeben!'), findsOneWidget);

      // Input this text
      final inputText = 'Haus';
      await tester.enterText(find.byKey(Key('inputText')), inputText);

      await tester.pumpAndSettle();
      // viele Listenelemente
      expect(find.byType(Html), findsWidgets);

      // Input this text with weird upper and lowercase
      await tester.enterText(find.byKey(Key('inputText')), "hausBoot");

      await tester.pumpAndSettle();
      // ein Ergebniss
      expect(find.byType(Html), findsOneWidget);

      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap on Clear - Clear Textinput
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Leere Suchbar
      expect(find.text('Suchbegriff eingeben!'), findsOneWidget);

      // Input this text that is not defined
      await tester.enterText(find.byKey(Key('inputText')), "hausBoote");

      await tester.pumpAndSettle();
      // ein Ergebniss
      expect(find.byType(Html), findsNothing);

      // find.byElementType(TextField)
    });
  });
}
