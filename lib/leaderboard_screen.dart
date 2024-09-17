import 'package:application/make_selections_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatefulWidget {
  final String competitionId;

  const LeaderboardScreen({super.key, required this.competitionId});

  @override
  LeaderboardScreenState createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> competitionStats = [];
  List<Map<String, dynamic>> usersSelections = [];
  List<String> goalscorers = [];
  Map<String, bool> expanded = {}; // Track which users' cards are expanded
  int currentGameweek = 0;
  int startGameweek = 0;
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;  // Set the initial state to true, indicating data is being loaded.
   String competitionName = "";

  List<String> squads = [
  "ALL",
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
    fetchLeaderboardData();
  }

  /// Step 1: Fetch the usernames and initialize competition stats
Future<void> fetchCompetitionStats() async {
  try {
    final response = await supabase
        .from('competition_participants')
        .select('user_id, competitions!inner(competition_name), users!inner(username)')
        .eq('competition_id', widget.competitionId);

    // Extract and store competition name (assuming it's the same for all entries)
    if (response.isNotEmpty) {
      competitionName = response[0]['competitions']['competition_name'];
    }

    // Map user competition stats
    competitionStats = response.map<Map<String, dynamic>>((entry) {
      return {
        'username': entry['users']['username'],
        'remainingFootballers': 20,
      };
    }).toList();
    
    if (kDebugMode) {
      print('Users in competition: $competitionStats');
      print('Competition Name: $competitionName');
    }
  } catch (error) {
    if (kDebugMode) {
      print('Error fetching competition stats: $error');
    }
  }

  // Call setState to trigger a rebuild with the updated competitionName
  setState(() {});
}

  // Function to fetch and determine the current gameweek based on the current time and deadline_time
  Future<int> getCurrentGameweek() async {
    try {
      final response = await supabase
          .from('gameweek')
          .select('gameweek_id, deadline_time')
          .order('deadline_time', ascending: true);

      if (response.isNotEmpty) {
        final DateTime now = DateTime.now();
        for (int i = 0; i < response.length; i++) {
          final DateTime deadlineTime = DateTime.parse(response[i]['deadline_time']);
          if (now.isBefore(deadlineTime)) {
            return response[i]['gameweek_id'];
          }
        }
        return response.last['gameweek_id'];
      }
      return 0;
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching gameweeks: $error');
      }
      return 0;
    }
  }

  // Step 2: Fetch current gameweek and starting gameweek
  Future<void> fetchGameweekInfo() async {
    try {
      final competitionResponse = await supabase
          .from('competitions')
          .select('game_week')
          .eq('id', widget.competitionId)
          .single();

      startGameweek = competitionResponse['game_week'];
      currentGameweek = await getCurrentGameweek();

      if (kDebugMode) {
        print("Start Gameweek: $startGameweek, Current Gameweek: $currentGameweek");
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching gameweek info: $error');
      }
    }
  }
  Widget buildTopThreeLeaderboard() {
  competitionStats.sort((a, b) => a['remainingFootballers'].compareTo(b['remainingFootballers']));

  final first = competitionStats.isNotEmpty ? competitionStats[0] : null;
  final second = competitionStats.length > 1 ? competitionStats[1] : null;
  final third = competitionStats.length > 2 ? competitionStats[2] : null;

  return SizedBox(  // Wrap Stack in a SizedBox to give it a fixed height
    height: 200,  // Adjust the height as needed
    child: Stack(
      clipBehavior: Clip.none,  // Allow overflow to extend into app bar
      children: [
        // The semi-circle background with a border
        Positioned(
          top: -100,  // Adjust this to control how much the semi-circle extends into the app bar
          left: -1,
          right: -1,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: themeBackgroundColour,  // Use the secondary theme color for the background
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),  // Semi-circle effect
              border: const Border(
                bottom: BorderSide(
                  color: themeMainColour,  // Bottom border color
                  width: 4.0,  // Adjust the border width as needed
                ),
                left: BorderSide(
                  color: themeMainColour,  // Left border color
                  width: 4.0,  // Adjust the border width as needed
                ),
                right: BorderSide(
                  color: themeMainColour,  // Right border color
                  width: 4.0,  // Adjust the border width as needed
                ),
                top: BorderSide.none,  // No border on the top
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),  // Shadow position
                ),
              ],
            ),
          ),
        ),
        // The actual leaderboard tiles (top 3)
        Positioned(
          top: 40,  // Position this properly so it sits within the semi-circle
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildLeaderboardTile(second, 2),  // 2nd place
              buildLeaderboardTile(first, 1, true),  // 1st place with crown
              buildLeaderboardTile(third, 3),  // 3rd place
            ],
          ),
        ),
      ],
    ),
  );
}



