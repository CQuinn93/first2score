import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'make_selections_screen.dart';
import 'lastman_dashboard.dart'; // Assuming this is the dashboard screen

class JoinCompetitionView extends StatefulWidget {
  const JoinCompetitionView({super.key});

  @override
  JoinCompetitionViewState createState() => JoinCompetitionViewState();
}

class JoinCompetitionViewState extends State<JoinCompetitionView> {
  final _joinCodeController = TextEditingController();

  // Define your theme colors
  final themeMainColour = const Color.fromARGB(255, 0, 165, 30);
  final themeSecondaryColour = const Color.fromARGB(255, 10, 65, 20);
  final themeBackgroundColour = const Color.fromARGB(255, 0, 0, 0);
  final themeTextColour = const Color.fromARGB(255, 255, 255, 255);
  final themeHintTextColour = const Color.fromARGB(255, 150, 150, 150);

  void _joinCompetition() async {
    final joinCode = _joinCodeController.text.trim();

    if (joinCode.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a join code.'),
          backgroundColor: themeSecondaryColour,
        ),
      );
      return;
    }

    try {
      // Fetch the competition details using the join code
      final response = await Supabase.instance.client
          .from('competitions')
          .select()
          .eq('join_code', joinCode)
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        final competitionName = response['competition_name'];
        final competitionId = response['id'];
        final isStarted = response['is_started'];

        // Show confirmation dialog
        _showJoinConfirmation(competitionId, competitionName, isStarted);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid join code.'),
            backgroundColor: themeSecondaryColour,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: themeSecondaryColour,
        ),
      );
    }
  }

  // Show confirmation dialog to confirm joining the competition
  void _showJoinConfirmation(String competitionId, String competitionName, bool isStarted) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeBackgroundColour, // Dark background color
          title: const Text(
            'Confirm Joining',
            style: TextStyle(color: Colors.white), // White text
          ),
          content: Text(
            'You are about to join $competitionName.\n\n'
            'Please note that if this competition has already started, you will not be added.',
            style: TextStyle(color: themeTextColour), // Theme text color
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss the dialog if the user presses 'Back'
              },
              child: Text(
                'Back',
                style: TextStyle(color: themeMainColour), // Green text color
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close this dialog
                if (!isStarted) {
                  _confirmJoining(competitionId, competitionName);
                } else {
                  // Show message that competition has already started
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('This competition has already started.'),
                      backgroundColor: themeSecondaryColour,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeMainColour, // Green button
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Confirm and join the competition if not started
  void _confirmJoining(String competitionId, String competitionName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Insert the user into the competition's participants table
      await Supabase.instance.client.from('competition_participants').insert({
        'competition_id': competitionId,
        'user_id': user.id,
        'is_owner': false, // As this is a join action, not a creation
      });

      // Show the success dialog and ask if the user wants to make selections now
      _showMakeSelectionOption(competitionId, competitionName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining competition: $error'),
          backgroundColor: themeSecondaryColour,
        ),
      );
    }
  }

  // Show the dialog to ask if the user wants to make selections now or later
  void _showMakeSelectionOption(String competitionId, String competitionName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeBackgroundColour, // Dark background color
          title: const Text(
            'Competition Joined',
            style: TextStyle(color: Colors.white), // White text
          ),
          content: const Text(
            'Do you want to make your selections now?',
            style: TextStyle(color: Colors.white), // White text
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LastManDashboardScreen(),
                  ),
                );
              },
              child: Text(
                'Later',
                style: TextStyle(color: themeMainColour), // Green text
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss this dialog
                _navigateToMakeSelections(competitionId, competitionName); // Navigate to selections
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeMainColour, // Green button
              ),
              child: const Text('Make Selections'),
            ),
          ],
        );
      },
    );
  }

  // Navigate to the make selections screen
  void _navigateToMakeSelections(String competitionId, String competitionName) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MakeSelectionsScreen(
          competitionId: competitionId,
          competitionName: competitionName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join a Competition',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeTextColour, // White text
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
              'To join a competition, simply input the join code recieved from the Creator of the competition. You will then be asked to confirm.',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w200,
                color: themeTextColour, // White text
              ),
            ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _joinCodeController,
              style: TextStyle(color: themeTextColour), // White text
              decoration: InputDecoration(
                labelText: 'Join Code',
                labelStyle: TextStyle(color: themeHintTextColour), // Grey hint text
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: themeTextColour), // White border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeMainColour), // Green border when focused
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center( // Center the button
              child: SizedBox(
                width: 200, // Set the width to a smaller size
                child: ElevatedButton(
                  onPressed: _joinCompetition,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeMainColour, // Green button
                    foregroundColor: themeTextColour, // White text color
                    padding: const EdgeInsets.symmetric(
                      vertical: 15, // Adjusted the vertical padding to match the smaller width
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Join Competition'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
