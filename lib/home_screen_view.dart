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

  List<Map<String, dynamic>> allGames = []; // Store all games here
  List<Map<String, dynamic>> filteredResults = [];
  List<Map<String, dynamic>> filteredFixtures = [];
  List<Map<String, dynamic>> gameweekData = []; // Store gameweek data here

  bool isLoading = true;
  String username = "User";
  int _selectedTabIndex = 0;

  String? selectedGameweek; // For gameweek filter
  String? selectedTeam; // For team filter

  // Theme colors
  final themeMainColour = const Color.fromARGB(255, 0, 165, 30);
  final themeSecondaryColour = const Color.fromARGB(255, 10, 65, 20);
  final themeTertiaryColour = const Color.fromARGB(255, 90, 90, 90);
  final themeBackgroundColour = const Color.fromARGB(255, 0, 0, 0);
  final themeTextColour = const Color.fromARGB(255, 255, 255, 255);

  List<String> squads = [
    "Arsenal", "Aston Villa", "Bournemouth", "Brentford", "Brighton", "Chelsea",
    "Crystal Palace", "Everton", "Fulham", "Ipswich Town", "Leicester", "Liverpool",
    "Manchester City", "Manchester United", "Newcastle United", "Nottingham Forest",
    "Southampton", "Tottenham Hotspur", "West Ham United", "Wolves"
  ];

  Map<String, String> teamImageMap = {
    "Arsenal": "lib/assets/Arsenal.png", "Aston Villa": "lib/assets/Aston Villa.png",
    "Bournemouth": "lib/assets/Bournemouth.png", "Brentford": "lib/assets/Brentford.png",
    "Brighton": "lib/assets/Brighton.png", "Chelsea": "lib/assets/Chelsea.png",
    "Crystal Palace": "lib/assets/Crystal Palace.png", "Everton": "lib/assets/Everton.png",
    "Fulham": "lib/assets/Fulham.png", "Ipswich Town": "lib/assets/Ipswich Town.png",
    "Leicester": "lib/assets/Leicester.png", "Liverpool": "lib/assets/Liverpool.png",
    "Manchester City": "lib/assets/Manchester City.png", "Manchester United": "lib/assets/Manchester United.png",
    "Newcastle United": "lib/assets/Newcastle.png", "Nottingham Forest": "lib/assets/Notts Forest.png",
    "Tottenham Hotspur": "lib/assets/Tottenham.png", "Southampton": "lib/assets/Southampton.png",
    "West Ham United": "lib/assets/West Ham.png", "Wolves": "lib/assets/Wolves.png",
  };

  @override
  void initState() {
    super.initState();
    fetchGameData(); // Fetch all games at launch
    fetchUsername(); // Fetch the logged-in user's username
  }

  // Fetch all games (fixtures + results)
  Future<void> fetchGameData() async {
    try {
      final response = await Supabase.instance.client
          .from('games')
          .select('*')
          .order('kickoff_time', ascending: true); // Fetch all games

      if (response.isNotEmpty) {
        setState(() {
          allGames = List<Map<String, dynamic>>.from(response);
          // Split games into fixtures and results
          filteredFixtures = allGames.where((game) => game['finished'] == false).toList();
          filteredResults = allGames.where((game) => game['finished'] == true).toList();
        });
      }
    } catch (error) {
      if (kDebugMode) print("Error fetching game data: $error");
    }
  }

  // Fetch the username from Supabase
  Future<void> fetchUsername() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await supabase
            .from('users')
            .select('username')
            .eq('id', user.id)
            .single();

        setState(() {
          username = response['username'] ?? "User";
        });
      } catch (error) {
        if (kDebugMode) print('Error fetching username: $error');
      }
    }
  }

  // Tab switching function
  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
      // Reset filters when switching tabs
      selectedGameweek = null;
      selectedTeam = null;
    });
  }

  // Apply filters based on selected gameweek and team
  List<Map<String, dynamic>> applyFilters(List<Map<String, dynamic>> games) {
    return games.where((game) {
      bool matchesGameweek = selectedGameweek == null || game['gameweek'].toString() == selectedGameweek;
      bool matchesTeam = selectedTeam == null || squads[game['home_team'] - 1] == selectedTeam || squads[game['away_team'] - 1] == selectedTeam;
      return matchesGameweek && matchesTeam;
    }).toList();
  }

 Widget buildGameTile(
  String homeTeamName,
  String awayTeamName,
  String homeTeamImage,
  String awayTeamImage, {
  String? homeScore,
  String? awayScore,
  DateTime? matchDate,
  List<String>? goalscorers, // Add goalscorers as an optional parameter
}) {
  // Check if this is a fixture (date and time) or a result (homeScore and awayScore)
  bool isResult = homeScore != null && awayScore != null;

  // Format the Date and Time if it's a fixture
  String? formattedDate;
  String? formattedTime;
  if (matchDate != null) {
    formattedDate = "${matchDate.day}-${matchDate.month}-${matchDate.year}";
    formattedTime = "${matchDate.hour}:${matchDate.minute.toString().padLeft(2, '0')}";
  }

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      bool isExpanded = false;

      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        color: themeBackgroundColour,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: InkWell(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Column(
            children: [
              // Main content (team names and scores or date/time)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // First column: Team Logos and Names
                    Row(
                      children: [
                        Image.asset(homeTeamImage, width: 30, height: 30),
                        const SizedBox(width: 8),
                        Text(
                          homeTeamName,
                          style: TextStyle(
                            color: themeTextColour,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 20), // Space between logos and names
                        Image.asset(awayTeamImage, width: 30, height: 30),
                        const SizedBox(width: 8),
                        Text(
                          awayTeamName,
                          style: TextStyle(
                            color: themeTextColour,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Second column: Scores or Date/Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: isResult
                          ? [
                              // Display home and away scores if this is a result
                              Container(
                                width: 50,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white, // White outline for the box
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  homeScore,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: themeTextColour,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 50,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white, // White outline for the box
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  awayScore,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: themeTextColour,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ]
                          : [
                              // Display date and time if this is a fixture
                              Text(
                                formattedDate ?? '',
                                style: TextStyle(
                                  color: themeTertiaryColour, // Change to tertiary color
                                  fontSize: 12, // Smaller font
                                ),
                              ),
                              const SizedBox(height: 8), // Space between date and time
                              Text(
                                formattedTime ?? '',
                                style: TextStyle(
                                  color: themeTertiaryColour, // Change to tertiary color
                                  fontSize: 12, // Smaller font
                                ),
                              ),
                            ],
                    ),
                  ],
                ),
              ),

              // Expanded section for goalscorers
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: goalscorers != null && goalscorers.isNotEmpty
                        ? goalscorers.map((scorer) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                scorer,
                                style: TextStyle(
                                  color: themeTextColour,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList()
                        : [
                            Text(
                              'No goalscorers for this game.',
                              style: TextStyle(color: themeTertiaryColour, fontSize: 14),
                            ),
                          ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}




  // Group games by gameweek
  Map<int, List<Map<String, dynamic>>> groupGamesByGameweek(List<Map<String, dynamic>> games) {
    Map<int, List<Map<String, dynamic>>> groupedGames = {};
    for (var game in games) {
      int gameweek = game['gameweek'];
      if (!groupedGames.containsKey(gameweek)) {
        groupedGames[gameweek] = [];
      }
      groupedGames[gameweek]!.add(game);
    }
    return groupedGames;
  }

  Widget buildResultsSection() {
  // Apply the selected filters to the results
  List<Map<String, dynamic>> filtered = applyFilters(filteredResults);

  // Group the results by gameweek and sort them in descending order
  Map<int, List<Map<String, dynamic>>> groupedResults = groupGamesByGameweek(filtered);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Add the filters for Results
      buildFilters(isResultsTab: true),

      const SizedBox(height: 16),

      // Scrollable view for results
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: groupedResults.keys.map((gameweek) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display gameweek header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Gameweek $gameweek',
                        style: TextStyle(
                          color: themeTextColour,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Build the list of games for this gameweek
                    Column(
                      children: groupedResults[gameweek]!.map((game) {
                        final homeTeamIndex = game['home_team'] - 1;
                        final awayTeamIndex = game['away_team'] - 1;

                        final homeTeamName = (homeTeamIndex >= 0 && homeTeamIndex < squads.length)
                            ? squads[homeTeamIndex]
                            : 'Unknown Team';
                        final awayTeamName = (awayTeamIndex >= 0 && awayTeamIndex < squads.length)
                            ? squads[awayTeamIndex]
                            : 'Unknown Team';

                        final homeTeamImage = teamImageMap[homeTeamName] ?? 'lib/assets/logo.png';
                        final awayTeamImage = teamImageMap[awayTeamName] ?? 'lib/assets/logo.png';

                        // Extract goalscorers from the game data
                        List<String> goalscorers = List<String>.from(game['goalscorers'] ?? []);

                        // Pass the scores instead of date and time for results
                        return buildGameTile(
                          homeTeamName,
                          awayTeamName,
                          homeTeamImage,
                          awayTeamImage,
                          homeScore: game['home_score']?.toString() ?? '0',
                          awayScore: game['away_score']?.toString() ?? '0',
                          goalscorers: goalscorers, // Pass goalscorers here
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );
}



Widget buildFixturesSection() {
  // Apply the selected filters to the fixtures
  List<Map<String, dynamic>> filtered = applyFilters(filteredFixtures);

  // Group the fixtures by gameweek and sort them in ascending order
  Map<int, List<Map<String, dynamic>>> groupedFixtures = groupGamesByGameweek(filtered);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Add the filters for Fixtures
      buildFilters(isResultsTab: false),

      const SizedBox(height: 16),

      // Scrollable view for fixtures
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: groupedFixtures.keys.map((gameweek) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display gameweek header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Gameweek $gameweek',
                        style: TextStyle(
                          color: themeTextColour,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Build the list of games for this gameweek
                    Column(
                      children: groupedFixtures[gameweek]!.map((game) {
                        final homeTeamIndex = game['home_team'] - 1;
                        final awayTeamIndex = game['away_team'] - 1;

                        final homeTeamName = (homeTeamIndex >= 0 && homeTeamIndex < squads.length)
                            ? squads[homeTeamIndex]
                            : 'Unknown Team';
                        final awayTeamName = (awayTeamIndex >= 0 && awayTeamIndex < squads.length)
                            ? squads[awayTeamIndex]
                            : 'Unknown Team';

                        final homeTeamImage = teamImageMap[homeTeamName] ?? 'lib/assets/logo.png';
                        final awayTeamImage = teamImageMap[awayTeamName] ?? 'lib/assets/logo.png';

                        // Parse the match time if available, otherwise use a placeholder DateTime
                        DateTime matchDate;
                        if (game['kickoff_time'] != null) {
                          matchDate = DateTime.parse(game['kickoff_time']);
                        } else {
                          matchDate = DateTime.now(); // Placeholder date if not available
                        }

                        // Pass the date and time for fixtures
                        return buildGameTile(
                          homeTeamName,
                          awayTeamName,
                          homeTeamImage,
                          awayTeamImage,
                          matchDate: matchDate, // Pass the matchDate here
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );
}






// Filter dropdowns for gameweek and teams
Widget buildFilters({required bool isResultsTab}) {
  // For results, filter gameweeks where the deadline_time has passed.
  // For fixtures, show gameweeks from the current gameweek onwards.
  List availableGameweeks = isResultsTab
      ? gameweekData
          .where((g) => DateTime.parse(g['deadline_time']).isBefore(DateTime.now()))
          .map((g) => g['gameweek_id'])
          .toList()
      : gameweekData
          .where((g) => DateTime.parse(g['deadline_time']).isAfter(DateTime.now()))
          .map((g) => g['gameweek_id'])
          .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Scrollable row for team logos and names
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: squads.map((team) {
            final teamImage = teamImageMap[team] ?? 'lib/assets/logo.png';
            final isSelected = selectedTeam == team;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedTeam = isSelected ? null : team; // Toggle team selection
                });
              },
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? themeMainColour : Colors.transparent,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      teamImage,
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    team,
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),

      const SizedBox(height: 16), // Space between filters

      // Scrollable row for gameweek numbers
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: availableGameweeks.map((gameweek) {
            final isSelected = selectedGameweek == gameweek.toString();

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedGameweek = isSelected ? null : gameweek.toString(); // Toggle gameweek selection
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? themeMainColour : Colors.transparent,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'GW $gameweek',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}




  // Build the UI layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeBackgroundColour,
      body: Column(
        children: [

          // Tab Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabButton('Results', 0),
              _tabButton('Fixtures', 1),
              _tabButton('Latest Goalscorers', 2),
              _tabButton('Latest Player Updates', 3),
            ],
          ),
          const SizedBox(height: 20),

          // Tab Views
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                Padding(padding: const EdgeInsets.all(8.0), child: buildResultsSection()),
                Padding(padding: const EdgeInsets.all(8.0), child: buildFixturesSection()),
                _goalscorersView(),
                _playerUpdatesView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab button widget
  Widget _tabButton(String title, int index) {
    bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: GestureDetector(
          onTap: () => _onTabSelected(index),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? themeSecondaryColour : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: themeMainColour),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(fontSize: 12, color: isActive ? themeTextColour : themeMainColour, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _goalscorersView() {
    return Center(child: Text('Latest Goalscorers Content', style: TextStyle(color: themeTextColour)));
  }

  Widget _playerUpdatesView() {
    return Center(child: Text('Latest Player Updates Content', style: TextStyle(color: themeTextColour)));
  }
}
