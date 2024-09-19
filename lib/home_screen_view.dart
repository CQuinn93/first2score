import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> latestResults = [];
  List<Map<String, dynamic>> upcomingFixtures = [];
  bool isLoading = true;
  String username = "User";
  String selectedGameweek = "";

  // Define theme colors as used on the other screens
  final themeMainColour = const Color.fromARGB(255, 0, 165, 30);
  final themeSecondaryColour = const Color.fromARGB(255, 10, 65, 20);
  final themeTertiaryColour = const Color.fromARGB(255, 90, 90, 90);
  final themeBackgroundColour = const Color.fromARGB(255, 0, 0, 0);
  final themeTextColour = const Color.fromARGB(255, 255, 255, 255);
  final themeHintTextColour = const Color.fromARGB(255, 150, 150, 150);

  List<String> squads = [
    "Arsenal",
    "Aston Villa",
    "Bournemouth",
    "Brentford",
    "Brighton",
    "Chelsea",
    "Crystal Palace",
    "Everton",
    "Fulham",
    "Ipswich Town",
    "Leicester",
    "Liverpool",
    "Manchester City",
    "Manchester United",
    "Newcastle United",
    "Nottingham Forest",
    "Southampton",
    "Tottenham Hotspur",
    "West Ham United",
    "Wolves"
  ];

  Map<String, String> teamImageMap = {
    "Arsenal": "lib/assets/Arsenal.png",
    "Aston Villa": "lib/assets/Aston Villa.png",
    "Bournemouth": "lib/assets/Bournemouth.png",
    "Brentford": "lib/assets/Brentford.png",
    "Brighton": "lib/assets/Brighton.png",
    "Chelsea": "lib/assets/Chelsea.png",
    "Crystal Palace": "lib/assets/Crystal Palace.png",
    "Everton": "lib/assets/Everton.png",
    "Fulham": "lib/assets/Fulham.png",
    "Ipswich Town": "lib/assets/Ipswich Town.png",
    "Leicester": "lib/assets/Leicester.png",
    "Liverpool": "lib/assets/Liverpool.png",
    "Manchester City": "lib/assets/Manchester City.png",
    "Manchester United": "lib/assets/Manchester United.png",
    "Newcastle United": "lib/assets/Newcastle.png",
    "Nottingham Forest": "lib/assets/Notts Forest.png",
    "Tottenham Hotspur": "lib/assets/Tottenham.png",
    "Southampton": "lib/assets/Southampton.png",
    "West Ham United": "lib/assets/West Ham.png",
    "Wolves": "lib/assets/Wolves.png",
  };

  
  @override
  void initState() {
    super.initState();
    fetchGameData();
    fetchUsername(); // Fetch the logged-in user's username
  }

  // Fetch game results and upcoming fixtures
  Future<void> fetchGameData() async {
    try {
      final previousGameweekResponse = await supabase
          .from('games')
          .select('*')
          .eq('gameweek', await getPreviousGameweek());

      final upcomingGameweekResponse = await supabase
          .from('games')
          .select('*')
          .eq('gameweek', await getNextGameweek());

      setState(() {
        latestResults =
            List<Map<String, dynamic>>.from(previousGameweekResponse);
        upcomingFixtures =
            List<Map<String, dynamic>>.from(upcomingGameweekResponse);
        isLoading = false;
      });
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching game data: $error');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch username from Supabase
  Future<void> fetchUsername() async {
    final user = supabase.auth.currentUser;
    setState(() {
      username = user?.userMetadata?['username'] ??
          "User"; // Use the username from Supabase
    });
  }

  Future<int> getPreviousGameweek() async {
    return 1; // Placeholder value, replace with actual logic
  }

  Future<int> getNextGameweek() async {
    return 2; // Placeholder value, replace with actual logic
  }

  // Reusable widget for game display (with centered content)
Widget buildGameTile(String homeTeamName, String awayTeamName, String homeTeamImage, String awayTeamImage, {String score = '', String status = ''}) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 2,
    color: themeBackgroundColour,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Team logos and names centered
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home team
              Column(
                children: [
                  Image.asset(homeTeamImage, width: 40, height: 40),
                  const SizedBox(height: 8),
                  Text(
                    homeTeamName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeTextColour,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Score and status in the middle (centered)
              Column(
                children: [
                  Text(
                    score,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // Away team
              Column(
                children: [
                  Image.asset(awayTeamImage, width: 40, height: 40),
                  const SizedBox(height: 8),
                  Text(
                    awayTeamName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeTextColour,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Gameweek scrollable row
Widget buildGameweekScroller() {
  List<int> gameweeks = List.generate(38, (index) => index + 1); // Assuming 38 gameweeks in a season
  return SizedBox(
    height: 50,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: gameweeks.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ChoiceChip(
            label: Text(
              'GW ${gameweeks[index]}',
              style: const TextStyle(color: Colors.white),
            ),
            selected: selectedGameweek == gameweeks[index],
            onSelected: (bool selected) {
              setState(() {
                selectedGameweek = gameweeks[index] as String;
                fetchResultsForGameweek(selectedGameweek); // Filter results for selected gameweek
              });
            },
            backgroundColor: themeMainColour,
            selectedColor: Colors.greenAccent,
          ),
        );
      },
    ),
  );
}

// Build widget to show game results with gameweek selector
Widget buildResultsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Gameweek selector at the top
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      buildGameweekScroller(),
      const SizedBox(height: 16),
      // Scrollable list of results
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the ListView
        itemCount: filteredResults.length,
        itemBuilder: (context, index) {
          final game = filteredResults[index];
          final homeTeamIndex = game['home_team'] - 1;
          final awayTeamIndex = game['away_team'] - 1;

          final homeTeamName = (homeTeamIndex >= 0 && homeTeamIndex < squads.length) ? squads[homeTeamIndex] : 'Unknown Team';
          final awayTeamName = (awayTeamIndex >= 0 && awayTeamIndex < squads.length) ? squads[awayTeamIndex] : 'Unknown Team';

          final homeTeamImage = teamImageMap[homeTeamName] ?? 'lib/assets/default_team.png';
          final awayTeamImage = teamImageMap[awayTeamName] ?? 'lib/assets/default_team.png';

          return buildGameTile(
            homeTeamName,
            awayTeamName,
            homeTeamImage,
            awayTeamImage,
            score: '${game['home_score']} - ${game['away_score']}',
            status: 'Finished', // Replace with actual status if needed
          );
        },
      ),
    ],
  );
}
// Build widget to show upcoming fixtures
Widget buildFixturesSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Upcoming Fixtures',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: upcomingFixtures.length,
        itemBuilder: (context, index) {
          final game = upcomingFixtures[index];
          final homeTeamIndex = game['home_team'] - 1;
          final awayTeamIndex = game['away_team'] - 1;

          final homeTeamName = (homeTeamIndex >= 0 && homeTeamIndex < squads.length) ? squads[homeTeamIndex] : 'Unknown Team';
          final awayTeamName = (awayTeamIndex >= 0 && awayTeamIndex < squads.length) ? squads[awayTeamIndex] : 'Unknown Team';

          final homeTeamImage = teamImageMap[homeTeamName] ?? 'lib/assets/default_team.png';
          final awayTeamImage = teamImageMap[awayTeamName] ?? 'lib/assets/default_team.png';

          return buildGameTile(
            homeTeamName,
            awayTeamName,
            homeTeamImage,
            awayTeamImage,
            status: 'Upcoming', // Replace with actual status if needed
          );
        },
      ),
    ],
  );
}


  Widget buildGamesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildGameButton('First2LastMan', themeSecondaryColour, () {
                // Placeholder for future functionality
              }),
              buildGameButton('First2Six', themeTertiaryColour, () {
                // Placeholder for future functionality
              }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildGameButton('First2Score', themeMainColour, () {
                Navigator.pushNamed(context, '/dashboard');
              }),
              buildGameButton('First2Racing', themeTertiaryColour, () {
                // Placeholder for future functionality
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildGameButton(String gameName, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 150,
        height: 75,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            gameName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeBackgroundColour,
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
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Welcome, $username', // Replace with actual username
                    style: TextStyle(
                      color: themeTextColour,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Add fixtures and results sections
                buildResultsSection(),
                buildFixturesSection(),
              ],
            ),
          ),
  );
}
}
