// ignore_for_file: avoid_print

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
  List<Map<String, dynamic>> leaderboardData = [];
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchLeaderboardData();
  }

  Future<void> fetchLeaderboardData() async {
    try {
      // Fetch competition leaderboard (assuming there's a way to order by position/points)
      final response = await supabase
          .from('competition_participants')
          .select('user_id, position, users(username), remaining_selections')
          .eq('competition_id', widget.competitionId)
          .order('position', ascending: true);

      setState(() {
        leaderboardData = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      if (kDebugMode) {
        print("Error fetching leaderboard: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: leaderboardData.isEmpty
          ? const Center(
              child: Text('No leaderboard data available.'),
            )
          : ListView.builder(
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final user = leaderboardData[index];
                return _buildLeaderboardRow(user);
              },
            ),
    );
  }

  Widget _buildLeaderboardRow(Map<String, dynamic> user) {
    final username = user['users']['username'];
    final position = user['position'];
    final remainingSelections = user['remaining_selections'];

    return GestureDetector(
      onTap: () => _showUserSelections(user['user_id']),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: ListTile(
          leading: CircleAvatar(
            child: Text('$position'),
          ),
          title: Text(username),
          subtitle: Text('Remaining: $remainingSelections'),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }

  // Function to show a user's selections in a bottom modal sheet
  void _showUserSelections(String userId) async {
    try {
      // Fetch the selections for this user in this competition
      final response = await supabase
          .from('selections')
          .select('players(first_name, last_name, position)')
          .eq('competition_id', widget.competitionId)
          .eq('user_id', userId);

      final selections = List<Map<String, dynamic>>.from(response);

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            height: 400, // Adjust height as needed
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Selections',4
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                selections.isEmpty
                    ? const Text('No selections found for this user.')
                    : Expanded(
                        child: ListView.builder(
                          itemCount: selections.length,
                          itemBuilder: (context, index) {
                            final player = selections[index]['players'];
                            return ListTile(
                              leading: const Icon(Icons.sports_soccer),
                              title: Text(
                                  '${player['first_name']} ${player['last_name']}'),
                              subtitle: Text(player['position']),
                            );
                          },
                        ),
                      ),
              ],
            ),
          );
        },
      );
    } catch (error) {
      if (kDebugMode) {
        print("Error fetching selections: $error");
      }
    }
  }
}
