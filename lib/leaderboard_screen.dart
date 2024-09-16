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
  List<double> goalscorers = [];
  int currentGameweek = 0;
  int startGameweek = 0;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchLeaderboardData();
  }

  // Step 1: Fetch the usernames and initialize competition stats
  Future<void> fetchCompetitionStats() async {
    try {
      final response = await supabase
          .from('competition_participants')
          .select('user_id, users!inner(username)')
          .eq('competition_id', widget.competitionId);

      competitionStats = response.map<Map<String, dynamic>>((entry) {
        return {
          'username': entry['users']['username'],
          'remainingFootballers': 20,
        };
      }).toList();
      
      if (kDebugMode) {
        print('Users in competition: $competitionStats');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching competition stats: $error');
      }
    }
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

  // Step 3: Fetch users' selections (footballer_id, username, hasScored)
  Future<void> fetchUsersSelections() async {
    try {
      final response = await supabase
          .from('selections')
          .select('player_id, users!inner(username), hasScored, gameweek_scored')
          .eq('competition_id', widget.competitionId);

      usersSelections = response.map<Map<String, dynamic>>((selection) {
        return {
          'player_id': selection['player_id'],
          'username': selection['users']['username'],
          'hasScored': selection['hasScored'],
          'gameweek_scored': selection['gameweek_scored'],
        };
      }).toList();
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching users selections: $error');
      }
    }
  }

  // Step 4: Fetch footballers who scored since the start gameweek
  Future<void> fetchGoalscorers() async {
    try {
      final footballersResponse = await supabase
          .from('footballers')
          .select('id')
          .gte('last_goal_scored', startGameweek)
          .not('last_goal_scored', 'is', null);

      goalscorers = footballersResponse.map<double>((f) => f['id']).toList();

      // Update the `hasScored` field and the `gameweek_scored` column for the selections
      for (var selection in usersSelections) {
        if (goalscorers.contains(selection['player_id']) && selection['hasScored'] == false) {
          await supabase
              .from('selections')
              .update({
                'hasScored': true,
                'gameweek_scored': currentGameweek,
              })
              .eq('player_id', selection['player_id'])
              .eq('competition_id', widget.competitionId);
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching footballers: $error');
      }
    }
  }

  // Step 5: Filter users' selections and update competition stats
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
    await fetchGameweekInfo();
    await fetchCompetitionStats();
    await fetchUsersSelections();
    await fetchGoalscorers();
    await updateCompetitionStats();
  }

  // Button action to show user selections
  void showUserSelections(String username) {
    final selections = usersSelections.where((selection) => selection['username'] == username).toList();
    if (kDebugMode) {
      print("$username's selections: $selections");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard - Footballers Remaining'),
      ),
      body: competitionStats.isEmpty
          ? const Center(
              child: Text('No user data available.'),
            )
          : ListView.builder(
              itemCount: competitionStats.length,
              itemBuilder: (context, index) {
                final user = competitionStats[index];
                final username = user['username'];
                final remainingFootballers = user['remainingFootballers'];
                final rank = index + 1;

                String subtitleText;
                if (currentGameweek < startGameweek) {
                  subtitleText = remainingFootballers == 0 ? 'Awaiting Selections' : 'Selections Locked In';
                } else {
                  subtitleText = '$remainingFootballers footballers remaining';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          rank.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(subtitleText),
                      trailing: ElevatedButton(
                        onPressed: () => showUserSelections(username),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
