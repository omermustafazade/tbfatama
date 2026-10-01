import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // EKLENDİ
import 'home_screen.dart';
import 'register_screen.dart';
import 'referee_home_screen.dart';
import '../models/referee.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black, width: 3)),
        title: const Text("GİZLİ ERİŞİM", style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(hintText: "Gizli Kod", focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 3))),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hatalı Kod!"), backgroundColor: Colors.red));
              }
            },
            child: const Text("ONAYLA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  // FIREBASE AUTH GİRİŞ İŞLEMİ
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if(email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen e-posta ve şifrenizi girin!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth üzerinden şifre ve mail doğrulama
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Başarılı ise Firestore'dan detayları çek
      var userDoc = await FirebaseFirestore.instance.collection('referees').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı verisi sistemde bulunamadı!"), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
        return;
      }

      final user = Referee.fromMap(userDoc.data()!);

      // 3. Rol ve Onay Kontrolleri
      if (user.role == RefereeRole.admin) {
        if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        if (!user.isApproved) {
          await FirebaseAuth.instance.signOut(); // Onaylanmadıysa oturumu geri kapat
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hesabınız henüz onaylanmadı! Yönetici onayı bekleyin."), backgroundColor: Colors.orange));
          setState(() => _isLoading = false);
          return;
        }
        if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RefereeHomeScreen(refereeId: user.id)));
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
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sistemsel Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // YENİ: ŞİFRE SIFIRLAMA E-POSTASI GÖNDERME
  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifresini sıfırlamak istediğiniz E-posta adresini yukarıya yazın!"), backgroundColor: Colors.orange));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre sıfırlama bağlantısı e-postanıza gönderildi! Gelen kutunuzu (veya spam klasörünüzü) kontrol edin."), backgroundColor: Colors.green));
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Sıfırlama işlemi başarısız!";
      if (e.code == 'user-not-found') errorMessage = "Bu e-posta adresi sistemde kayıtlı değil.";
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                  ),
                  child: const Icon(Icons.sports_basketball, size: 70, color: Color(0xFFE65100)),
                ),
              ),
              const SizedBox(height: 24),
              const Text("TBF ATAMA", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const Text("HAKEM YÖNETİM SİSTEMİ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),

              const SizedBox(height: 50),

              _buildInput("E-POSTA ADRESİ", _emailController, false),
              const SizedBox(height: 20),
              _buildInput("ŞİFRE", _passwordController, true, isPasswordField: true),

              const SizedBox(height: 16),

              // ŞİFREMİ UNUTTUM BUTONU
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _resetPassword,
                  child: const Text("Şifremi Unuttum", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, decoration: TextDecoration.underline)),
                ),
              ),

              const SizedBox(height: 40),

              _isLoading
                  ? const CircularProgressIndicator(color: Colors.orange)
                  : InkWell(
                onTap: _login,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2.5),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                  ),
                  child: const Center(
                    child: Text("GİRİŞ YAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Sisteme dahil değil misin? ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen(isAdminRegistration: false))),
                    child: const Text("KAYIT OL", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, decoration: TextDecoration.underline)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, bool isObscure, {bool isPasswordField = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
        const SizedBox(height: 8),
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
              suffixIcon: isPasswordField
                  ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black87),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
                  : null,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 2.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.orange, width: 2.5)),
            ),
          ),
        ),
      ],
    );
  }
}