import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'expense_screen.dart';
import 'map_screen.dart';
import 'memory_screen.dart';
import 'profile_screen.dart';
import 'travel_planner_screen.dart';

class AppShell extends StatefulWidget {
  final String userName;
  final String userEmail;

  const AppShell({
    Key? key,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();

  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    state?.setTab(index);
  }
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(
      userName: widget.userName,
      userEmail: widget.userEmail,
      embedded: true,
    ),
    const TravelPlannerScreen(embedded: true),
    const ExpenseScreen(embedded: true),
    const MemoryScreen(embedded: true),
    const MapScreen(embedded: true),
    /*
    ProfileScreen(
      userName: widget.userName,
      userEmail: widget.userEmail,
      embedded: true,
    ),
    */
  ];

  void setTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      extendBody: false,
      body: IndexedStack(
        index: currentIndex,
        children: _screens
            .map(
              (screen) => SafeArea(
                maintainBottomViewPadding: true,
                child: screen,
              ),
            )
            .toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        height: 72,
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_rounded),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Memories',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          /*
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
          */
        ],
      ),
    );
  }
}
