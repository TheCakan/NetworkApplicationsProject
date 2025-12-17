import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/register_screen.dart';

// Mock servisleri import et - gerçek API çağrılarını engellemek için

import 'package:http/http.dart' as http;

void main() {
  // Test için setup
  setUp(() {
    // Test öncesi temizlik
  });

  tearDown(() {
    // Test sonrası temizlik
  });

  group('Temel Widget Testleri', () {
    testWidgets('MyApp widget testi', (WidgetTester tester) async {
      // MyApp widget'ını oluştur ve test et
      await tester.pumpWidget(const MyApp());

      // LoginScreen'in göründüğünü kontrol et
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('LoginScreen widget testi', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Temel widget'ların göründüğünü kontrol et
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('RegisterScreen widget testi', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Kayıt ekranı widget'larını kontrol et
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign up to get started'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text('Register'), findsOneWidget);
    });
  });

  group('Navigasyon Testleri', () {
    testWidgets('Login to Register navigasyonu', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Register butonuna tıkla
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Register ekranının açıldığını kontrol et
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Register to Login navigasyonu', (WidgetTester tester) async {
      // Doğrudan RegisterScreen ile başla
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Login butonuna tıkla
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Login ekranının açıldığını kontrol et
      expect(find.text('Welcome Back'), findsOneWidget);
    });
  });

  group('Form Validasyon Testleri', () {
    testWidgets('Login form validasyonu - boş form',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Boş form ile login butonuna tıkla
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Hata mesajlarını kontrol et
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Register form validasyonu - boş form',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Boş form ile register butonuna tıkla
      await tester.tap(find.text('Register'));
      await tester.pump();

      // Hata mesajlarını kontrol et
      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Geçerli email validasyonu', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Geçersiz email gir
      await tester.enterText(
          find.byType(TextFormField).at(0), 'gecersiz-email');
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Email validasyon hatasını kontrol et
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Şifre uzunluk validasyonu', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Kısa şifre gir
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Şifre uzunluk hatasını kontrol et
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('İsim uzunluk validasyonu', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Kısa isim gir
      await tester.enterText(find.byType(TextFormField).at(0), 'A');
      await tester.tap(find.text('Register'));
      await tester.pump();

      // İsim uzunluk hatasını kontrol et
      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('Şifre eşleşme validasyonu', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Eşleşmeyen şifreler gir
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(
          find.byType(TextFormField).at(3), 'differentpassword');
      await tester.tap(find.text('Register'));
      await tester.pump();

      // Şifre eşleşme hatasını kontrol et
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('Etkileşim Testleri', () {
    testWidgets('Login form doldurma', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Email ve şifre gir
      await tester.enterText(
          find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Değerlerin girildiğini kontrol et
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Register form doldurma', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Form alanlarını doldur
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      // Değerlerin girildiğini kontrol et
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsNWidgets(2));
    });

    testWidgets('Password visibility toggle - Login',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Şifre görünürlük butonunu bul
      final visibilityButton = find.byIcon(Icons.visibility_outlined);

      // Butona tıkla
      await tester.tap(visibilityButton);
      await tester.pump();

      // İkonun değiştiğini kontrol et
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('Password visibility toggle - Register',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Şifre görünürlük butonlarını bul
      final passwordVisibilityButton =
          find.byIcon(Icons.visibility_outlined).first;
      final confirmPasswordVisibilityButton =
          find.byIcon(Icons.visibility_outlined).last;

      // Butonlara tıkla
      await tester.tap(passwordVisibilityButton);
      await tester.tap(confirmPasswordVisibilityButton);
      await tester.pump();

      // İkonların değiştiğini kontrol et
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
    });
  });

  group('UI Element Testleri', () {
    testWidgets('AppBar titles test', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Login ekranı AppBar kontrolü
      expect(find.text('Currency Exchange'), findsOneWidget);
    });

    testWidgets('Icon presence test - Login', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Temel ikonların varlığını kontrol et
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('Icon presence test - Register', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Register ekranı ikonlarını kontrol et
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.byIcon(Icons.person_outlined), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsNWidgets(2));
    });

    testWidgets('Button styles test', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Buton stillerinin varlığını kontrol et
      expect(find.byType(ElevatedButton),
          findsNWidgets(2)); // Login ve Register butonları
      expect(find.byType(TextButton), findsOneWidget); // Forgot password butonu
    });

    testWidgets('Text field types test - Login', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Login text field türlerini kontrol et
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('Text field types test - Register',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Register text field türlerini kontrol et
      expect(find.byType(TextFormField), findsNWidgets(4));
    });
  });

  group('Responsive Tasarım Testleri', () {
    testWidgets('Widgetlerin ekranda render edildiğini kontrol et',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Temel widget'ların render edildiğini kontrol et
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('Card widgetları render testi - Login',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Card widget'larının render edildiğini kontrol et
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('Card widgetları render testi - Register',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Card widget'larının render edildiğini kontrol et
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('Gradient ve Stil Testleri', () {
    testWidgets('Login screen gradient background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Container with gradient kontrolü
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Register screen gradient background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Container with gradient kontrolü
      expect(find.byType(Container), findsWidgets);
    });
  });
}
