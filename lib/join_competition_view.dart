import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'make_selections_screen.dart';
import 'dashboard_screen.dart'; // Assuming this is the dashboard screen

class JoinCompetitionView extends StatefulWidget {
  const JoinCompetitionView({super.key});

  @override
  JoinCompetitionViewState createState() => JoinCompetitionViewState();
}

class JoinCompetitionViewState extends State<JoinCompetitionView> {
  final _joinCodeController = TextEditingController();

  void _joinCompetition() async {
    final joinCode = _joinCodeController.text.trim();

    if (joinCode.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a join code.')),
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
          const SnackBar(content: Text('Invalid join code.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  // Show confirmation dialog to confirm joining the competition
  void _showJoinConfirmation(String competitionId, String competitionName, bool isStarted) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Joining'),
          content: Text(
              'You are about to join $competitionName.\n\n'
              'Please note that if this competition has already started, you will not be added.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss the dialog if the user presses 'Back'
              },
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close this dialog
                if (!isStarted) {
                  _confirmJoining(competitionId, competitionName);
                } else {
                  // Show message that competition has already started
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This competition has already started.')),
                  );
                }
              },
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
        SnackBar(content: Text('Error joining competition: $error')),
      );
    }
  }

  // Show the dialog to ask if the user wants to make selections now or later
  void _showMakeSelectionOption(String competitionId, String competitionName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Competition Joined'),
          content: const Text('Do you want to make your selections now?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss this dialog
                _navigateToMakeSelections(competitionId, competitionName); // Navigate to selections
              },
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
            const Text(
              'Join a Competition',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _joinCodeController,
              decoration: const InputDecoration(
                labelText: 'Join Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinCompetition,
              child: const Text('Join Competition'),
            ),
          ],
        ),
      ),
    );
  }
}
