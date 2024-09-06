import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'make_selections_screen.dart'; // Import the selections screen
// Assuming you have a leaderboard screen
import 'leaderboard_screen.dart';

class MyCompetitionsScreen extends StatefulWidget {
  const MyCompetitionsScreen({super.key});

  @override
  MyCompetitionsScreenState createState() => MyCompetitionsScreenState();
}

class MyCompetitionsScreenState extends State<MyCompetitionsScreen> {
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
      final response = await supabase
          .from('competition_participants')
          .select('''
            competition_id,
            competitions(competition_name)
          ''')
          .eq('user_id', user.id);

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
            .compareTo(b['competitions']['competition_name'].toString().toLowerCase());
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
      appBar: AppBar(
        title: const Text("My Competitions"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Show loader while fetching
            )
          : RefreshIndicator(
              onRefresh: fetchMyCompetitions, // Add pull-to-refresh functionality
              child: myCompetitions.isEmpty
                  ? const Center(
                      child: Text("No competitions joined yet."),
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
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              competitionName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (hasMadeSelections) {
                      _navigateToTransfers(competitionId);
                    } else {
                      _navigateToMakeSelections(competitionId, competitionName);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasMadeSelections
                        ? Colors.blue // Transfers button color
                        : Colors.green, // Make selections button color
                  ),
                  child: Text(
                    hasMadeSelections
                        ? 'Transfers'
                        : 'Make Selections', // Text based on the condition
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _navigateToLeaderboard(competitionId);
                  },
                  child: const Text("Leaderboard"),
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