PreferredSizeWidget buildAppBar() {
  return AppBar(
    backgroundColor: Colors.transparent,  // Make the app bar transparent
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),  // Custom back button icon and color
      onPressed: () {
        Navigator.of(context).pop();  // Custom behavior when the back button is pressed
      },
    ),
    title: const Text(
      'Leaderboard',
      style: TextStyle(fontSize: 24, fontFamily: 'Ethnocentric', color: Colors.white),
    ),
  );
}

  Future<void> fetchUsersSelections() async {
  try {
    final response = await supabase
        .from('selections')
        .select('player_id, users!inner(username), hasScored, gameweek_scored, footballers!inner(first_name, last_name, team)')
        .eq('competition_id', widget.competitionId);

    usersSelections = response.map<Map<String, dynamic>>((selection) {
      return {
        'player_id': selection['player_id'], // Keep the player_id for internal logic if needed
        'username': selection['users']['username'], // Fetch the username from users table
        'first_name': selection['footballers']['first_name'], // Fetch the first name from footballers table
        'last_name': selection['footballers']['last_name'],   // Fetch the last name from footballers table
        'team': (selection['footballers']['team'] as double?)?.toInt() ?? 0, // Convert team to int
        'hasScored': selection['hasScored'], // Has the player scored
        'gameweek_scored': selection['gameweek_scored'], // The gameweek when the player scored
      };
    }).toList();
    if (kDebugMode) {
      print(usersSelections);
    }
  } catch (error) {
    if (kDebugMode) {
      print('Error fetching users selections: $error');
    }
  }
}

