import 'package:flutter/material.dart';
import 'package:qr_scanner_app/auth/register_screen.dart';
import 'package:qr_scanner_app/services/auth_service.dart';
import 'package:qr_scanner_app/views/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Palette Warna Minimalis
  final Color deepGreen = const Color(0xFF1B4332); 
  final Color softPink = const Color(0xFFFFD1DC); 
  final Color accentPink = const Color(0xFFF48FB1);

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: softPink.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded, size: 40, color: deepGreen),
                ),
                const SizedBox(height: 32),
                Text("Welcome back,",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: deepGreen, letterSpacing: -1),
                ),
                const SizedBox(height: 8),
                Text("Log in to manage your tickets.",
                  style: TextStyle(fontSize: 16, color: deepGreen.withOpacity(0.6)),
                ),
                const SizedBox(height: 50),
                _buildTextField(
                  label: "EMAIL ADDRESS",
                  controller: _emailController,
                  hint: "yourname@gmail.com",
                  icon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  label: "PASSWORD",
                  controller: _passwordController,
                  hint: "••••••••",
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepGreen,
                      foregroundColor: softPink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                      ? CircularProgressIndicator(color: softPink) 
                      : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("New here? ", style: TextStyle(color: deepGreen.withOpacity(0.5))),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text("Create Account", style: TextStyle(color: accentPink, fontWeight: FontWeight.bold)),
                    ),
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
          cursorColor: deepGreen,
          style: TextStyle(color: deepGreen, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: deepGreen.withOpacity(0.2), fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: deepGreen, size: 20),
            suffixIcon: isPassword ? IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: accentPink, size: 20), onPressed: onToggle) : null,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: deepGreen.withOpacity(0.1))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentPink, width: 2)),
          ),
          validator: (value) => value!.isEmpty ? "Field required" : null,
        ),
      ],
    );
  }
}