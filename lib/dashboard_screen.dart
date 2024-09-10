import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_join_view.dart'; // Import your CreateJoinView
import 'open_competitions_view.dart'; // Import OpenCompetitionsView
import 'my_competitions_view.dart'; // Import your MyCompetitionsView
import 'login_screen.dart'; // Import the LoginScreen for logout

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('email', user.email!)
          .maybeSingle();

      setState(() {
        username = response != null && response['username'] != null
            ? response['username'] as String
            : 'User';
      });
    } else {
      setState(() {
        username = 'User';
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) =>
                const LoginScreen()), // Redirect to login screen
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color to black
      backgroundColor: Colors.black,

      // Transparent AppBar with updated logo
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Handle drawer action
          },
        ),
        title: Image.asset(
          'lib/assets/F2ScoreGreen.png', // Updated logo
          height: 40,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Welcome, ${username ?? 'User'}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text for dark background
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _menuButton("Create / Join", 0),
                _menuButton("My Competitions", 1),
                _menuButton("Open Competitions", 2),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                CreateJoinView(), // Tab 1: Create/Join Competitions
                MyCompetitionsScreen(), // Tab 2: My Competitions
                OpenCompetitionsView(), // Tab 3: Open Competitions
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated menu button to use green color scheme
  Widget _menuButton(String title, int index) {
    bool isActive = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? const Color.fromARGB(255, 22, 107, 30)
                : Colors.transparent, // Green background for active
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF1C6E47)), // Green border color
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isActive
                  ? Colors.white
                  : const Color(0xFF1C6E47), // Green text for inactive buttons
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
