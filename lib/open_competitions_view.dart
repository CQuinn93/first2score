import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpenCompetitionsScreen extends StatefulWidget {
  final VoidCallback
      onCompetitionJoined; // Add a callback for when a competition is joined
  const OpenCompetitionsScreen({super.key, required this.onCompetitionJoined});

  @override
  OpenCompetitionsScreenState createState() => OpenCompetitionsScreenState();
}

class OpenCompetitionsScreenState extends State<OpenCompetitionsScreen> {
  // Theme colors
  final themeMainColour = const Color.fromARGB(255, 0, 165, 30);
  final themeSecondaryColour = const Color.fromARGB(255, 10, 65, 20);
  final themeTertiaryColour = const Color.fromARGB(255, 90, 90, 90);
  final themeBackgroundColour = const Color.fromARGB(255, 0, 0, 0);
  final themeTextColour = const Color.fromARGB(255, 255, 255, 255);
  final themeSecondaryTextColour = const Color.fromARGB(255, 175, 172, 0);

  List<Map<String, dynamic>> openCompetitions = [];
  List<String> joinedCompetitionIds = [];
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchOpenCompetitions();
  }

  Future<void> fetchOpenCompetitions() async {
    setState(() {
      isLoading = true; // Show loading indicator during fetch
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Fetch the competitions that are open
      final response = await supabase
          .from('competitions')
          .select('id, competition_name, game_week')
          .eq('competition_type', 'open');

      final competitionsList = List<Map<String, dynamic>>.from(response);

      // Fetch the competitions the user has already joined
      final joinedCompetitionsResponse = await supabase
          .from('competition_participants')
          .select('competition_id')
          .eq('user_id', user.id);

      // Convert joined competitions to a list of competition IDs
      joinedCompetitionIds = joinedCompetitionsResponse
          .map<String>((item) => item['competition_id'].toString())
          .toList();

      setState(() {
        openCompetitions = competitionsList;
        isLoading = false; // Hide loading indicator after fetch
      });
    } catch (error) {
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
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchOpenCompetitions,
                    color: themeMainColour,
                    child: openCompetitions.isEmpty
                        ? Center(
                            child: Text(
                              "No open competitions available.",
                              style: TextStyle(
                                color: themeTextColour, // Use theme text color
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: openCompetitions.length,
                            itemBuilder: (context, index) {
                              final competition = openCompetitions[index];
                              return _buildCompetitionCard(competition);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCompetitionCard(Map<String, dynamic> competition) {
    final competitionName = competition['competition_name'];
    final competitionId = competition['id'].toString();
    final startWeek =
        '${competition['game_week']}'; // Start week of the competition (no "Gameweek" text)
    final alreadyJoined = joinedCompetitionIds.contains(competitionId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: themeSecondaryColour.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: themeMainColour, width: 1), // Add green border
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column for Competition Name
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name',
                    style: TextStyle(
                      color: themeTertiaryColour,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                      height: 5), // Add spacing between header and content
                  Text(
                    competitionName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold, // White text for competition name
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Column for Gameweek
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Gameweek', // Header remains unchanged
                    style: TextStyle(
                      color: themeTertiaryColour,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                      height: 5), // Add spacing between header and content
                  Text(
                    startWeek, // Now only shows the gameweek number
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    softWrap: true,
                    maxLines: 2, // Set max lines to handle wrapping
                    overflow: TextOverflow.ellipsis, // Handle overflow
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10.0),
            // Column for Join Button
            Column(
              children: [
                ElevatedButton(
                  onPressed: alreadyJoined
                      ? null // Disable the button if the user has already joined
                      : () {
                          _joinCompetition(competitionId, competitionName);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 15,
                    ),
                    backgroundColor: alreadyJoined
                        ? themeBackgroundColour // Grey button for already joined competitions
                        : themeMainColour, // Green button for joining
                  ),
                  child: Text(
                    alreadyJoined ? 'Already Joined' : 'Join',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _joinCompetition(String competitionId, String competitionName) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Insert the user into the competition_participants table
      await supabase.from('competition_participants').insert({
        'user_id': user.id,
        'competition_id': competitionId,
      });

      // Ensure the widget is still mounted before showing a SnackBar
      if (!mounted) return;

      // Call the callback to notify that a competition was joined
      widget.onCompetitionJoined();

      // Show success message
      _showJoinSuccessDialog(competitionName);

      // Refresh competitions to update the list
      fetchOpenCompetitions();
    } catch (error) {
      // Ensure the widget is still mounted before showing a SnackBar
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join competition: $error')),
      );
    }
  }

  void _showJoinSuccessDialog(String competitionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Competition Joined'),
          content: Text(
            'You\'ve joined $competitionName. To make your selections, please visit "My Competitions" and proceed from there.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
