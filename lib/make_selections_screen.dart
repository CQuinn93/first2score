import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MakeSelectionsScreen extends StatefulWidget {
  const MakeSelectionsScreen({super.key});

  @override
  MakeSelectionsScreenState createState() => MakeSelectionsScreenState();
}

class MakeSelectionsScreenState extends State<MakeSelectionsScreen> {
  // Player position counters
  int defendersCount = 0;
  int midfieldersCount = 0;
  int attackersCount = 0;

  // Example list to hold selected players
  List<int> selectedPlayerIds = [];

  // Placeholder for filter options (e.g., teams or positions)
  String? selectedTeam;
  String? selectedPosition;

  // List of players fetched from the database
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    _fetchPlayersFromDatabase(); // Fetch players on initialization
  }

  // Function to fetch players from Supabase
  Future<void> _fetchPlayersFromDatabase() async {
    try {
      final response = await Supabase.instance.client
          .from('players') // Assuming the table is called 'players'
          .select()
          .or('position.eq.2,position.eq.3,position.eq.4'); // Use 'in' for filtering multiple values

      print('Error fetching players: ${response}');
    } catch (error) {
      print('Error: $error');
    }
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
    const teams = [
      "Arsenal",
      "Aston Villa",
      "Bournemouth",
      "Brentford",
      "Brighton & Hove Albion",
      "Chelsea",
      "Crystal Palace",
      "Everton",
      "Fulham",
      "Ipswich Town",
      "Leicester City",
      "Liverpool",
      "Manchester City",
      "Manchester United",
      "Newcastle United",
      "Nottingham Forest",
      "Southampton",
      "Tottenham Hotspur",
      "West Ham United",
      "Wolves"
    ];
    return teams[teamId - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C6E47),
        title: const Text("Make Your Selections"),
        actions: [
          Row(
            children: [
              _positionCounter('DEF', defendersCount),
              _positionCounter('MID', midfieldersCount),
              _positionCounter('ATT', attackersCount),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildFilters(),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final isSelected = selectedPlayerIds.contains(player['id']);
                return _buildPlayerCard(player, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build player card
  Widget _buildPlayerCard(Map<String, dynamic> player, bool isSelected) {
    return Card(
      color: isSelected ? const Color(0xFF1C6E47) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
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
                    'Team: ${_getTeamName(player['team'])}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Position: ${_getPositionName(player['position'])}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Expected Goals: ${player['expected_goa']}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Expected Assists: ${player['expected_assi']}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  _togglePlayerSelection(player['id'], player['position']),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? Colors.grey
                    : const Color(0xFF1C6E47), // Green color
                foregroundColor: Colors.white,
              ),
              child: Text(isSelected ? "Remove" : "Add to Team"),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for position counters
  Widget _positionCounter(String position, int count) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Text(
            position,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '$count',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Filter options for players by team or position
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: selectedTeam,
              hint: const Text("Filter by Team"),
              items: const [
                DropdownMenuItem(value: "Team A", child: Text("Team A")),
                DropdownMenuItem(value: "Team B", child: Text("Team B")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedTeam = value;
                });
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: DropdownButton<String>(
              value: selectedPosition,
              hint: const Text("Filter by Position"),
              items: const [
                DropdownMenuItem(value: "DEF", child: Text("DEF")),
                DropdownMenuItem(value: "MID", child: Text("MID")),
                DropdownMenuItem(value: "ATT", child: Text("ATT")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedPosition = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
