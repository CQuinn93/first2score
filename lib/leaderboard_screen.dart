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
  List<dynamic> participants = []; // Will hold user data
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    updateGoalscorersRemaining();
  }

  // Step 1: Fetch footballers who have scored since the competition start gameweek
  Future<List<double>> fetchFootballersWhoScored() async {
    try {
      // Fetch the starting gameweek of the competition
      final competitionResponse = await supabase
          .from('competitions')
          .select('game_week')
          .eq('id', widget.competitionId)
          .single(); // Only fetch a single competition
      final int startGameweek = competitionResponse['game_week'];
      if (kDebugMode) {
        print(startGameweek);
      }

      // Fetch footballers who scored on or after the start gameweek
      final footballersResponse = await supabase
          .from('footballers')
          .select('id')
          .gte('last_goal_scored', startGameweek);

      // Extract player IDs from the response
      List<double> footballersWhoScored = footballersResponse.map<double>((f) => f['id']).toList();

      return footballersWhoScored;
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching footballers: $error');
      }
      return [];
    }
  }

  // Step 2: Fetch the selections for each user and calculate remaining footballers
Future<void> updateGoalscorersRemaining() async {
  try {
    // Step 1: Get the footballers who have scored
    final footballersWhoScored = await fetchFootballersWhoScored();

    // Step 2: Fetch users and their selections with an explicit join
    final response = await supabase
        .from('competition_participants')
        .select('user_id, selections!inner(player_id)')
        .eq('competition_id', widget.competitionId);

    // Process the data and update the goalscorers_remaining field
    for (var participant in response) {
      final userId = participant['user_id'];
      final selections = participant['selections'] as List;

      // Count the number of selected footballers who have scored
      int footballersScored = selections.where((s) => footballersWhoScored.contains(s['player_id'])).length;

      // Calculate remaining footballers (starting from 20, assuming 20 selections)
      int remainingFootballers = 20 - footballersScored;

      // Step 3: Update the goalscorers_remaining field in competition_participants
      await supabase
          .from('competition_participants')
          .update({'goalscorers_remaining': remainingFootballers})
          .eq('competition_id', widget.competitionId)
          .eq('user_id', userId);
    }

    // Fetch updated leaderboard data
    fetchLeaderboardData();
  } catch (error) {
    if (kDebugMode) {
      print('Error updating goalscorers_remaining: $error');
    }
  }
}


  // Step 3: Fetch updated leaderboard data (users and their remaining footballers)
  Future<void> fetchLeaderboardData() async {
    try {
      // Fetch user data including the updated goalscorers_remaining
      final response = await supabase
          .from('competition_participants')
          .select('user_id, users!inner(username), goalscorers_remaining')
          .eq('competition_id', widget.competitionId);

      // Update the state with the fetched participants
      setState(() {
        participants = response;
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
        title: const Text('Leaderboard - Footballers Remaining'),
      ),
      body: participants.isEmpty
          ? const Center(
              child: Text('No user data available.'),
            )
          : ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final user = participants[index];
                final username = user['users']['username'];
                final goalscorersRemaining = user['goalscorers_remaining'];

                return ListTile(
                  title: Text('User: $username'),
                  subtitle: Text('Footballers remaining: $goalscorersRemaining'),
                );
              },
            ),
    );
  }
}
