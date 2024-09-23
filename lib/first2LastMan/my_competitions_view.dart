import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'make_selections_screen.dart'; // Import the selections screen
import 'leaderboard_screen.dart'; // Import the leaderboard screen

class MyCompetitionsScreen extends StatefulWidget {
  const MyCompetitionsScreen({super.key});

  @override
  MyCompetitionsScreenState createState() => MyCompetitionsScreenState();
}

class MyCompetitionsScreenState extends State<MyCompetitionsScreen> {
  // Theme colors
  final themeMainColour = const Color.fromARGB(255, 0, 165, 30);
  final themeSecondaryColour = const Color.fromARGB(255, 10, 65, 20);
  final themeTertiaryColour = const Color.fromARGB(255, 90, 90, 90);
  final themeBackgroundColour = const Color.fromARGB(255, 0, 0, 0);
  final themeTextColour = const Color.fromARGB(255, 255, 255, 255);
  final themeHintTextColour = const Color.fromARGB(255, 150, 150, 150);

  List<Map<String, dynamic>> myCompetitions = [];
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMyCompetitions();
  }

  Future<void> fetchMyCompetitions() async {
    setState(() {
      isLoading = true; // Show loading indicator during fetch
    });

    final user = supabase.auth.currentUser;
    if (kDebugMode) {
      print(user?.id);
    }

    if (user == null) {
      // Handle user not authenticated
      if (kDebugMode) {
        print("User not Logged in");
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Fetch the competitions the user is a participant in
      final response =
          await supabase.from('competition_participants').select('''
            competition_id,
            competitions(competition_name)
          ''').eq('user_id', user.id);

      final competitionList = List<Map<String, dynamic>>.from(response);

      // For each competition, check if the user has made selections
      for (var competition in competitionList) {
        final competitionId = competition['competition_id'];

        // Check if the user has made selections in this competition
        final selectionsResponse = await supabase
            .from('selections')
            .select('id') // You can also fetch other fields if needed
            .eq('competition_id', competitionId)
            .eq('user_id', user.id);

        // If selections are found, set the `hasMadeSelections` flag to true
        competition['hasMadeSelections'] = selectionsResponse.isNotEmpty;
      }

      // Sort the competitionList alphabetically by the competition_name
      competitionList.sort((a, b) {
        return a['competitions']['competition_name']
            .toString()
            .toLowerCase()
            .compareTo(
                b['competitions']['competition_name'].toString().toLowerCase());
      });

      setState(() {
        myCompetitions = competitionList;
        isLoading = false; // Hide loading indicator after fetch
      });
    } catch (error) {
      // Handle error
      if (kDebugMode) {
        print("Error fetching competitions: $error");
      }
      setState(() {
        isLoading = false; // Hide loading indicator on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeBackgroundColour, // Dark theme background

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: themeMainColour, // Use theme main color for the loader
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchMyCompetitions,
              color: themeMainColour,
              child: myCompetitions.isEmpty
                  ? Center(
                      child: Text(
                        "No competitions joined yet.",
                        style: TextStyle(
                          color: themeTextColour, // Use theme text color
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: myCompetitions.length,
                      itemBuilder: (context, index) {
                        final competition = myCompetitions[index];
                        return _buildCompetitionCard(competition);
                      },
                    ),
            ),
    );
  }

  Widget _buildCompetitionCard(Map<String, dynamic> competition) {
    final competitionName = competition['competitions']['competition_name'];
    final competitionId = competition['competition_id'];
    final hasMadeSelections = competition['hasMadeSelections'] ?? false;

    return Card(
      color: themeSecondaryColour
          .withOpacity(0.5), // Use theme secondary color for the card
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: themeMainColour, width: 1), // Add green border
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Competition Logo (Image)
            Image.asset(
              'lib/assets/F2ScoreGreen.png',
              width: 150,
            ),
            const SizedBox(height: 5),

            // Row for competition name and buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Competition name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        color: themeTertiarytColour,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      competitionName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold, // White text for competition name
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                // Right: Two buttons with icons and labels
                Row(
                  children: [
                    // First button (Make Selections / Transfers)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (hasMadeSelections) {
                              _navigateToTransfers(competitionId);
                            } else {
                              _navigateToMakeSelections(
                                  competitionId, competitionName);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(6), // Smaller padding
                            minimumSize: const Size(40, 40), // Smaller size
                            backgroundColor: hasMadeSelections
                                ? themeMainColour // Transfers button color
                                : themeTextColour, // Make selections button color
                          ),
                          child: Image.asset(
                            hasMadeSelections
                                ? 'lib/assets/transfers_icon.png'
                                : 'lib/assets/make_selections_icon.png',
                            height: 15,
                            width: 15,
                          ),
                        ),
                        Text(
                          hasMadeSelections ? 'Transfers' : 'Selections',
                          style: const TextStyle(
                            color: Colors.white, // White text
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // Second button (Leaderboard)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _navigateToLeaderboard(competitionId);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(6), // Smaller padding
                            minimumSize: const Size(40, 40), // Smaller size
                            backgroundColor:
                                themeTextColour, // Leaderboard button color
                          ),
                          child: Image.asset(
                            'lib/assets/leaderboard_icon.png', // Use your leaderboard icon
                            height: 15,
                            width: 15,
                          ),
                        ),
                        const Text(
                          'Leaderboard',
                          style: TextStyle(
                            color: Colors.white, // White text
                            fontSize: 8,
                          ),
                        ),
                      ],
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

  void _navigateToMakeSelections(String competitionId, String competitionName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MakeSelectionsScreen(
          competitionId: competitionId,
          competitionName: competitionName,
        ),
      ),
    );
  }

  void _navigateToTransfers(String competitionId) {
    // Navigate to the transfers screen
    // Implement the screen and navigation logic here
  }

  void _navigateToLeaderboard(String competitionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeaderboardScreen(
          competitionId: competitionId,
        ),
      ),
    );
  }
}
