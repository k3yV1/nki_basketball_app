import 'package:flutter/material.dart';
import 'package:nki_basketball/services/sign_up_service.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();

  String? errorMessage;
  String? nameError;
  String? lastNameError;
  String? emailError;
  String? passwordError;
  String? repeatPasswordError;

  bool isLoading = false;

  Future<void> handleSignUp() async {
    setState(() {
      errorMessage = null;
      nameError = null;
      lastNameError = null;
      emailError = null;
      passwordError = null;
      repeatPasswordError = null;
      isLoading = true;
    });

    final name = nameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final repeatPassword = repeatPasswordController.text;

    bool isValid = true;

    if (name.isEmpty) {
      nameError = 'Введите имя';
      isValid = false;
    }
    if (lastName.isEmpty) {
      lastNameError = 'Введите фамилию';
      isValid = false;
    }
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
    if (repeatPassword.isEmpty) {
      repeatPasswordError = 'Повторите пароль';
      isValid = false;
    } else if (password != repeatPassword) {
      repeatPasswordError = 'Пароли не совпадают';
      isValid = false;
    }

    if (!isValid) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final result = await SignUpService().register(
      email: email,
      password: password,
      name: name,
      lastName: lastName,
    );

    if (result == '') {
      Navigator.pushReplacementNamed(context, '/signin');
    } else {
      setState(() {
        errorMessage = result['error'];
        isLoading = false;
      });
    }
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
            colors: [Color(0xff2c5364), Color(0xff203e43), Color(0xff0f2027)],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 100),
              const Text(
                'Sign Up',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildInput('Name', nameController, errorText: nameError),
              const SizedBox(height: 16),
              _buildInput('Last Name', lastNameController, errorText: lastNameError),
              const SizedBox(height: 16),
              _buildInput('Email', emailController, errorText: emailError),
              const SizedBox(height: 16),
              _buildInput('Password', passwordController, obscure: true, errorText: passwordError),
              const SizedBox(height: 16),
              _buildInput('Repeat Password', repeatPasswordController,
                  obscure: true, errorText: repeatPasswordError),
              const SizedBox(height: 16),
              if (errorMessage != null)
                Text(errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('SIGN UP',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Image.asset("assets/images/nki_basketball_logo.png", width: 300, height: 170),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("If you already have an account?",
                      style: TextStyle(color: Colors.white.withOpacity(0.8))),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signin');
                    },
                    child: const Text('Sign In',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController controller,
      {bool obscure = false, String? errorText}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white70,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        errorText: errorText,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}