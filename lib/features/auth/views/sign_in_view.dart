import 'package:flutter/material.dart';
import 'package:nki_basketball/services/sign_in_service.dart';

class SignInView extends StatefulWidget {
  const SignInView({Key? key}) : super(key: key);

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final SignInService _signInService = SignInService();
  String? errorMessage;
  String? emailError;
  String? passwordError;
  bool isLoading = false;

  Future<void> handleSignIn() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      emailError = null;
      passwordError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;

    bool isValid = true;

    if (email.isEmpty) {
      emailError = 'Введите email';
      isValid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailError = 'Некорректный email';
      isValid = false;
    }

    if (password.isEmpty) {
      passwordError = 'Введите пароль';
      isValid = false;
    } else if (password.length < 6) {
      passwordError = 'Минимум 6 символов';
      isValid = false;
    }

    if (!isValid) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final userData = await _signInService.signIn(email, password);

    if (userData != null) {
      print('User logged in: ${userData['email']}');
      print(userData);
      Navigator.pushNamed(context, '/home', arguments: userData);
    } else {
      setState(() {
        errorMessage = 'Неверный логин или пароль';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, automaticallyImplyLeading: false),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff2c5364),
              Color(0xff203e43),
              Color(0xff0f2027),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 100),
            const Text(
              'Sign In',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Email Field
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white70,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(color: Colors.white70),
                errorText: emailError,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            // Password Field
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white70,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.white70),
                errorText: passwordError,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'SIGN IN',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 40),
            Image.asset("assets/images/nki_basketball_logo.png", width: 300, height: 300),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account?", style: TextStyle(color: Colors.white.withOpacity(0.8))),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}