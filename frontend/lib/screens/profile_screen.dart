import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/travel_data_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final bool embedded;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.embedded = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TravelDataService travelData = TravelDataService.instance;

  @override
  void initState() {
    super.initState();
    travelData.addListener(_refresh);
    travelData.initialize();
  }

  @override
  void dispose() {
    travelData.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _logout() async {
    await travelData.clearSession();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0B5F8E)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E2530),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final initials = widget.userName.isEmpty
        ? 'TP'
        : widget.userName.substring(0, 1).toUpperCase();
    final tripsCount = travelData.previousTrips.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFF0B5F8E),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.userName.isEmpty ? 'TravelPilot User' : widget.userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E2530),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.userEmail.isEmpty
                    ? 'traveler@travelpilot.ai'
                    : widget.userEmail,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildStatRow(
          'Active Trip',
          travelData.tripIsActive ? '1' : '0',
          Icons.travel_explore_rounded,
        ),
        _buildStatRow(
          'Completed Trips',
          '${travelData.pastTrips.length}',
          Icons.check_circle_outline_rounded,
        ),
        _buildStatRow(
          'Total Expenses',
          '₹${travelData.totalExpense.toStringAsFixed(0)}',
          Icons.account_balance_wallet_rounded,
        ),
        _buildStatRow(
          'Memories',
          '${travelData.memories.length}',
          Icons.photo_library_rounded,
        ),
        _buildStatRow(
          'Visited Places',
          '${travelData.visitedPlacesCount}',
          Icons.place_rounded,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _logout,
            child: const Text('Logout'),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'TravelPilot AI v1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.45),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(child: _buildBody()),
    );
  }
}
