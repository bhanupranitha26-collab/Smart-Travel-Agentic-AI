import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
import 'signup_screen.dart';
import '../services/auth_api.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
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

    setState(() {
      _isLoading = true;
    });

    final res = await AuthApi.login(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res['success']) {
      final data = res['data'];
      final String token = data['access_token'];
      final String userName = data['user_name'];
      final String userEmail = data['user_email'];
      final String userId = data['user_id'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('token', token);
      await prefs.setString('userName', userName);
      await prefs.setString('userEmail', userEmail);
      await prefs.setString('user_id', userId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AppShell(
            userName: userName,
            userEmail: userEmail,
          ),
        ),
      );
    } else {
      String msg = res['message'] ?? 'Login failed';
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
                            'TravelPilot AI',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF008080),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Plan smarter. Travel better.',
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
                                // Google Login removed per request
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
                                Row(
                                  children: [
                                    const Expanded(
                                      child: _FieldLabel('PASSWORD'),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Color(0xFF008080),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                                    onPressed: _login,
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
                                        : const Text('Log In'),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => SignupScreen()),
                                    );
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      text: "Don't have an account yet? ",
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.6),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Create Account',
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

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
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

