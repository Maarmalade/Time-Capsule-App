import 'package:flutter/material.dart';
import '../../widgets/home_panel_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _navigate(BuildContext context, String route, String pageName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(pageName),
            leading: BackButton(),
          ),
          body: Center(
            child: Text('You are now in $pageName', style: TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Home Page',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  children: [
                    HomePanelCard(
                      text: 'Access Memory',
                      onTap: () => _navigate(context, '/memory_album', 'Memory Album'),
                    ),
                    HomePanelCard(
                      text: 'Sent Time Leap Messages',
                      onTap: () => _navigate(context, '/time_leap_messages', 'Time Leap Messages'),
                    ),
                    HomePanelCard(
                      text: 'Take Digital Diary',
                      onTap: () => _navigate(context, '/digital_diary', 'Digital Diary'),
                    ),
                    HomePanelCard(
                      text: "1 year ago, you've\nvisited Japan",
                      image: const AssetImage('assets/japan_flag.png'), // Replace with your asset if needed
                      onTap: () {}, // No action yet
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
}