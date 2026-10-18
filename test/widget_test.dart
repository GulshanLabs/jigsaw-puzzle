// Basic smoke test for the Jigsaw Puzzle app.

import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(JigsawPuzzleApp(sharedPreferences: prefs));
    await tester.pump();

    // Verify the photo source selection screen is shown.
    expect(find.text('Take a Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
  });
}
