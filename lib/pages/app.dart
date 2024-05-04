import 'package:flutter/material.dart';
import 'package:project_app/pages/contribution.dart';
import 'package:project_app/pages/esl.dart';
import 'package:project_app/pages/transcription.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // ignore: prefer_typing_uninitialized_variables
  late var _selectedPageIndex;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _selectedPageIndex = 0;
    _pages = [
      const TranscriptionPage(),
      const ESLPage(),
      const ContributionPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedPageIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.subtitles), label: 'Transcription'),
          BottomNavigationBarItem(icon: Icon(Icons.sign_language), label: 'Sign Language'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Contribution'),
        ],
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.deepPurple,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        currentIndex: _selectedPageIndex,
        onTap: (selectedPageIndex) {
          setState(() {
            _selectedPageIndex = selectedPageIndex;
          });
        },
      ),
    );
  }
}
