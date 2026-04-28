import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
import 'login_screen.dart';
import '../services/auth_api.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await AuthApi.signup(name, email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please log in.'),
          backgroundColor: Color(0xFF008080),
        ),
      );
      Navigator.pop(context);
    } else {
      String msg = res['message'] ?? 'Signup failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F6FF), Color(0xFFF7FBFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              color: const Color(0xFF008080),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x26008080),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/logo/travelpilot_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.travel_explore_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF008080),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join TravelPilot AI today.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: const Color(0xFF204055).withOpacity(0.72),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _FieldLabel('FULL NAME'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.name,
                                  decoration: InputDecoration(
                                    hintText: 'John Doe',
                                    hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.28),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFE6E7ED),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF008080),
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const _FieldLabel('EMAIL ADDRESS'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'explorer@travelpilot.ai',
                                    hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.28),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFE6E7ED),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF008080),
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const _FieldLabel('PASSWORD'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: '........',
                                    hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.28),
                                      letterSpacing: 2,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFE6E7ED),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF008080),
                                        width: 1.4,
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.black.withOpacity(0.42),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _signup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF008080),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.black.withOpacity(0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Sign Up'),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      text: "Already have an account? ",
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.6),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Log In',
                                          style: TextStyle(
                                            color: Color(0xFF008080),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 18,
                            runSpacing: 6,
                            children: const [
                              _FooterText('PRIVACY POLICY'),
                              _FooterText('TERMS OF SERVICE'),
                              _FooterText('SUPPORT'),
                            ],
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Color(0xFF5B6069),
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  final String text;

  const _FooterText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: Colors.black.withOpacity(0.18),
      ),
    );
  }
}

