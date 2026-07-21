import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_auction/main.dart';

void main() {
  testWidgets('App launch test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LiveAuctionApp(),
      ),
    );
    expect(find.byType(LiveAuctionApp), findsOneWidget);
  });
}
