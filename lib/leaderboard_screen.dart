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
  List<dynamic> participants = []; // Will hold user IDs and usernames
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchUsernames();
  }

  // Step 2: Fetch user IDs and usernames
  Future<void> fetchUsernames() async {
    try {
      // Fetch user_id and the associated username by joining users table
      final response = await supabase
          .from('competition_participants')
          .select(
              'user_id, users!inner(id, username)') // Explicit join with foreign key assumption
          .eq('competition_id', widget.competitionId);

      setState(() {
        participants = response; // Save both user_id and username
      });

      if (kDebugMode) {
        print('Participants fetched: $participants');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching participants: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard - Usernames'),
      ),
      body: participants.isEmpty
          ? const Center(
              child: Text('No user data available.'),
            )
          : ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final user = participants[index];
                final userId = user['user_id'];
                final username = user['users']['username'];

                return ListTile(
                  title: Text('User: $username (ID: $userId)'),
                );
              },
            ),
    );
  }
}
