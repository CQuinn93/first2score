import 'dart:math';
import 'package:application/dashboard_screen.dart';
import 'package:application/join_competition_view.dart';
import 'package:application/make_selections_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateJoinView extends StatefulWidget {
  const CreateJoinView({super.key});

  @override
  CreateJoinViewState createState() => CreateJoinViewState();
}

class CreateJoinViewState extends State<CreateJoinView> {
  // Color theme variables
  final themeMainColour = const Color.fromARGB(255, 0, 165, 30);
  final themeSecondaryColour = const Color.fromARGB(255, 10, 65, 20);
  final themeBackgroundColour = const Color.fromARGB(255, 0, 0, 0);
  final themeTextColour = const Color.fromARGB(255, 255, 255, 255);
  final themeHintTextColour = const Color.fromARGB(255, 150, 150, 150);

  int _selectedTabIndex = 0; // Tracks the selected tab
  final _competitionNameController = TextEditingController();
  int? _selectedGameWeek;
  String _competitionType = 'open'; // 'open', 'code', 'private'
  bool _agreedToTerms = false; // Track if user has agreed to terms
  String? _joinCode;

  // Switch between "Create" and "Join" tabs
  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  // Generates a 7-character alphanumeric join code
  String _generateJoinCode() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(7, (_) {
      final index = Random().nextInt(characters.length);
      return characters.codeUnitAt(index);
    }));
  }

  // Handles competition creation
  void _createCompetition() async {
    final name = _competitionNameController.text.trim();
    final user = Supabase.instance.client.auth.currentUser;

    if (name.isEmpty ||
        _selectedGameWeek == null ||
        user == null ||
        !_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and accept the terms.')),
      );
      return;
    }
    // Generate a join code if the competition is private or code-join
    if (_competitionType == 'code' || _competitionType == 'private') {
      _joinCode = _generateJoinCode();
    } else {
      _joinCode = null;
    }

    try {
      // Insert the competition details into the database
      final List<Map<String, dynamic>> competitionResponse =
          await Supabase.instance.client.from('competitions').insert({
        'competition_name': name,
        'game_week': _selectedGameWeek,
        'competition_type': _competitionType, // New field for type
        'join_code': _joinCode,
        'organizer_id': user.id,
        'is_complete': false,
      }).select();

      // Check if the competition was created successfully
      if (competitionResponse.isNotEmpty) {
        final competitionId = competitionResponse.first['id'] as String;
        final competitionName =
            competitionResponse.first['competition_name'] as String;

        // Insert the creator into the competition_participants table as the owner
        await Supabase.instance.client.from('competition_participants').insert({
          'competition_id': competitionId,
          'user_id': user.id,
          'is_owner': true,
        });

        // Show success pop-up with join code if needed
        _showSuccessPopup(competitionId, competitionName);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create competition.')),
          );
        }
      }
    } catch (error, stackTrace) {
      // Log the error and stack trace for better understanding
      if (kDebugMode) {
        print("Exception: $error");
      }
      if (kDebugMode) {
        print("StackTrace: $stackTrace");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  void _showSuccessPopup(String competitionId, String competitionName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeBackgroundColour, // Dark background
          title: Center(
            child: Text('Success',
                style: TextStyle(color: themeTextColour)), // White text
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                'Your competition has been created.',
                textAlign: TextAlign.center,
                style: TextStyle(color: themeTextColour), // White text
              ),
              if (_competitionType != 'open')
                Column(
                  children: [
                    Text('Join Code: $_joinCode',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: themeTextColour)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _joinCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Join code copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy,
                          color: Colors.green), // Green icon
                      label: Text('Copy Join Code',
                          style:
                              TextStyle(color: themeMainColour)), // Green text
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Make selections now?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeTextColour), // White bold text
                    ),
                  ],
                ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 120, // Set a fixed width for both buttons
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToCompetitionDetail(
                        competitionId,
                        competitionName,
                        _competitionType,
                        _joinCode,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeMainColour, // Green button
                    ),
                    child: const Text(
                      'Let\'s Go',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text color
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 120, // Set the same width for both buttons
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToMyCompetitions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeMainColour, // Green button
                    ),
                    child: const Text(
                      'Later',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text color
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _navigateToCompetitionDetail(String competitionId,
      String competitionName, String competitionType, String? joinCode) {
    // Use push instead of pushReplacement to retain the back button functionality
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MakeSelectionsScreen(
          competitionId: competitionId,
          competitionName: competitionName,
          isPrivate: competitionType == 'private',
          joinCode: joinCode,
        ),
      ),
    );
  }

  void _navigateToMyCompetitions() {
    // Keep pushReplacement here for navigating to the dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Adjust for keyboard
      backgroundColor: themeBackgroundColour, // Dark theme background
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabButton('Create', 0),
              _tabButton('Join', 1),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _createView(), // Create competition view
                _joinView(), // Join competition view
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab button for switching between Create and Join views
  Widget _tabButton(String title, int index) {
    bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5.0, 0, 5.0, 0),
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? themeSecondaryColour : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: themeMainColour),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isActive ? themeTextColour : themeMainColour,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
      ),
    );
  }

  // Create competition view
  Widget _createView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a Competition',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeTextColour),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _competitionNameController,
              style: TextStyle(color: themeTextColour), // White text color
              decoration: InputDecoration(
                labelText: 'Competition Name',
                labelStyle:
                    TextStyle(color: themeHintTextColour), // Grey label text
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: themeTextColour), // White border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeMainColour), // Green border when focused
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Game Week Dropdown styled like text fields
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Game Week',
                labelStyle: TextStyle(color: themeHintTextColour),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: themeTextColour),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedGameWeek,
                  dropdownColor: themeBackgroundColour,
                  style: TextStyle(color: themeTextColour),
                  items: List.generate(36, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text('Game Week ${index + 1}'),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedGameWeek = value;
                    });
                  },
                  hint: Text('Select Game Week',
                      style: TextStyle(color: themeHintTextColour)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Message asking how users will join the competition
            Text(
              'How would you like others to join your competition?',
              style: TextStyle(color: themeTextColour),
            ),
            const SizedBox(height: 10),

            // Join options (Open, Join via Code, Private)
            Column(
              children: [
                ListTile(
                  title:
                      const Text('Open', style: TextStyle(color: Colors.white)),
                  leading: Radio(
                    value: 'open',
                    groupValue: _competitionType,
                    onChanged: (value) {
                      setState(() {
                        _competitionType = value!;
                      });
                    },
                    activeColor: themeMainColour,
                  ),
                ),
                ListTile(
                  title: const Text('Join via Code',
                      style: TextStyle(color: Colors.white)),
                  leading: Radio(
                    value: 'code',
                    groupValue: _competitionType,
                    onChanged: (value) {
                      setState(() {
                        _competitionType = value!;
                      });
                    },
                    activeColor: themeMainColour,
                  ),
                ),
                ListTile(
                  title: const Text('Private',
                      style: TextStyle(color: Colors.white)),
                  leading: Radio(
                    value: 'private',
                    groupValue: _competitionType,
                    onChanged: (value) {
                      setState(() {
                        _competitionType = value!;
                      });
                    },
                    activeColor: themeMainColour,
                  ),
                ),
              ],
            ),

            // Dynamic message based on competition type
            if (_competitionType == 'open')
              _buildInfoMessage(
                  'You have selected Open. This means that your competition is open to all users who want to play. It will appear in the Open Competitions tab.'),
            if (_competitionType == 'code')
              _buildInfoMessage(
                  'You have selected Join via Code. Users will require a code to join your competition.'),
            if (_competitionType == 'private')
              _buildInfoMessage(
                  'You have selected Private. Users will require a code to apply for your competition and will need to be verified by you.'),

            const SizedBox(height: 20),

            // Checkbox and confirmation message
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (bool? value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                  activeColor: themeSecondaryColour,
                  checkColor: themeTextColour,
                ),
                Expanded(
                  child: Text(
                    'I have read and understood the competition naming rules and restrictions.',
                    style: TextStyle(color: themeTextColour),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Centered Create Competition Button
            Center(
              child: ElevatedButton(
                onPressed: _createCompetition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeMainColour, // Green button
                ),
                child: Text('Create Competition',
                    style: TextStyle(color: themeTextColour)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to display dynamic info message
  Widget _buildInfoMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeSecondaryColour.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeMainColour),
      ),
      child: Text(
        message,
        style: TextStyle(color: themeTextColour),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Join competition view
  Widget _joinView() {
    return const JoinCompetitionView(); // Link to join view
  }
}