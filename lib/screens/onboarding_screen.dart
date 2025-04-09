import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'room_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to GARRISON',
      'desc': 'A board game where every choice shape yuh future inna di Garrison.',
    },
    {
      'title': 'How To Play',
      'desc': 'Roll di dice, draw choice cards, survive, and rise. From Good Youth to Don or JP.',
    },
    {
      'title': 'Di Roles',
      'desc': 'Good Youth, Don, MP, JP, Babylon. Each role have mission and ability fi use.',
    },
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => const RoomScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset('assets/logo.png', height: 80),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          page['desc']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? theme.primaryColor : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ElevatedButton(
                onPressed: _currentPage == _pages.length - 1
                    ? _finishOnboarding
                    : () => _controller.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
                child: Text(_currentPage == _pages.length - 1 ? "Start Game" : "Next"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
