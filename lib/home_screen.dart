import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:application/first2Score/dashboard_screen.dart';  // Import First2Score Dashboard screen
import 'package:application/first2LastMan/lastman_dashboard.dart';  // Import Last Man Standing Dashboard screen
import 'package:supabase_flutter/supabase_flutter.dart'; // For logout functionality

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}
const themeMainColour = Color.fromARGB(255, 0, 165, 30);
  const themeSecondaryColour = Color.fromARGB(255, 10, 65, 20);
  const themeBackgroundColour = Color.fromARGB(255, 0, 0, 0);
  const themeTextColour = Color.fromARGB(255, 255, 255, 255);
  const themeHintTextColour = Color.fromARGB(255, 150, 150, 150);
  const themeTertiaryColour = Color.fromARGB(255, 110, 110, 110);

class HomeScreenState extends State<HomeScreen> {
  String username = "User"; // Placeholder username

  bool isLoading = false; // Flag to show the loading spinner
  String? selectedLogo; // To track the selected logo for loading screen

  @override
  void initState() {
    super.initState();
    fetchUsername(); // Fetch username after login
  }

  Future<void> fetchUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('username')
            .eq('id', user.id)
            .single();

        setState(() {
          username = response['username'] ?? "User";
        });
      } catch (error) {
        if (kDebugMode) {
          print('Error fetching username: $error');
        }
      }
    }
  }

  // Simulate a delay with loading spinner before navigating
  void _navigateAfterDelay(Widget destinationScreen, String logo) async {
    setState(() {
      isLoading = true; // Start loading
      selectedLogo = logo; // Store the logo to display during loading
    });

    await Future.delayed(const Duration(seconds: 3)); // Wait for 3 seconds

    setState(() {
      isLoading = false; // Stop loading after delay
    });

    // Navigate to the destination screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeBackgroundColour,
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    selectedLogo!,
                    height: 100,
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section: Logo and Welcome text
                  Column(
                    children: [
                      const SizedBox(height: 40), // Space from the top of the screen
                      Image.asset('lib/assets/mainLogo.png', height: 100),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome, $username',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Middle section: Game selection buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Show First2Score logo with a delay before navigating
                            _navigateAfterDelay(const DashboardScreen(), 'lib/assets/F2S_logo.png');
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: themeTertiaryColour, width: 2),
                            ),
                            elevation: 2,
                            color: const Color.fromARGB(255, 0, 0, 0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset(
                                'lib/assets/F2S_logo.png',
                                height: 100,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Show Last Man Standing logo with a delay before navigating
                            _navigateAfterDelay(const LastManDashboardScreen(), 'lib/assets/F2LM_logo.png');
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: themeTertiaryColour, width: 2),
                            ),
                            elevation: 2,
                            color: const Color.fromARGB(255, 0, 0, 0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset(
                                'lib/assets/F2LM_logo.png',
                                height: 100,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom section: Logout button
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: TextButton(
                      onPressed: () async {
                        // Logout functionality
                        await Supabase.instance.client.auth.signOut();
                        Navigator.pushReplacementNamed(context, '/login'); // Navigate back to login
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 90, 90, 90), // themeTertiaryColour for logout text
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
