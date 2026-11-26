import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'referee_home_screen.dart';
import '../models/referee.dart';
import '../services/demo_seeder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _secretClickCount = 0;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _showSecretAdminDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: const Text("GİZLİ YÖNETİM", style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            hintText: "Gizli Kod",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 3)),
          ),
          keyboardType: TextInputType.number,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (codeController.text == "000002") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen(isAdminRegistration: true)));
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Hatalı Kod!"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("ONAYLA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen e-posta ve şifrenizi girin!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      var userDoc = await FirebaseFirestore.instance.collection('referees').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kullanıcı verisi sistemde bulunamadı!"), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final user = Referee.fromMap(userDoc.data()!);

      if (user.role == RefereeRole.admin) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        if (!user.isApproved) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Hesabınız henüz onaylanmadı. Yönetici onayı bekleyin."), backgroundColor: Colors.orange),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RefereeHomeScreen(refereeId: user.id)));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Giriş başarısız!";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = "E-posta veya şifre hatalı.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Şifre hatalı.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "E-posta formatı geçersiz.";
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sistemsel Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifresini sıfırlamak istediğiniz E-posta adresini yukarıya yazın!"), backgroundColor: Colors.orange),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Şifre sıfırlama bağlantısı e-postanıza gönderildi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Sıfırlama işlemi başarısız!";
      if (e.code == 'user-not-found') errorMessage = "Bu e-posta adresi sistemde kayıtlı değil.";
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    }
  }

  Widget _buildPresentationQuickAccess() {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt, color: Color(0xFFE5A93C), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "CANLI SUNUM & DEMO PANELİ",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
                    SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "18 Hakem & 3 Günlük (10 Maç) Senaryosu",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              await DemoSeeder.seedDemoData(context);
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A9D8F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "1. SUNUM VERİSİNİ YÜKLE & BAŞLAT",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              setState(() => _isLoading = true);
              await DemoSeeder.ensureDemoAuth();
              if (mounted) {
                setState(() => _isLoading = false);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(3, 3))],
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.admin_panel_settings, color: Color(0xFFE5A93C), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "ADMİN PANELİNE GEÇ (ŞİFRESİZ)",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await DemoSeeder.ensureDemoAuth();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RefereeHomeScreen(refereeId: "demo_kosu_1")),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        children: [
                          Text("SKOR GİRİŞ ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black)),
                          SizedBox(height: 2),
                          Text("Ahmet Yılmaz (G5)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await DemoSeeder.ensureDemoAuth();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RefereeHomeScreen(refereeId: "demo_kosu_2")),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        children: [
                          Text("UYGUNLUK VERME", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black)),
                          SizedBox(height: 2),
                          Text("Mehmet Demir (G5)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _secretClickCount++;
                    if (_secretClickCount >= 5) {
                      _secretClickCount = 0;
                      _showSecretAdminDialog();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                    ),
                    child: const Icon(Icons.sports_basketball, size: 54, color: Color(0xFFE65100)),
                  ),
                ),
                const SizedBox(height: 16),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("TBF ATAMA", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                const Text(
                  "HAKEM YÖNETİM SİSTEMİ",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
                ),
                const SizedBox(height: 24),
                _buildInput("E-POSTA ADRESİ", _emailController, false),
                const SizedBox(height: 14),
                _buildInput("ŞİFRE", _passwordController, true, isPasswordField: true),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _resetPassword,
                    child: const Text(
                      "Şifremi Unuttum",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, decoration: TextDecoration.underline, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.orange)
                    : InkWell(
                  onTap: _login,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 2.5),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                    ),
                    child: const Center(
                      child: Text(
                        "GİRİŞ YAP",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
                _buildPresentationQuickAccess(),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text("Sisteme dahil değil misin? ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen(isAdminRegistration: false))),
                      child: const Text(
                        "KAYIT OL",
                        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, decoration: TextDecoration.underline),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, bool isObscure, {bool isPasswordField = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPasswordField ? !_isPasswordVisible : isObscure,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: isPasswordField
                  ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black87),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 2.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.orange, width: 2.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}