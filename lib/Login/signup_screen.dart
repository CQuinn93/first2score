import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../first2Score/dashboard_screen.dart'; // Assuming DashboardScreen is implemented
import 'login_screen.dart'; // Assuming LoginScreen is implemented

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  bool isLoading = false;
  bool _isSignUpEnabled = false;
  String? _usernameErrorMessage;

  // Theme colors
  final themeMainColour = const Color.fromARGB(255, 0, 165, 30);
  final themeSecondaryColour = const Color.fromARGB(255, 10, 65, 20);
  final themeBackgroundColour = const Color.fromARGB(255, 0, 0, 0);
  final themeTextColour = const Color.fromARGB(255, 255, 255, 255);
  final themeHintTextColour = const Color.fromARGB(255, 150, 150, 150);

  Future<void> _checkUsernameAvailability() async {
    final username = usernameController.text.trim();
    try {
      final usernameCheckResponse = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (!mounted) return;

      if (usernameCheckResponse != null) {
        setState(() {
          _usernameErrorMessage = 'Username is already taken.';
          _isSignUpEnabled = false;
        });
      } else {
        setState(() {
          _usernameErrorMessage = null;
          _isSignUpEnabled = true;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _usernameErrorMessage = 'Failed to check username availability.';
        _isSignUpEnabled = false;
      });
    }
  }

  Future<void> _signUp() async {
    if (!_isSignUpEnabled) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();

    if (password.length < 8 ||
        !RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)').hasMatch(password)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password must be at least 8 characters long and contain an upper case letter, lower case letter, and number.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final emailCheckResponse = await Supabase.instance.client
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (!mounted) return;

      if (emailCheckResponse != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email already exists.')),
          );
        }
        return;
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user != null) {
        await Supabase.instance.client.from('users').insert({
          'email': email,
          'username': username,
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = e.message;
        if (message.contains('User already registered')) {
          message = 'This email is already registered.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-up failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeBackgroundColour,
      resizeToAvoidBottomInset: true, // Resizes UI when keyboard appears
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40), // Add top padding
              Image.asset(
                'lib/assets/F2ScoreGreen.png', // Use same logo as Login screen
                height: 60,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Ethnocentric',
                      ),
                    ),
                    const SizedBox(
                        height: 50), // Space between title and input fields
                    TextField(
                      controller: emailController,
                      style: TextStyle(color: themeTextColour),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: themeHintTextColour),
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(color: themeHintTextColour),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: themeTextColour),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: themeMainColour),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: themeTextColour),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: themeHintTextColour),
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(color: themeHintTextColour),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: themeTextColour),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: themeMainColour),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      style: TextStyle(color: themeTextColour),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: themeHintTextColour),
                        hintText: 'Enter your username',
                        hintStyle: TextStyle(color: themeHintTextColour),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: themeTextColour),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: themeMainColour),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _checkUsernameAvailability,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeMainColour,
                      ),
                      child: const Text('Check Username Availability'),
                    ),
                    if (_usernameErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _usernameErrorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(
                        height: 40), // Space between form and sign-up button
                    ElevatedButton(
                      onPressed: isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeSecondaryColour,
                        foregroundColor: themeTextColour,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 100,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: themeTextColour,
                            )
                          : const Text(
                              'SIGN UP',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: "Ethnocentric",
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: themeTextColour),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              color: themeMainColour,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40), // Padding at the bottom
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
