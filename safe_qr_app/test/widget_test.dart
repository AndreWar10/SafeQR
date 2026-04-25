import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safe_qr_app/shared/presentation/widgets/app_hero_header.dart';

void main() {
  testWidgets('AppHeroHeader apresenta título e subtítulo', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppHeroHeader(title: 'Título de teste', subtitle: 'Subtítulo de teste'),
        ),
      ),
    );

    expect(find.text('Título de teste'), findsOneWidget);
    expect(find.text('Subtítulo de teste'), findsOneWidget);
  });
}
