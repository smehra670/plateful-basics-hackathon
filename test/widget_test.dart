import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:plateful/main.dart';
import 'package:plateful/widgets/plateful_logo.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Plateful shows onboarding with logo', (WidgetTester tester) async {
    await tester.pumpWidget(const PlatefulApp());
    await tester.pump();

    expect(find.byType(PlatefulLogo), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
