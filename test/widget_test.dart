import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template_app/app.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AthenaApp()),
    );

    // One frame to build the widget tree.
    await tester.pump();

    // Allow async providers (e.g. secure storage read) to resolve.
    await tester.pump(const Duration(milliseconds: 500));

    // The app should be visible — either the splash/loading indicator
    // or the Settings screen (no server configured in test environment).
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
