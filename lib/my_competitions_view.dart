import 'package:flutter/material.dart';

class MyCompetitionsView extends StatelessWidget {
  const MyCompetitionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'My Competitions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        // Example of competition listing
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1C6E47)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Competition Name: WC Prediction Competition \'22'),
              SizedBox(height: 8),
              Text('Organizer: JSMITH99'),
              SizedBox(height: 8),
              Text('No. of Entries: 18'),
              SizedBox(height: 8),
              Text('Leaders Points: 35'),
              SizedBox(height: 8),
              Text('Current Pos: 8th'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Example of leaderboard section within My Competitions
        _leaderboard(),
      ],
    );
  }

  Widget _leaderboard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1C6E47)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _leaderboardRow('USERNAME', 'PL', 'W', 'D', 'L', 'GD', 'P'),
              const Divider(),
              _leaderboardRow('SWAPGN23', '15', '10', '-', '-', '-', '25'),
              _leaderboardRow('JTWOODS', '16', '7', '-', '-', '-', '23'),
              _leaderboardRow('ADGAV11', '15', '7', '-', '-', '-', '22'),
              _leaderboardRow('JSMITH99', '12', '7', '-', '-', '-', '19'),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            // Handle view full leaderboard action
          },
          child: const Text(
            'View Full Leaderboard',
            style: TextStyle(color: Color(0xFF1C6E47)),
          ),
        ),
      ],
    );
  }

  Widget _leaderboardRow(String username, String pl, String w, String d,
      String l, String gd, String p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(username),
        Text(pl),
        Text(w),
        Text(d),
        Text(l),
        Text(gd),
        Text(p),
      ],
    );
  }
}
