import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpenCompetitionsView extends StatelessWidget {
  const OpenCompetitionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('competitions')
          .select()
          .eq('is_private', false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Failed to load competitions.'));
        }

        final competitions = snapshot.data!;

        return ListView.builder(
          itemCount: competitions.length,
          itemBuilder: (context, index) {
            final competition = competitions[index];
            return ListTile(
              title: Text(competition['competition_name']),
              subtitle: Text('Starting Week: ${competition['game_week']}'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Joined ${competition['competition_name']}')),
                );
                // Add logic to join this competition
              },
            );
          },
        );
      },
    );
  }
}
