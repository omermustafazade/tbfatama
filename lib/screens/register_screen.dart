import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/referee.dart';

class RegisterScreen extends StatefulWidget {
  final bool isAdminRegistration;
  const RegisterScreen({super.key, this.isAdminRegistration = false});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  RefereeRole _selectedRole = RefereeRole.kosu; // Artık aday yok
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isAdminRegistration) {
      _selectedRole = RefereeRole.admin;
    }
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun!"), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(), password: _passwordController.text.trim(),
      );
      final newRef = Referee(
        id: userCredential.user!.uid, name: _nameController.text.trim(), email: _emailController.text.trim(),
        role: widget.isAdminRegistration ? RefereeRole.admin : _selectedRole,
        level: widget.isAdminRegistration ? 10 : 2, // Yeni kayıtlı hakem minimum gruptan başlar
        isApproved: widget.isAdminRegistration ? true : false,
      );
      await FirebaseFirestore.instance.collection('referees').doc(newRef.id).set(newRef.toMap());
      if(mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isAdminRegistration ? "Yönetici hesabı başarıyla oluşturuldu!" : "Kayıt Başarılı! Yönetici onayı bekleyin.", style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green, duration: const Duration(seconds: 4)));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Kayıt işlemi başarısız!";
      if (e.code == 'weak-password') errorMessage = "Şifre en az 6 karakter olmalıdır.";
      else if (e.code == 'email-already-in-use') errorMessage = "Bu e-posta adresi ile zaten bir hesap var.";
      else if (e.code == 'invalid-email') errorMessage = "Geçersiz e-posta adresi formatı.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.isAdminRegistration ? "YÖNETİCİ KAYDI" : "KAYIT OL", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text(widget.isAdminRegistration ? "Sisteme tam yetki ile dahil olun." : "Sisteme dahil olmak için formu doldur.", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 40),
              _buildInput("AD SOYAD", _nameController, false),
              const SizedBox(height: 20),
              _buildInput("E-POSTA ADRESİ", _emailController, false),
              const SizedBox(height: 20),
              _buildInput("ŞİFRE", _passwordController, true, isPasswordField: true),
              const SizedBox(height: 24),
              if (!widget.isAdminRegistration) ...[
                const Text("TALEP EDİLEN KATEGORİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))], borderRadius: BorderRadius.circular(10), color: Colors.white),
                  child: DropdownButtonFormField<RefereeRole>(
                    value: _selectedRole, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 30),
                    decoration: InputDecoration(filled: true, fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 2.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.orange, width: 2.5))),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                    items: RefereeRole.values.where((r) => r != RefereeRole.admin).map((role) { return DropdownMenuItem(value: role, child: Text(role.name.toUpperCase())); }).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ] else ...[
                const Text("KATEGORİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black, width: 2.5), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]),
                  child: const Row(children: [Icon(Icons.admin_panel_settings, color: Colors.white), SizedBox(width: 12), Text("MASTER ADMİN (TAM YETKİ)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1))]),
                ),
              ],
              const SizedBox(height: 50),
              _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.orange)) : InkWell(
                onTap: _register,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black, width: 2.5), boxShadow: [BoxShadow(color: widget.isAdminRegistration ? Colors.blueGrey : Colors.orange, offset: const Offset(4, 4))]),
                  child: Center(child: Text(widget.isAdminRegistration ? "YÖNETİCİ HESABINI OLUŞTUR" : "KAYDI TAMAMLA", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1))),
                ),
              ),
              const SizedBox(height: 40),
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
          decoration: BoxDecoration(boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))], borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: controller, obscureText: isPasswordField ? !_isPasswordVisible : isObscure, style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white,
              suffixIcon: isPasswordField ? IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black87), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)) : null,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 2.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.orange, width: 2.5)),
            ),
          ),
        ),
      ],
    );
  }
}