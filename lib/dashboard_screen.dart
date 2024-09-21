import 'package:application/home_screen_view.dart';
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
  Key myCompetitionsKey = UniqueKey(); // Key to refresh MyCompetitionsScreen
  bool _refreshMyCompetitions = false; // Flag to refresh My Competitions tab

  // Theme colors
  final themeMainColour = const Color.fromARGB(255, 0, 165, 30);
  final themeSecondaryColour = const Color.fromARGB(255, 10, 65, 20);
  final themeBackgroundColour = const Color.fromARGB(255, 0, 0, 0);
  final themeTextColour = const Color.fromARGB(255, 255, 255, 255);

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
      backgroundColor: themeBackgroundColour, // Set the background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: themeTextColour),
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
            icon: Icon(Icons.logout, color: themeTextColour),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
            'Welcome, ${username ?? 'User'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: themeTextColour, // White text for dark background
            ),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _menuButton("Home", 0),
                _menuButton("Create / Join", 1),
                _menuButton("My Competitions", 2),
                _menuButton("Open Competitions", 3),
              ],
            ),
          ),
          const SizedBox(height: 5),
          const Divider(color: Colors.white, thickness: 1), // White line separator
          const SizedBox(height: 20),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const HomeScreen(),
                const CreateJoinView(), // Tab 1: Create/Join Competitions
                MyCompetitionsScreen(
                  key:
                      myCompetitionsKey, // Tab 2: My Competitions with dynamic key
                ),
                OpenCompetitionsScreen(
                  onCompetitionJoined: () {
                    setState(() {
                      _refreshMyCompetitions = true; // Set flag to refresh
                    });
                  },
                ), // Tab 3: Open Competitions
              ],
            ),
          ),
          
        ],
        
      ),
    );
  }

  // Updated menu button to use theme colors
  Widget _menuButton(String title, int index) {
    bool isActive = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (index == 1 && _refreshMyCompetitions) {
              // When selecting "My Competitions", only refresh if a competition was joined
              myCompetitionsKey = UniqueKey(); // Set a new key to force refresh
              _refreshMyCompetitions = false; // Reset the refresh flag
            }
            _selectedIndex = index; // Switch to selected tab
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? themeSecondaryColour // Green background for active
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: themeMainColour), // Green border color
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? themeTextColour // White text for active buttons
                  : themeMainColour, // Green text for inactive buttons
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
