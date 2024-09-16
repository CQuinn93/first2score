import 'package:application/dashboard_screen.dart';
import 'package:application/forgot_password_screen.dart';
import 'package:application/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false; // Loading state
  bool rememberMe = false; // Remember Me checkbox state
  bool obscurePassword = true; // Password visibility toggle

  // Theme colors
  final themeMainColour = const Color.fromARGB(255, 0, 165, 30);
  final themeSecondaryColour = const Color.fromARGB(255, 10, 65, 20);
  final themeBackgroundColour = const Color.fromARGB(255, 0, 0, 0);
  final themeTextColour = const Color.fromARGB(255, 255, 255, 255);

  @override
  void initState() {
    super.initState();
    loadRememberedCredentials(); // Load saved credentials when the app starts
  }

  Future<void> loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email') ?? '';
    final savedPassword = prefs.getString('password') ?? '';
    final savedRememberMe = prefs.getBool('rememberMe') ?? false;

    if (savedRememberMe) {
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      setState(() {
        rememberMe = true;
      });
    }
  }

  Future<void> saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }
    await prefs.setBool('rememberMe', rememberMe);
  }

  Future<void> login() async {
    setState(() {
      isLoading = true; // Start loading
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Attempt to sign in
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if the login was successful
      if (response.user != null) {
        await saveCredentials(); // Save credentials if login is successful

        if (!mounted) return; // Ensure the widget is still mounted
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Stop loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeBackgroundColour, // Use theme background color
      resizeToAvoidBottomInset:
          true, // Ensures the UI resizes when keyboard appears
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40), // Add top padding
              Image.asset(
                'lib/assets/F2ScoreGreen.png', // Use dark theme logo here
                height: 60,
              ),

              // Center the text fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center content
                  children: [
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text color from theme
                        fontFamily: 'Ethnocentric', // Use custom font here
                      ),
                    ),
                    const SizedBox(height: 100),
                    TextField(
                      controller: emailController,
                      style:
                          TextStyle(color: themeTextColour), // Use theme color
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle:
                            const TextStyle(color: Colors.grey), // Grey label
                        hintText: 'Enter your email',
                        hintStyle: const TextStyle(
                            color: Colors.grey), // Grey hint text
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: themeTextColour), // White border
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  themeMainColour), // Green border when focused
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      style:
                          TextStyle(color: themeTextColour), // Use theme color
                      obscureText: obscurePassword, // Toggle password visibility
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle:
                            const TextStyle(color: Colors.grey), // Grey label
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(
                            color: Colors.grey), // Grey hint text
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: themeTextColour), // White border
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  themeMainColour), // Green border when focused
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey, // Grey color for icon
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword; // Toggle visibility
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (bool? value) {
                                setState(() {
                                  rememberMe = value ?? false;
                                });
                              },
                              activeColor: themeMainColour, // Green color
                              checkColor: themeTextColour, // White checkmark
                            ),
                            Text(
                              'Remember me',
                              style: TextStyle(
                                  color: themeTextColour), // White text
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.grey), // Grey text
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 75),
                  ],
                ),
              ),

              // Move the login button and sign-up prompt to the bottom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed:
                          isLoading ? null : login, // Disable button if loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            themeSecondaryColour, // Use secondary green
                        foregroundColor: themeTextColour, // White text
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
                              color: themeTextColour, // White loader color
                            )
                          : const Text(
                              'LOG IN',
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
                          "Don't have an account? ",
                          style:
                              TextStyle(color: themeTextColour), // White text
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              color: themeMainColour, // Green text
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                        height: 40), // Padding below the sign-up section
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
