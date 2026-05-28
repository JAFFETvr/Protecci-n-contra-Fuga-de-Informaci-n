import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_dlp/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(fakeGpsDetected: false));

    // Verify that the login screen is shown.
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Accede a tu cuenta de forma segura'), findsOneWidget);
  });
}
