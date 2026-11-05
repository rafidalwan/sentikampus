import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('SentiKampus menampilkan halaman utama',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SentiKampusApp());
    expect(find.text('SentiKampus'), findsOneWidget);
    expect(find.text('Analisis Sentimen Kampus'), findsOneWidget);
    expect(find.text('Analisis Sentimen'), findsOneWidget);
  });
}
