import 'package:application/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  bool _isSignUpEnabled =
      false; // Track if the sign-up button should be enabled
  String? _usernameErrorMessage; // Store the error message for the username

  Future<void> _checkUsernameAvailability() async {
    final username = usernameController.text.trim();

    try {
      final usernameCheckResponse = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle(); // Check for single match or null

      if (!mounted) return; // Check if the widget is still mounted

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
      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        _usernameErrorMessage = 'Failed to check username availability.';
        _isSignUpEnabled = false;
      });
    }
  }

  Future<void> _signUp() async {
    if (!_isSignUpEnabled) {
      return; // Ensure that sign-up can only happen when enabled
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();

    // Validate password
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
      // Check if the email already exists in the database
      final emailCheckResponse = await Supabase.instance.client
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle(); // Check for a single match or null

      if (!mounted) return; // Check if the widget is still mounted

      if (emailCheckResponse != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email already exists.')),
          );
        }
        return; // Stop the sign-up process if the email exists
      }

      // Attempt to sign up the user
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (!mounted) return; // Check if the widget is still mounted

      // Check if the sign-up was successful
      if (response.user != null) {
        // Insert the user info into the 'users' table
        await Supabase.instance.client.from('users').insert({
          'email': email,
          'username': username,
        });

        // Navigate to DashboardScreen
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
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  _checkUsernameAvailability, // Check username availability
              child: const Text('Check Username Availability'),
            ),
            if (_usernameErrorMessage !=
                null) // Show error message if the username is taken
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _usernameErrorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _isSignUpEnabled ? _signUp : null, // Enable/disable sign-up
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
