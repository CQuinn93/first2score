// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MakeSelectionsScreen extends StatefulWidget {
  final String competitionId;
  final String competitionName;
  final bool isPrivate;
  final String? joinCode;

  const MakeSelectionsScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
    this.isPrivate = false,
    this.joinCode,
  });

  @override
  MakeSelectionsScreenState createState() => MakeSelectionsScreenState();
}

List<String> squads = [
  "ALL",
  "Arsenal",
  "Aston Villa",
  "Bournemouth",
  "Brentford",
  "Brighton",
  "Chelsea",
  "Crystal Palace",
  "Everton",
  "Fulham",
  "Ipswich Town",
  "Leicester",
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

const themeMainColour = Color.fromARGB(255, 0, 165, 30);
const themeSecondaryColour = Color.fromARGB(255, 10, 65, 20);
const themeBackgroundColour = Color.fromARGB(255, 0, 0, 0);
const themeTextColour = Color.fromARGB(255, 255, 255, 255);
const themeTertiarytColour = Color.fromARGB(255, 110, 110, 110);

List<String> positions = ["ALL", "Defender", "Midfielder", "Striker"];

class MakeSelectionsScreenState extends State<MakeSelectionsScreen> {
  int defendersCount = 0;
  int midfieldersCount = 0;
  int attackersCount = 0;
  List<int> selectedPlayerIds = [];
  String selectedTeam = 'ALL';
  String selectedPosition = 'ALL'; // Updated to match names
  List<Map<String, dynamic>> players = [];
  List<Map<String, dynamic>> filteredPlayers = [];
  String searchQuery = '';
  bool sortByGoals = false;
  String selectedFilter = "team";

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
    return squads[teamId];
  }

  Map<String, String> teamImageMap = {
    "Arsenal": "lib/assets/Arsenal.png",
    "Aston Villa": "lib/assets/Aston Villa.png",
    "Bournemouth": "lib/assets/Bournemouth.png",
    "Brentford": "lib/assets/Brentford.png",
    "Brighton": "lib/assets/Brighton.png",
    "Chelsea": "lib/assets/Chelsea.png",
    "Crystal Palace": "lib/assets/Crystal Palace.png",
    "Everton": "lib/assets/Everton.png",
    "Fulham": "lib/assets/Fulham.png",
    "Ipswich Town": "lib/assets/Ipswich Town.png",
    "Leicester": "lib/assets/Leicester.png",
    "Liverpool": "lib/assets/Liverpool.png",
    "Manchester City": "lib/assets/Manchester City.png",
    "Manchester United": "lib/assets/Manchester United.png",
    "Newcastle United": "lib/assets/Newcastle.png",
    "Nottingham Forest": "lib/assets/Notts Forest.png",
    "Tottenham Hotspur": "lib/assets/Tottenham.png",
    "Southampton": "lib/assets/Southampton.png",
    "West Ham United": "lib/assets/West Ham.png",
    "Wolves": "lib/assets/Wolves.png",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background of the entire Scaffold to black
      backgroundColor: themeBackgroundColour,

      // Make the AppBar transparent
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // Remove shadow/elevation
        centerTitle: true,
        title: Image.asset(
          'lib/assets/F2ScoreGreen.png', // Update this path based on your actual asset location
          height: 60, // Adjust the height as needed
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showCompetitionInfo,
          ),
        ],
      ),
      body: Stack(
        children: [
          // No need for backdrop image; setting the entire background to black
          Container(
            color: themeBackgroundColour, // Ensures the background is black
          ),
          Column(
            children: [
              _buildPositionCounters(),
              const SizedBox(height: 10),
              _buildFilters(),
              ElevatedButton(
                onPressed: _showSelections,
                child: const Text("View Selections"),
              ),
              const SizedBox(height: 5),
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
                    onPressed: _confirmSelections,
                    child: const Text("Confirm Selections"),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Function to show competition information
  void _showCompetitionInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.competitionName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Competition ID: ${widget.competitionId}'),
              if (widget.isPrivate && widget.joinCode != null)
                Text('Join Code: ${widget.joinCode}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Build player card widget
  Widget _buildPlayerCard(Map<String, dynamic> player, bool isSelected) {
    final bool hasNews = player['news'] != null && player['news'].isNotEmpty;
    final String teamName = _getTeamName(player['team'].toInt());
    final String? teamImage = teamImageMap[teamName];

    return GestureDetector(
      onTap: () {
        if (hasNews) {
          _showNewsDialog(player, isSelected);
        } else {
          _togglePlayerSelection(
            (player['id'] is int)
                ? player['id']
                : (player['id'] as double).toInt(),
            (player['position'] is int)
                ? player['position']
                : (player['position'] as double).toInt(),
          );
        }
      },
      child: Card(
        color: isSelected
            ? themeMainColour
            : themeSecondaryColour.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: hasNews
              ? const BorderSide(
                  color: Color.fromARGB(255, 255, 0, 0), width: 2.0)
              : BorderSide.none,
        ),
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: teamImage != null
                    ? AssetImage(teamImage)
                    : const AssetImage('lib/assets/default_jersey.png'),
                backgroundColor: Colors.transparent,
                radius: 20,
                child: ClipPath(
                  // Clip the image in a circular shape
                  child: teamImage != null
                      ? Image.asset(
                          teamImage,
                          fit: BoxFit
                              .cover, // Makes the image cover the circle properly
                          width:
                              40, // Adjust this as per your needs to fit the avatar
                          height:
                              40, // Adjust this as per your needs to fit the avatar
                        )
                      : const Icon(Icons.person,
                          size: 30), // If no image, show icon
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Position inside a rounded corner box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: themeSecondaryColour.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        _getPositionName(player['position'].toInt()),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${player['first_name']} ${player['last_name']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected
                            ? Colors.white
                            : const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.sports_soccer,
                              color: Color.fromARGB(255, 255, 255, 255)),
                          Text(
                            '${(player['expected_goals'] ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        children: [
                          const Icon(Icons.assistant,
                              color: Color.fromARGB(255, 255, 255, 255)),
                          Text(
                            '${(player['expected_assists'] ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Function to show a dialog when a player with news is selected
  void _showNewsDialog(Map<String, dynamic> player, bool isSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${player['first_name']} ${player['last_name']}'),
          content: Text(player['news']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _togglePlayerSelection(
                  (player['id'] is int)
                      ? player['id']
                      : (player['id'] as double).toInt(),
                  (player['position'] is int)
                      ? player['position']
                      : (player['position'] as double).toInt(),
                );
              },
              child: const Text('Select Anyway'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Helper widget to build position counters
  Widget _buildPositionCounters() {
    return Container(
      padding: const EdgeInsets.all(6.0),
      margin: const EdgeInsets.only(
        top: 10.0,
        left: 8.0,
        right: 8.0,
      ),
      decoration: BoxDecoration(
        color: themeTertiarytColour.withOpacity(0.5), // Background color
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white, // Border color for the entire container
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          // Defender Counter
          Expanded(
            child: _positionCounter(
                'DEF', defendersCount, 3, defendersCount >= 3, themeMainColour),
          ),
          const SizedBox(width: 5), // Small gap between counters

          // Remaining Selections Counter
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.0),
                borderRadius: BorderRadius.circular(5),
                color: themeSecondaryColour,
              ),
              child: Column(
                children: [
                  const Text(
                    'Remaining:',
                    style: TextStyle(
                      color: themeTextColour,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${20 - selectedPlayerIds.length}',
                    style: const TextStyle(
                      color: themeTextColour,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5), // Small gap between counters

          // Midfielder Counter
          Expanded(
            child: _positionCounter(
                'MID', midfieldersCount, 7, midfieldersCount >= 7, Colors.blue),
          ),
        ],
      ),
    );
  }

// Helper widget to create position counter
  Widget _positionCounter(String position, int count, int requiredCount,
      bool highlight, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        border: Border.all(
            color: highlight ? borderColor : themeMainColour, width: 1.5),
        borderRadius: BorderRadius.circular(5),
        color: themeSecondaryColour,
      ),
      child: Column(
        children: [
          Text(
            position,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            '$count/$requiredCount',
            style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

// Build filter widgets for team and position
  Widget _buildFilters() {
    return Column(
      children: [
        // Toggle between Team and Position filters
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _filterToggleButton("Team", selectedFilter == "Team", () {
              setState(() {
                selectedFilter = "Team";
              });
            }),
            _filterToggleButton("Position", selectedFilter == "Position", () {
              setState(() {
                selectedFilter = "Position";
              });
            }),
          ],
        ),
        const SizedBox(
            height: 16), // Space between the toggle buttons and filter

        // Show team jerseys or position buttons based on the selected filter
        selectedFilter == "Team" ? _buildTeamIcons() : _buildPositionButtons(),

        // Sort by Predicted Goals checkbox
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Sort by Predicted Goals",
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            Checkbox(
              value: sortByGoals,
              onChanged: (value) {
                setState(() {
                  sortByGoals = value ?? false;
                  _filterPlayers(); // Apply filter when checkbox is toggled
                });
              },
            ),
          ],
        ),
      ],
    );
  }

// Toggle button for switching between Team and Position filters
  Widget _filterToggleButton(
      String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? themeMainColour : themeSecondaryColour,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? themeTextColour : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

// Build the team jerseys row with team names underneath
  Widget _buildTeamIcons() {
    return SizedBox(
      height: 80, // Adjust the height as needed for smaller icons
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Horizontally scrollable row
        itemCount: teamImageMap.length + 1, // +1 to include "All Players"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All Players" football icon
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedTeam = "ALL"; // Show all players when clicked
                  _filterPlayers(); // Apply the filter
                });
              },
              child: Column(
                children: [
                  // Football Icon
                  Container(
                    width: 40, // Smaller square icon
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedTeam == "ALL"
                            ? themeMainColour
                            : Colors.transparent,
                        width: 2, // Highlight when selected
                      ),
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.transparent, // Transparent background
                    ),
                    child: const Icon(
                      Icons.sports_soccer, // Football icon
                      color: Colors.white,
                      size: 24, // Adjust the size of the football icon
                    ),
                  ),
                  const SizedBox(height: 4),

                  // "All Players" label
                  SizedBox(
                    width: 50, // Set the width for text wrapping
                    child: Text(
                      "All Players",
                      style: TextStyle(
                        fontSize: 7, // Smaller font size
                        color: selectedTeam == "ALL"
                            ? themeMainColour // Highlight when selected
                            : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2, // Allow text to wrap to two lines if needed
                      overflow: TextOverflow.ellipsis, // Truncate if too long
                    ),
                  ),
                ],
              ),
            );
          }

          // Display team jerseys and names for the rest of the teams
          String teamName =
              teamImageMap.keys.elementAt(index - 1); // Adjust for 0-index
          String teamImage = teamImageMap[teamName]!;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTeam = teamName; // Filter by selected team
                _filterPlayers(); // Apply the filter
              });
            },
            child: Column(
              children: [
                // Team Jersey Icon
                Container(
                  width: 40, // Smaller square icon
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedTeam == teamName
                          ? themeMainColour
                          : Colors.transparent,
                      width: 2, // Highlight selected team
                    ),
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.transparent, // Transparent background
                  ),
                  child: Image.asset(
                    teamImage,
                    fit: BoxFit.contain, // Contain within the square
                  ),
                ),
                const SizedBox(height: 4),

                // Team Name with wrapping text
                SizedBox(
                  width: 50, // Set the width for text wrapping
                  child: Text(
                    teamName,
                    style: TextStyle(
                      fontSize: 7, // Smaller font size
                      color: selectedTeam == teamName
                          ? themeMainColour // Highlight selected team
                          : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2, // Allow text to wrap to two lines if needed
                    overflow: TextOverflow.ellipsis, // Truncate if too long
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

// Build the position buttons (All, Defender, Midfielder, Striker)
  Widget _buildPositionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: positions.map((position) {
        return ElevatedButton(
          onPressed: () {
            setState(() {
              selectedPosition = position; // Filter by position
              _filterPlayers(); // Apply the filter
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedPosition == position
                ? themeMainColour
                : themeSecondaryColour,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          ),
          child: Text(
            position,
            style: TextStyle(
              color:
                  selectedPosition == position ? themeTextColour : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Function to show the overlay for selections
  void _showSelections() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.white.withOpacity(0.9), // Semi-transparent white background
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Your Selections",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: selectedPlayerIds.length,
                      itemBuilder: (context, index) {
                        final playerId = selectedPlayerIds[index];
                        final player = players
                            .firstWhere((element) => element['id'] == playerId);
                        return ListTile(
                          title: Text(
                            '${player['first_name']} ${player['last_name']}',
                          ),
                          subtitle: Text(
                            '${_getTeamName(player['team'].toInt())} - ${_getPositionName(player['position'].toInt())}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Function to confirm selections and insert into the database
  void _confirmSelections() async {
    if (selectedPlayerIds.length != 20) {
      _showErrorDialog('You must select exactly 20 players.');
      return;
    }

    if (defendersCount < 3 || midfieldersCount < 7) {
      _showErrorDialog('You must have at least 3 defenders and 7 midfielders.');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showErrorDialog('User not authenticated.');
      return;
    }

    final competitionId = widget.competitionId;

    final List<Map<String, dynamic>> entries =
        selectedPlayerIds.map((playerId) {
      final player = players.firstWhere((element) => element['id'] == playerId);
      return {
        'competition_id': competitionId,
        'user_id': user.id,
        'player_id': playerId,
        'position': player['position'],
      };
    }).toList();

    try {
      final response =
          await Supabase.instance.client.from('selections').insert(entries);

      if (response != null && response.error != null) {
        _showErrorDialog(
            'Failed to confirm selections: ${response.error!.message}');
      } else {
        _showSuccessDialog('Selections confirmed successfully!');
      }
    } catch (error) {
      _showErrorDialog('An error occurred: $error');
    }
  }

  // Function to show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to another screen or refresh the selections
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
