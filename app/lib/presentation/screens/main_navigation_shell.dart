import 'package:flutter/material.dart';
import 'activity/activity_screen.dart';
import 'home/home_screen.dart';
import 'lookup/lookup_screen.dart';
import 'rules/rules_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ActivityScreen(),
    LookupScreen(),
    RulesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            activeIcon: Icon(Icons.manage_history_rounded),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            activeIcon: Icon(Icons.saved_search_rounded),
            label: 'Lookup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rule_rounded),
            activeIcon: Icon(Icons.gavel_rounded),
            label: 'Rules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
