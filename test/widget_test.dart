
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_quest/main.dart';

void main() {
  testWidgets('Cloud Quest app initializes', (tester) async {
    expect(const CloudQuestApp(), isNotNull);
  });
}
