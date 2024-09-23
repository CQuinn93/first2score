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
  bool _isExpanded = false; // Add a state variable to track whether the card is expanded

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

  Future<void> fetchGameData() async {
  try {
    // Fetch all games
    final response = await Supabase.instance.client
        .from('games')
        .select('*')
        .order('kickoff_time', ascending: true); // Fetch all games

    // Fetch all footballers
    final playersResponse = await Supabase.instance.client
        .from('footballers')
        .select('id, first_name, last_name');

    // Convert the footballers list into a map for quick lookups
    Map<int, String> playerNamesMap = {};
    for (var player in playersResponse) {
      playerNamesMap[player['id']] =
          '${player['first_name']} ${player['last_name']}'; // Store player full names
    }

    if (response.isNotEmpty) {
      setState(() {
        allGames = List<Map<String, dynamic>>.from(response);

        // Replace player IDs in goalscorers with actual names
        for (var game in allGames) {
          if (game['goalscorers'] != null) {
            List<String> updatedGoalscorers = replacePlayerIdsWithNames(
                List<String>.from(game['goalscorers']), playerNamesMap);
            game['goalscorers'] = updatedGoalscorers;
          }
        }

        // Split games into fixtures and results
        filteredFixtures =
            allGames.where((game) => game['finished'] == false).toList();
        filteredResults =
            allGames.where((game) => game['finished'] == true).toList();
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

  List<int> extractPlayerIds(List<String> goalscorers) {
  // Extract player IDs from the string format: "Player 317 (Away)"
  return goalscorers.map((goalscorer) {
    final regex = RegExp(r'Player (\d+)'); // Regular expression to capture the ID
    final match = regex.firstMatch(goalscorer);
    if (match != null) {
      return int.parse(match.group(1)!); // Get the player ID as an integer
    }
    return null;
  }).whereType<int>().toList(); // Filter out nulls and keep only valid integers
}


  // Apply filters based on selected gameweek and team
  List<Map<String, dynamic>> applyFilters(List<Map<String, dynamic>> games) {
    return games.where((game) {
      bool matchesGameweek = selectedGameweek == null || game['gameweek'].toString() == selectedGameweek;
      bool matchesTeam = selectedTeam == null || squads[game['home_team'] - 1] == selectedTeam || squads[game['away_team'] - 1] == selectedTeam;
      return matchesGameweek && matchesTeam;
    }).toList();
  }

 Widget buildGameTile(String homeTeamName, String awayTeamName,
    String homeTeamImage, String awayTeamImage,
    {String? homeScore, String? awayScore, DateTime? matchDate, List<String>? goalscorers}) {
  
  // Check if this is a fixture (date and time) or a result (homeScore and awayScore)
  bool isResult = homeScore != null && awayScore != null;

  // Format the Date and Time if it's a fixture
  String? formattedDate;
  String? formattedTime;
  if (matchDate != null) {
    formattedDate = "${matchDate.day}-${matchDate.month}-${matchDate.year}";
    formattedTime = "${matchDate.hour}:${matchDate.minute.toString().padLeft(2, '0')}"; // Add leading zero to minutes if needed
  }

  return GestureDetector(
    onTap: () {
      if (isResult) {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      }
    },
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      color: themeBackgroundColour,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          Divider(
            color: themeMainColour.withOpacity(0.8),
            thickness: 1.0,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // First column: Team logos and names stacked (flex 7)
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
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
                        ],
                      ),
                    ),
                    // Second column: Either scores for results or date/time for fixtures (flex 3)
                    Expanded(
                      flex: 3,
                      child: isResult
                          ? Column(
                              children: [
                                Container(
                                  width: 50,
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white, width: 1.5),
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
                                    border: Border.all(color: Colors.white, width: 1.5),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    awayScore ?? '0',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: themeTextColour,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Text(
                                  formattedDate ?? '',
                                  style: TextStyle(
                                    color: themeTertiaryColour,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formattedTime ?? '',
                                  style: TextStyle(
                                    color: themeTertiaryColour,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                // We won't add a goalscorers section for fixtures, so it remains as is
              ],
            ),
          ),
        ],
      ),
    ),
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

  List<String> replacePlayerIdsWithNames(List<String> goalscorers, Map<int, String> playerNamesMap) {
  return goalscorers.map((goalscorer) {
    final regex = RegExp(r'Player (\d+)'); // Regex to extract player ID
    final match = regex.firstMatch(goalscorer);
    if (match != null) {
      int playerId = int.parse(match.group(1)!); // Extract player ID
      String? playerName = playerNamesMap[playerId]; // Lookup player name
      if (playerName != null) {
        // Replace the "Player X (Home/Away)" with the actual player name
        return goalscorer.replaceFirst(RegExp(r'Player \d+'), playerName);
      }
    }
    return goalscorer; // Return the original string if no match
  }).toList();
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

                        // Revert to showing date and time for upcoming fixtures
                        return buildGameTile(
                          homeTeamName,
                          awayTeamName,
                          homeTeamImage,
                          awayTeamImage,
                          matchDate: matchDate, // Pass the matchDate here for fixtures
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

