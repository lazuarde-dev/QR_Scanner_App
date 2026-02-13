import 'package:flutter/material.dart';
import 'package:qr_scanner_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color deepGreen = const Color(0xFF1B4332); 
  final Color softPink = const Color(0xFFFFD1DC); 
  final Color accentPink = const Color(0xFFF48FB1);

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created! Please login."), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: deepGreen, size: 20), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text("Join Us,", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: deepGreen, letterSpacing: -1)),
                Text("Create an account to start scanning.", style: TextStyle(fontSize: 16, color: deepGreen.withOpacity(0.6))),
                const SizedBox(height: 40),
                _buildTextField(label: "FULL NAME", controller: _nameController, hint: "John Doe", icon: Icons.person_outline),
                const SizedBox(height: 25),
                _buildTextField(label: "EMAIL ADDRESS", controller: _emailController, hint: "hello@gmail.com", icon: Icons.alternate_email_rounded),
                const SizedBox(height: 25),
                _buildTextField(
                  label: "PASSWORD", 
                  controller: _passwordController, 
                  hint: "••••••••", 
                  icon: Icons.lock_outline_rounded, 
                  isPassword: true, 
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepGreen, foregroundColor: softPink, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading ? CircularProgressIndicator(color: softPink) : const Text("Create Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Member already? ", style: TextStyle(color: deepGreen.withOpacity(0.5))),
                    GestureDetector(onTap: () => Navigator.pop(context), child: Text("Log in", style: TextStyle(color: accentPink, fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, bool obscure = false, VoidCallback? onToggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: deepGreen.withOpacity(0.4))),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: deepGreen, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: deepGreen.withOpacity(0.2), fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: deepGreen, size: 20),
            suffixIcon: isPassword ? IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: accentPink, size: 20), onPressed: onToggle) : null,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: deepGreen.withOpacity(0.1))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentPink, width: 2)),
          ),
          validator: (value) => value!.isEmpty ? "Required" : (isPassword && value.length < 6 ? "Min 6 chars" : null),
        ),
      ],
    );
  }
}