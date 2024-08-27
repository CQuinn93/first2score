// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MakeSelectionsScreen extends StatefulWidget {
  const MakeSelectionsScreen({super.key});

  @override
  MakeSelectionsScreenState createState() => MakeSelectionsScreenState();
}

List<String> squads = [
  "ALL", // Added 'ALL' as a filter option for teams
  "Arsenal",
  "Aston Villa",
  "Bournemouth",
  "Brentford",
  "Brighton",
  "Chelsea",
  "Crystal Palace",
  "Everton",
  "Fulham",
  "Burnley",
  "Luton Town",
  "Liverpool",
  "Manchester City",
  "Manchester United",
  "Newcastle United",
  "Nottingham Forest",
  "Sheffield United",
  "Tottenham Hotspur",
  "West Ham United",
  "Wolves"
];

class MakeSelectionsScreenState extends State<MakeSelectionsScreen> {
  int defendersCount = 0;
  int midfieldersCount = 0;
  int attackersCount = 0;
  List<int> selectedPlayerIds = [];
  String selectedTeam = 'ALL'; // Default team filter is 'ALL'
  String selectedPosition = 'ALL'; // Default to show all positions
  List<Map<String, dynamic>> players = [];
  List<Map<String, dynamic>> filteredPlayers = []; // Filtered players array
  String searchQuery = '';
  bool sortByGoals = false;

  @override
  void initState() {
    super.initState();
    _fetchPlayersFromDatabase();
  }

  // Function to fetch players from Supabase
  Future<void> _fetchPlayersFromDatabase() async {
    try {
      final response = await Supabase.instance.client
          .from('footballers')
          .select()
          .neq('position', 1); // Ignore goalkeepers

      setState(() {
        players = List<Map<String, dynamic>>.from(response);
        _filterPlayers(); // Filter the players immediately after fetching
      });
    } catch (error) {
      print('Error: $error');
    }
  }

  // Filter players based on selected team, position, and search query
  void _filterPlayers() {
    setState(() {
      filteredPlayers = players.where((player) {
        final matchesTeam = selectedTeam == 'ALL' ||
            _getTeamName(player['team'].toInt()) == selectedTeam;
        final matchesPosition = selectedPosition == 'ALL' ||
            _getPositionName(player['position'].toInt()) == selectedPosition;
        final matchesSearch = searchQuery.isEmpty ||
            '${player['first_name']} ${player['last_name']}'
                .toLowerCase()
                .contains(searchQuery.toLowerCase());

        return matchesTeam && matchesPosition && matchesSearch;
      }).toList();

      // Sort by expected goals if the option is selected
      if (sortByGoals) {
        filteredPlayers.sort((a, b) {
          final xGoalsA = a['expected_goals'] ?? 0.0;
          final xGoalsB = b['expected_goals'] ?? 0.0;
          return xGoalsB.compareTo(xGoalsA); // Sort in descending order
        });
      }
    });
  }

  // Function to add/remove a player from the team
  void _togglePlayerSelection(int playerId, int positionId) {
    setState(() {
      if (selectedPlayerIds.contains(playerId)) {
        selectedPlayerIds.remove(playerId);
        _updatePositionCounter(positionId, remove: true);
      } else {
        selectedPlayerIds.add(playerId);
        _updatePositionCounter(positionId);
      }
    });
  }

  // Helper function to update the position counters
  void _updatePositionCounter(int positionId, {bool remove = false}) {
    if (positionId == 2) {
      defendersCount += remove ? -1 : 1;
    } else if (positionId == 3) {
      midfieldersCount += remove ? -1 : 1;
    } else if (positionId == 4) {
      attackersCount += remove ? -1 : 1;
    }
  }

  // Map position number to position name
  String _getPositionName(int positionId) {
    switch (positionId) {
      case 1:
        return 'Goalkeeper';
      case 2:
        return 'Defender';
      case 3:
        return 'Midfielder';
      case 4:
        return 'Striker';
      default:
        return 'Unknown';
    }
  }

  // Map team number to team name
  String _getTeamName(int teamId) {
    return squads[teamId]; // Update to reflect the addition of 'ALL'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C6E47),
        title: const Text("Make Your Selections"),
      ),
      body: Column(
        children: [
          _buildPositionCounters(),
          const SizedBox(height: 10),
          _buildFilters(),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPlayers.length,
              itemBuilder: (context, index) {
                final player = filteredPlayers[index];
                final isSelected = selectedPlayerIds.contains(player['id']);
                return _buildPlayerCard(player, isSelected);
              },
            ),
          ),
          if (selectedPlayerIds.length == 20)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Handle confirm action
                },
                child: const Text("Confirm Selections"),
              ),
            ),
        ],
      ),
    );
  }

  // Build player card widget
  Widget _buildPlayerCard(Map<String, dynamic> player, bool isSelected) {
    return GestureDetector(
      onTap: () => _togglePlayerSelection(
        (player['id'] is int) ? player['id'] : (player['id'] as double).toInt(),
        (player['position'] is int)
            ? player['position']
            : (player['position'] as double).toInt(),
      ),
      child: Card(
        color: isSelected ? const Color(0xFF1C6E47) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(player['profile_pic_url'] ?? ''),
                backgroundColor: Colors.grey[200],
                radius: 25,
                child: player['profile_pic_url'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${player['first_name']} ${player['last_name']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _getPositionName(player['position'].toInt()),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.sports_soccer,
                                    color: Colors.grey),
                                Text(
                                  '${(player['expected_goals'] ?? 0.0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Column(
                              children: [
                                const Icon(Icons.assistant, color: Colors.grey),
                                Text(
                                  '${(player['expected_assists'] ?? 0.0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getTeamName(player['team'].toInt()),
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (player['news'] != null && player['news'].isNotEmpty)
                      Text(
                        player['news'],
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build position counters
  Widget _buildPositionCounters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _positionCounter('DEF', defendersCount, defendersCount >= 3),
          _positionCounter('MID', midfieldersCount, midfieldersCount >= 7),
          _positionCounter('ATT', attackersCount, false),
          _totalCounter(),
        ],
      ),
    );
  }

  // Helper widget to create position counter
  Widget _positionCounter(String position, int count, bool highlight) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: highlight ? Colors.green : Colors.black),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Text(
            position,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
          Text(
            '$count',
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  // Helper widget to show the total counter of selected players
  Widget _totalCounter() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          const Text(
            'Total',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          Text(
            '${selectedPlayerIds.length}/20',
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  // Build filter widgets for team, position, and search bar
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedTeam,
                  hint: const Text("Filter by Team"),
                  items: squads.map((String team) {
                    return DropdownMenuItem(
                      value: team,
                      child: Text(team),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTeam = value ?? 'ALL';
                      _filterPlayers(); // Apply filters
                    });
                  },
                ),
                DropdownButton<String>(
                  value: selectedPosition,
                  hint: const Text("Filter by Position"),
                  items: const [
                    DropdownMenuItem(value: "DEF", child: Text("DEF")),
                    DropdownMenuItem(value: "MID", child: Text("MID")),
                    DropdownMenuItem(value: "ATT", child: Text("ATT")),
                    DropdownMenuItem(value: "ALL", child: Text("ALL")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPosition = value ?? 'ALL';
                      _filterPlayers(); // Apply filters
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search Player',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      _filterPlayers(); // Apply filters
                    });
                  },
                ),
                Row(
                  children: [
                    const Text("Sort by xGoals"),
                    Checkbox(
                      value: sortByGoals,
                      onChanged: (value) {
                        setState(() {
                          sortByGoals = value ?? false;
                          _filterPlayers(); // Apply filters
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
