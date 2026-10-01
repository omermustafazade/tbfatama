import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart'; // Giriş ekranına yönlendiriyoruz

void main() async {
  // Flutter motorunun güvenli bir şekilde başlamasını sağlar
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i yapılandırma dosyasıyla başlatır
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TBFatamaApp());
}

class TBFatamaApp extends StatelessWidget {
  const TBFatamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TBF Atama',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange.shade800),
      home: const LoginScreen(), // Uygulama artık Login ile başlayacak
    );
  }
}