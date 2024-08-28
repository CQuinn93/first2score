// ignore_for_file: avoid_print

import 'package:application/make_selections_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'join_competition_view.dart';

class CreateJoinView extends StatefulWidget {
  const CreateJoinView({super.key});

  @override
  CreateJoinViewState createState() => CreateJoinViewState();
}

class CreateJoinViewState extends State<CreateJoinView> {
  int _selectedTabIndex = 0; // Tracks the selected tab
  final _competitionNameController = TextEditingController();
  int? _selectedGameWeek;
  bool _isPrivate = false;
  String? _joinCode;

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  String _generateJoinCode() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(7, (_) {
      final index = Random().nextInt(characters.length);
      return characters.codeUnitAt(index);
    }));
  }

  Future<bool> _isCompetitionNameUnique(String name) async {
    final response = await Supabase.instance.client
        .from('competitions')
        .select('id')
        .eq('competition_name', name);

    return response.isEmpty;
  }

  void _createCompetition() async {
    final name = _competitionNameController.text.trim();
    final user = Supabase.instance.client.auth.currentUser;

    if (name.isEmpty || _selectedGameWeek == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    if (!await _isCompetitionNameUnique(name)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Competition name already exists.')),
        );
        return;
      }
    }

    if (_isPrivate) {
      _joinCode = _generateJoinCode();
    } else {
      _joinCode = null;
    }

    try {
      final List<Map<String, dynamic>> competitionResponse =
          await Supabase.instance.client.from('competitions').insert({
        'competition_name': name,
        'game_week': _selectedGameWeek,
        'is_private': _isPrivate,
        'join_code': _joinCode,
        'organizer_id': user.id,
        'is_complete': false,
      }).select();

      if (competitionResponse.isNotEmpty) {
        final competitionId = competitionResponse.first['id'];

        await Supabase.instance.client.from('competition_participants').insert({
          'competition_id': competitionId,
          'user_id': user.id,
          'is_owner': true,
        });

        _showSuccessPopup(competitionId, name, _joinCode, _isPrivate);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create competition.')),
          );
        }
      }
    } catch (error, stackTrace) {
      print("Exception: $error");
      print("StackTrace: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  void _showSuccessPopup(String competitionId, String competitionName,
      String? joinCode, bool isPrivate) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text('Your competition has been created.'),
              if (isPrivate)
                Column(
                  children: [
                    Text('Join Code: $joinCode'),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: joinCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Join code copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Join Code'),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToCompetitionDetail(
                    competitionId, competitionName, isPrivate, joinCode);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCompetitionDetail(String competitionId,
      String competitionName, bool isPrivate, String? joinCode) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MakeSelectionsScreen(
          competitionId: competitionId,
          competitionName: competitionName,
          isPrivate: isPrivate,
          joinCode: joinCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                _createView(),
                _joinView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1C6E47) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1C6E47)),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isActive ? Colors.white : const Color(0xFF1C6E47),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _createView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a Competition',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _competitionNameController,
              decoration: const InputDecoration(
                labelText: 'Competition Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<int>(
              value: _selectedGameWeek,
              items: List.generate(10, (index) {
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
              hint: const Text('Select Game Week'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Private'),
                Switch(
                  value: _isPrivate,
                  onChanged: (value) {
                    setState(() {
                      _isPrivate = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createCompetition,
              child: const Text('Create Competition'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _joinView() {
    return const JoinCompetitionView();
  }
}
