import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:application/login_screen.dart'; // Import your login screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Tracks the selected menu option
  String? username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      // Fetch the username from the users table
      final response = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('email', user.email!)
          .maybeSingle();

      setState(() {
        username = response != null && response['username'] != null
            ? response['username'] as String
            : 'User'; // Fallback to 'User'
      });
    } else {
      setState(() {
        username = 'User'; // Fallback to 'User'
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // Handle drawer action
          },
        ),
        title: Image.asset(
          'lib/assets/logo.png',
          height: 40,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logout, // Log out on press
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Dynamic welcome message with a smaller font size
          Text(
            'Welcome, ${username ?? 'User'}',
            style: const TextStyle(
              fontSize: 18, // Reduced font size
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C6E47),
            ),
          ),
          const SizedBox(height: 20),
          // Scrollable row for the menu buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _menuButton("Create / Join", 0),
                _menuButton("My Competitions", 1),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // IndexedStack will display the corresponding content for the selected menu
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _createJoinView(), // First tab content
                _myCompetitionsView(), // Second tab content
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function for creating menu buttons
  Widget _menuButton(String title, int index) {
    bool isActive = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index; // Change selected index on tap
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1C6E47) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1C6E47)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isActive ? Colors.white : const Color(0xFF1C6E47),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // Content for the "Create / Join" view
  Widget _createJoinView() {
    return Column(
      children: [
        const Text(
          'Create or Join a Competition',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Handle create/join action
          },
          child: const Text('Create a Competition'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Handle join action
          },
          child: const Text('Join a Competition'),
        ),
      ],
    );
  }

  // Content for the "My Competitions" view
  Widget _myCompetitionsView() {
    return Column(
      children: [
        const Text(
          'My Competitions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        // Example of competition listing
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1C6E47)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Competition Name: WC Prediction Competition \'22'),
              SizedBox(height: 8),
              Text('Organizer: JSMITH99'),
              SizedBox(height: 8),
              Text('No. of Entries: 18'),
              SizedBox(height: 8),
              Text('Leaders Points: 35'),
              SizedBox(height: 8),
              Text('Current Pos: 8th'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Example of leaderboard section within My Competitions
        _leaderboard(),
      ],
    );
  }

  Widget _leaderboard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1C6E47)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _leaderboardRow('USERNAME', 'PL', 'W', 'D', 'L', 'GD', 'P'),
              const Divider(),
              _leaderboardRow('SWAPGN23', '15', '10', '-', '-', '-', '25'),
              _leaderboardRow('JTWOODS', '16', '7', '-', '-', '-', '23'),
              _leaderboardRow('ADGAV11', '15', '7', '-', '-', '-', '22'),
              _leaderboardRow('JSMITH99', '12', '7', '-', '-', '-', '19'),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            // Handle view full leaderboard action
          },
          child: const Text(
            'View Full Leaderboard',
            style: TextStyle(color: Color(0xFF1C6E47)),
          ),
        ),
      ],
    );
  }

  Widget _leaderboardRow(String username, String pl, String w, String d,
      String l, String gd, String p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(username),
        Text(pl),
        Text(w),
        Text(d),
        Text(l),
        Text(gd),
        Text(p),
      ],
    );
  }
}