Widget buildLeaderboardTile(Map<String, dynamic>? user, int rank, [bool isFirst = false]) {
    if (user == null) {
      return SizedBox(
        width: 100,
        height: 150,
        child: Column(
          children: [
            CircleAvatar(
              radius: isFirst ? 40 : 30,
              backgroundColor: themeSecondaryColour,
              child: Text(
                rank.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return SizedBox(
      width: 100,
      height: 150,
      child: Column(
        children: [
          CircleAvatar(
            radius: isFirst ? 40 : 30,
            backgroundColor: themeMainColour,
            child: isFirst
                ? const Icon(Icons.emoji_events, color: Colors.yellowAccent, size: 40)
                : Text(
                    rank.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            user['username'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  /// Step 5: Filter users' selections and update competition stats
Future<void> updateCompetitionStats() async {
  for (var stat in competitionStats) {
    String username = stat['username'];
    int remaining = usersSelections
        .where((selection) => selection['username'] == username && !selection['hasScored'])
        .length;
    stat['remainingFootballers'] = remaining;
  }

  competitionStats.sort((a, b) => a['remainingFootballers'].compareTo(b['remainingFootballers']));

  setState(() {
    competitionStats = competitionStats;
  });
}

 // Step 6: Fetch leaderboard data (all steps combined)
Future<void> fetchLeaderboardData() async {
  setState(() {
    isLoading = true;  // Start loading
  });
  
  await fetchGameweekInfo();
  await fetchCompetitionStats();
  await fetchUsersSelections(); // Only need to fetch user selections
  await updateCompetitionStats(); // Update based on selections
  
  setState(() {
    isLoading = false;  // Data loading is done
  });
}



  // Expand and collapse the selections for a specific user
  void toggleExpand(String username) {
    setState(() {
      expanded[username] = !(expanded[username] ?? false); // Toggle expansion state
    });
  }

  Widget buildSelectionsList(String username) {
  final selections = usersSelections.where((selection) => selection['username'] == username).toList();

  return Column(
    children: selections.map((selection) {
      final hasScored = selection['hasScored'];
      final gameweekScored = selection['gameweek_scored'];

      // Check if team_id is null and handle safely
      final teamId = selection['team'];
      final teamName = teamId != null && teamId is int && teamId >= 0 && teamId < squads.length
          ? squads[teamId]  // Use the team name if team_id is valid
          : 'Unknown Team';  // Fallback if team_id is null or out of bounds

      final teamImage = teamImageMap[teamName] ?? 'lib/assets/UnknownTeam.png';  // Use default if team is unknown

      // Get the player's full name
      final playerFullName = '${selection['first_name']} ${selection['last_name']}';

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: hasScored ? themeBackgroundColour : themeSecondaryColour,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  teamImage,  // Display the team image
                  width: 30,  // Adjust size as needed
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),  // Add spacing between the image and text
                Text(
                  playerFullName,  // Show the player's full name
                  style: TextStyle(
                    color: hasScored ? themeTertiarytColour : themeTextColour,  // Change color when hasScored is true
                  ),
                ),
                const SizedBox(width: 8),  // Space between name and football icon

                // Show football logo if the player has scored
                if (hasScored)
  const Icon(
    Icons.check,  // Use check icon
    color: Colors.green,  // Set the color to green
    size: 20,  // Adjust size as needed
  ),

              ],
            ),
            if (hasScored)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Gameweek Scored:', style: TextStyle(color: Colors.white70)),
                  Text(
                    gameweekScored.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
          ],
        ),
      );
    }).toList(),
  );
}


 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: themeBackgroundColour, // Set background color to black
    appBar: buildAppBar(),
    body: isLoading
      ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),  // Set spinner color
          ),
        )
      : competitionStats.isEmpty
          ? const Center(
              child: Text(
                'No user data available.',
                style: TextStyle(color: Colors.white), // White text on black background
              ),
            )
          : Column( 
            children: [
              // Display the competition name dynamically from the fetched data
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  competitionName.isNotEmpty ? competitionName : 'Loading...',  // Display the actual competition name
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Expanded ListView for leaderboard
              Expanded(
                child: ListView.builder(
                  itemCount: competitionStats.length,
                  itemBuilder: (context, index) {
                    final user = competitionStats[index];
                    final username = user['username'];
                    final remainingFootballers = user['remainingFootballers'];
                    final rank = index + 1;

                    // Determine if the dropdown should be active
                    bool canViewSelections = currentGameweek >= startGameweek;

                    String subtitleText;
                    if (currentGameweek < startGameweek) {
                      subtitleText = remainingFootballers == 0
                          ? 'Awaiting Selections'
                          : 'Selections Locked In';
                    } else {
                      subtitleText = '$remainingFootballers footballers remaining';
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 1.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: themeBackgroundColour, // Card background color
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.white, width: 1.0), // Add bottom border
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.transparent,
                                child: Text(
                                  rank.toString(),
                                  style: const TextStyle(
                                    color: themeTextColour,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeTextColour,
                                ),
                              ),
                              subtitle: Text(
                                  subtitleText,
                                  style: const TextStyle(
                                      color: themeMainColour)),

                              // If the competition hasn't started, disable the dropdown
                              trailing: canViewSelections
                                  ? IconButton(
                                      icon: Icon(
                                        expanded[username] == true
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: themeTextColour,
                                      ),
                                      onPressed: () => toggleExpand(username),
                                    )
                                  : null, // Disable dropdown when the competition hasn't started
                            ),

                            // If the competition has started and user has expanded, show selections
                            if (canViewSelections &&
                                expanded[username] == true)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: buildSelectionsList(username),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
  );
}




}