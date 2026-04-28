import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trip_plan.dart';
import '../services/api_service.dart';
import '../services/smart_travel_agent.dart';
import '../services/travel_data_service.dart';
import '../services/sync_service.dart';
import '../services/tracking_service.dart';
import 'app_shell.dart';
import 'expense_screen.dart';
import 'map_screen.dart';
import 'memory_screen.dart';
import 'profile_screen.dart';
import 'travel_planner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'past_trip_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final bool embedded;

  DashboardScreen({
    super.key,
    required this.userName,
    this.userEmail = '',
    this.embedded = false,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService api = ApiService();
  final TravelDataService travelData = TravelDataService.instance;
  final TextEditingController destinationController = TextEditingController();
  bool isLoading = true;
  String? errorMessage;
  bool backendConnected = false;
  DateTime? draftStartDate;
  DateTime? draftEndDate;
  TravelTrip? _selectedPastTrip;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    travelData.addListener(_handleTravelDataChanged);
  }

  @override
  void dispose() {
    travelData.removeListener(_handleTravelDataChanged);
    destinationController.dispose();
    super.dispose();
  }

  void _handleTravelDataChanged() {
    if (!mounted) return;
    setState(() {
      errorMessage = travelData.errorMessage;
      if (_selectedPastTrip == null && travelData.pastTrips.isNotEmpty) {
        _selectedPastTrip = travelData.pastTrips.first;
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await travelData.initialize();
      await travelData.refreshAllData(); // Force sync past trips down from backend
      final response = await api.runAllAgents(
        location: travelData.cityName.isEmpty ? 'dashboard' : travelData.cityName,
        time: DateTime.now().toIso8601String(),
      );

      if (!mounted) return;
      setState(() {
        errorMessage = travelData.errorMessage;
        backendConnected = response['status'] == 'success';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        backendConnected = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _retryCurrentCity() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await travelData.initialize();
    await travelData.refreshSelectedCity();
    if (!mounted) return;
    setState(() {
      isLoading = false;
      errorMessage = travelData.errorMessage;
    });
  }

  Future<void> _openTripSearch() async {
    destinationController.text = travelData.cityName;
    final TextEditingController sourceController = TextEditingController();
    String tripSize = 'Family';
    String tripMove = 'Flight';
    draftStartDate = DateTime.now();
    draftEndDate = DateTime.now().add(const Duration(days: 2));

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickRange() async {
              final selected = await showDateRangePicker(
                context: context,
                locale: const Locale('en', 'IN'),
                initialDateRange: DateTimeRange(
                  start: draftStartDate ?? DateTime.now(),
                  end: draftEndDate ?? (draftStartDate ?? DateTime.now()).add(const Duration(days: 2)),
                ),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF008080), 
                        onPrimary: Colors.white,
                        onSurface: Color(0xFF102A43),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (selected == null) return;
              setDialogState(() {
                draftStartDate = selected.start;
                draftEndDate = selected.end;
              });
            }

            final startDate = draftStartDate ?? DateTime.now();
            final endDate = draftEndDate ?? startDate;
            final calculatedDays = endDate.difference(startDate).inDays + 1;

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Plan Trip',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF102A43)),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: sourceController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Source',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Source',
                          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF7B8A9D)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFF008080)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: destinationController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Destination',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Enter destination',
                          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7B8A9D)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFF008080)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF4FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Weekend Getaway', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334A5E))),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF4FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Business Trip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334A5E))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: tripSize,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF008080)),
                              decoration: InputDecoration(
                                labelText: 'Trip Size',
                                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFF008080)),
                                ),
                              ),
                              items: ['Family', 'Friends', 'Solo', 'Others'].map((String s) {
                                return DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (String? val) {
                                setDialogState(() => tripSize = val!);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: tripMove,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF008080)),
                              decoration: InputDecoration(
                                labelText: 'Trip Move',
                                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFF008080)),
                                ),
                              ),
                              items: ['Bus', 'Train', 'Car', 'Bike', 'Flight', 'Other'].map((String s) {
                                return DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (String? val) {
                                setDialogState(() => tripMove = val!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: pickRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF7CB6B6)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                                style: const TextStyle(color: Color(0xFF102A43), fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const Spacer(),
                              const Icon(Icons.calendar_today_outlined, color: Color(0xFF008080), size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          ' $calculatedDays day trip',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF355264),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            final source = sourceController.text.trim();
                            final destination = destinationController.text.trim();
                            
                            if (source.isEmpty || destination.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter source and destination')),
                              );
                              return;
                            }
                            
                            Navigator.of(context).pop();
                            
                            await travelData.createTrip(
                              source: source,
                              destination: destination,
                              startDate: startDate,
                              endDate: endDate,
                            );
                            
                            if (!mounted) return;
                            AppShell.switchToTab(this.context, 1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008080),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                          child: const Text('Generate Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPreviousTrip(TravelTrip trip) async {
    setState(() => isLoading = true);
    await travelData.openPreviousTrip(trip);
    if (!mounted) return;
    setState(() => isLoading = false);
    AppShell.switchToTab(context, 2);
  }

  String _formatDate(DateTime date) {
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][date.month - 1];
    return '$month ${date.day}';
  }

  Widget _buildPreviousTripCard(TravelTrip trip) {
    return GestureDetector(
      onTap: () => _openPreviousTrip(trip),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                color: Color(0xFF21536F),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.destination,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF008080),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(DateTime.parse(trip.startDate))} - ${_formatDate(DateTime.parse(trip.endDate))} • ${trip.tripDays} days',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF355264)),
          ],
        ),
      ),
    );
  }

  Widget _buildTripStatusCard(String title, TravelTrip trip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          const SizedBox(height: 10),
          _buildPreviousTripCard(trip),
        ],
      ),
    );
  }

  String get _greetingName {
    final value = widget.userName.trim();
    if (value.isEmpty) return 'Traveler';
    return value[0].toUpperCase() + value.substring(1);
  }

  String get _totalExpenses {
    return '\$${travelData.currentTripExpenses.fold<double>(0, (sum, expense) => sum + expense.amount).toStringAsFixed(2)}';
  }

  String get _aiInsights {
    final focusPlace = travelData.topPicks.isNotEmpty
        ? travelData.topPicks.first.name
        : travelData.cityName;
    return 'Live nearby data suggests $focusPlace is one of the best stops to anchor your day in ${travelData.cityName}.';
  }

  String get _decision {
    return 'Cluster nearby attractions, one restaurant stop, and one museum to keep travel time low and the day balanced.';
  }

  String get _contextText {
    final connection = backendConnected
        ? 'Connected to TravelPilot AI'
        : 'Offline mode';
    return '$connection\nLoaded from OpenStreetMap for ${travelData.cityLabel} and cached locally for offline browsing after fetch.';
  }

  List<String> get _reminders {
    if (travelData.topPicks.isNotEmpty) {
      return [
        'Closest pick: ${travelData.topPicks.first.distanceKm.toStringAsFixed(1)} km away',
        '${travelData.places.length} nearby places loaded',
      ];
    }
    return const [
      'Daily limit: \$200.00',
      '+\$15.00 today',
    ];
  }

  Widget _buildSectionHeader(String title, {String? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20242C),
          ),
        ),
        if (action != null)
          Text(
            action,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4D87AA),
            ),
          ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return GestureDetector(
      onTap: _openTripSearch,
      child: Container(
        height: 196,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2AA8D4), Color(0xFF123F75)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26123F75),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -10,
              top: 40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -28,
              bottom: -36,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8DE8E0),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                backendConnected ? 'CONNECTED' : 'OFFLINE',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0E5469),
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Agentic Workflow optimized based on 'ReAct: Synergizing Reasoning and Acting in Language Models'"),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.info_outline, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'AI Basis',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onLongPress: () {
                            TrackingAgent.instance.toggleSimulation();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(TrackingAgent.instance.isSimulating.value 
                                    ? 'Passive Tracking Simulation Started' 
                                    : 'Passive Tracking Simulation Stopped'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(
                            travelData.cityName.isEmpty
                                ? 'TravelPilot AI'
                                : '${travelData.cityName} Explorer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          travelData.cityLabel.isEmpty
                              ? 'Plan smarter. Travel better.'
                              : travelData.cityLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            /*
            const Positioned(
              right: 18,
              bottom: 18,
              child: CircleAvatar(
                radius: 19,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            */
          ],
        ),
      ),
    );
  }

  Widget _buildSpendCard() {
    final reminders = _reminders;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ExpenseScreen()),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPENT SO FAR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.35),
                  letterSpacing: 0.9,
                ),
              ),
              const Text(
                '76% of budget',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2FA7A2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _totalExpenses,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
              color: Color(0xFF173D56),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              _Bar(height: 14, color: Color(0xFFD6E1EA)),
              SizedBox(width: 6),
              _Bar(height: 22, color: Color(0xFFD6E1EA)),
              SizedBox(width: 6),
              _Bar(height: 12, color: Color(0xFFD6E1EA)),
              SizedBox(width: 6),
              _Bar(height: 28, color: Color(0xFF1C638C)),
              SizedBox(width: 6),
              _Bar(height: 16, color: Color(0xFFD6E1EA)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.circle,
                size: 8,
                color: Color(0xFF8E97A3),
              ),
              const SizedBox(width: 6),
              Text(
                reminders.isNotEmpty ? reminders.first : 'Daily limit: \$200.00',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                reminders.length > 1 ? reminders[1] : '+\$15.00 today',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFE15555),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPickCard({
    required String title,
    required String subtitle,
    required List<Color> colors,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 118,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withOpacity(0.35),
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20242C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Near your stay',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.black.withOpacity(0.45),
                      fontWeight: FontWeight.w600,
                    ),
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

  Widget _buildMemoryCard(String label, List<Color> colors) {
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: colors),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text('Dashboard', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              // 1. Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/logo/travelpilot_logo.png', height: 40, errorBuilder: (ctx, _, __) => const Icon(Icons.flight_takeoff, color: Color(0xFF008080), size: 30)),
                      const SizedBox(width: 8),
                      const Text(
                        'TripPilot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: SyncService.instance.isSynced,
                        builder: (context, synced, _) {
                          return Tooltip(
                            message: "Agent Cloud Sync Active",
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: synced ? const Color(0xFF34A853) : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 48),
                    padding: EdgeInsets.zero,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF008080),
                      child: Text(
                        (_greetingName == 'null' || _greetingName == 'undefined' || _greetingName.isEmpty) ? 'U' : _greetingName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          _greetingName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF102A43)),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (String value) async {
                      if (value == 'logout') {
                        final bool? shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Text('Do you really want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            );
                          },
                        );
                        if (shouldLogout == true) {
                          await TravelDataService.instance.clearSession();
                          if (!mounted) return;
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 2. Greeting
              Row(
                children: [
                  Text(
                    'Hello, $_greetingName ',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF102A43),
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 24)),
                ],
              ),
              const Text(
                'Your travel assistant',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              
              // 3. Live Map Card
              _buildStitchMapCard(),
              const SizedBox(height: 16),
              if (travelData.tripIsActive)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await travelData.endTrip();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trip ended successfully and stored in past trips.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    child: const Text('End Trip'),
                  ),
                ),
              const SizedBox(height: 24),



              // 7. Past Trips
              if (travelData.pastTrips.isNotEmpty) _buildStitchTripReport(_selectedPastTrip ?? travelData.pastTrips.first),
              _buildSectionHeader('Past Trips'),
              const SizedBox(height: 16),
              _buildStitchUpcomingTrips(),
              const SizedBox(height: 24),

              // Memories section removed

            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _openTripSearch,
            backgroundColor: const Color(0xFF008080),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildStitchMapCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      },
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF8BAE90),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEBEAD7),
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage('assets/images/header.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 16,
                bottom: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008080),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'LIVE NOW',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are traveling in ${travelData.cityName.isEmpty ? 'a new destination' : travelData.cityName}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.near_me, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          travelData.places.isNotEmpty ? travelData.places.first.name : 'Discovering local gems...',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
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

  Widget _buildStitchJourney() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _journeyStitchItem('Cafe', Icons.local_cafe, '09:30 AM', const Color(0xFFD4E5F9), const Color(0xFF4C8DDF)),
          _journeyStitchItem('Mall', Icons.shopping_bag, '12:45 PM', const Color(0xFFD3EBE8), const Color(0xFF008080)),
          _journeyStitchItem('Park', Icons.park, '04:20 PM', const Color(0xFFFDECD4), const Color(0xFFDF7B4C)),
        ],
      ),
    );
  }

  Widget _journeyStitchItem(String title, IconData icon, String time, Color bgColor, Color iconColor) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF102A43))),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 9, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildStitchExpenseWarning() {
    final spent = travelData.spentPercentage;
    final warningTitle = spent > 0.8 
        ? 'High Spending Alert' 
        : 'You are spending more on food this week';
    final warningSub = spent > 0.8
        ? 'You have used ${(spent * 100).toStringAsFixed(0)}% of your budget. Consider reducing non-essential costs.'
        : 'Try budget-friendly options nearby. We\'ve found 3 local spots with high ratings.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF008080),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF008080).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(spent > 0.8 ? Icons.warning_amber_rounded : Icons.pie_chart, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warningTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  warningSub,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchAutoExpenses() {
    final realExpenses = travelData.expenses;
    final hasReal = realExpenses.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hasReal ? 'Recent\nExpenses' : 'Auto Detected\nExpenses',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF102A43), height: 1.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hasReal ? const Color(0xFFE8F4FB) : const Color(0xFFD4E5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasReal ? 'LIVE TRIP FEED' : 'DETECTED FROM GMAIL', 
                  style: TextStyle(
                    color: hasReal ? const Color(0xFF21536F) : const Color(0xFF4C8DDF), 
                    fontSize: 8, 
                    fontWeight: FontWeight.w800
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (hasReal)
            ...realExpenses.reversed.take(3).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _expenseStitchItem(
                e.category, 
                e.note.isEmpty ? 'Manual Entry' : e.note, 
                '₹${e.amount.toStringAsFixed(0)}', 
                _getCategoryIcon(e.category), 
                const Color(0xFFF1F3F5)
              ),
            ))
          else ...[
            _expenseStitchItem('Swiggy', 'Today, 2:15 PM', '₹500', Icons.fastfood, const Color(0xFFF1F3F5)),
            const SizedBox(height: 16),
            _expenseStitchItem('Uber ride', 'Yesterday', '₹300', Icons.directions_car, const Color(0xFFF1F3F5)),
          ],
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExpenseScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: const Text('View All Expenses', style: TextStyle(color: Color(0xFF008080), fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('eat') || cat.contains('dine')) return Icons.fastfood;
    if (cat.contains('travel') || cat.contains('transport') || cat.contains('uber') || cat.contains('cab')) return Icons.directions_car;
    if (cat.contains('hotel') || cat.contains('stay')) return Icons.hotel;
    if (cat.contains('shop')) return Icons.shopping_bag;
    return Icons.receipt_long;
  }

  Widget _expenseStitchItem(String title, String subtitle, String amt, IconData icon, Color bgColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF355264), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF102A43))),
              Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: Colors.blueGrey)),
            ],
          ),
        ),
        Text(amt, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF102A43))),
      ],
    );
  }

  Widget _buildStitchTripReport(TravelTrip trip) {
    final tripExpenses = travelData.expenses.where((e) => e.tripId == trip.id).fold(0.0, (s, e) => s + e.amount);
    final tripMemoriesCount = travelData.memories.where((m) => m.tripId == trip.id).length;
    
    final report = SmartTravelAgent.instance.summary.generateTripReport(
      trip,
      tripExpenses,
      travelData.visitedPlacesCount,
      tripMemoriesCount,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF102A43).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Color(0xFF4DB6AC)),
              const SizedBox(width: 8),
              Text(
                report['title'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _reportItem(
            'Total Expenses', 
            'Rs ${report['expenses'].toStringAsFixed(0)}'
          ),
          _reportItem('Places Visited', '${report['visited_places']}'),
          _reportItem('Memories Logged', '${report['memories_logged']}'),
        ],
      ),
    );
  }

  Widget _reportItem(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _editPastTrip(TravelTrip trip) async {
    final controller = TextEditingController(text: trip.destination);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Trip Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Destination'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()), 
              child: const Text('Save')
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != trip.destination) {
      final updatedTrip = TravelTrip(
        id: trip.id,
        destination: newName,
        cityLabel: newName,
        startDate: trip.startDate,
        endDate: trip.endDate,
        tripDays: trip.tripDays,
        status: trip.status,
        shareCode: trip.shareCode,
        friends: trip.friends,
      );
      await travelData.updatePastTrip(updatedTrip);
    }
  }

  Widget _buildStitchUpcomingTrips() {
    if (travelData.pastTrips.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          'No past trips saved yet.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: travelData.pastTrips.map((trip) {
          String dates = '';
          try {
            final start = DateTime.parse(trip.startDate);
            final end = DateTime.parse(trip.endDate);
            final months = const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            dates = '${months[start.month-1]} ${start.day} - ${months[end.month-1]} ${end.day}';
          } catch (_) {}
          return _tripStitchCard(
            title: trip.destination.isEmpty ? 'Previous Trip' : trip.destination, 
            dates: dates, 
            tagColor: const Color(0xFF2B78D9),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PastTripDetailScreen(trip: trip),
                ),
              );
            },
            onEdit: () {
              _editPastTrip(trip);
            },
            onDelete: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Delete Trip'),
                    content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                await travelData.deleteTrip(trip.id);
                if (_selectedPastTrip?.id == trip.id) {
                  setState(() {
                    _selectedPastTrip = null;
                  });
                }
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _tripStitchCard({
    required String title, 
    required String dates, 
    required Color tagColor, 
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 120,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: tagColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage('https://picsum.photos/seed/${title.replaceAll(' ', '_')}_${title.length}/400/300'),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(Colors.black26, BlendMode.darken),
          ),
        ),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(dates, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 10)),
                ],
              ),
            ),
            if (onEdit != null || onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    if (onEdit != null)
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF102A43)),
                        ),
                      ),
                    if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFE53935)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchMemories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _memoryStitchCard(const Color(0xFF8BAE90)),
          _memoryStitchCard(const Color(0xFFB1C9CD)),
          _memoryStitchCard(const Color(0xFFE2C992)),
          _memoryStitchCard(const Color(0xFF637C90)),
        ],
      ),
    );
  }

  Widget _memoryStitchCard(Color color) {
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage('https://picsum.photos/seed/mem_${color.value}/200/200'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 16, height: height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)));
  }
}

class _AgentChip extends StatelessWidget {
  final String label;
  const _AgentChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFE8F4FB), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF21536F))),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
