import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final response = await Supabase.instance.client
          .from('competitions')
          .select()
          .eq('join_code', joinCode)
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have joined the competition!')),
        );
        // Add logic to insert the user into the competition's participants
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
