import 'package:flutter/material.dart';

import '../diary/digital_diary_page.dart';
import '../../widgets/home_panel_card.dart';
import 'home_panel_grid.dart';
import '../memory_album/memory_album_page.dart';
import '../../services/diary_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                child: HomePanelGrid(
                  diaryService: DiaryService(),
                  navigate: (context, route, pageName) {
                    if (route == '/digital_diary') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DigitalDiaryPage()),
                      );
                    } else if (route == '/memory_album') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MemoryAlbumPage()),
                      );
                    } else {
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}