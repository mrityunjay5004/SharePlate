import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zero_waste_food/main.dart';

void main() {
  testWidgets('SharePlate app starts in demo mode with branding and tagline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SharePlateApp()));

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('SharePlate'), findsAtLeastNWidgets(1));
    expect(find.text('Share More. Waste Less.'), findsAtLeastNWidgets(1));
  });
}
