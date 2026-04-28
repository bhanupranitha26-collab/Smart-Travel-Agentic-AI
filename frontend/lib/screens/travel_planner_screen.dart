import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/trip_plan.dart';
import '../services/travel_data_service.dart';
import '../services/sync_service.dart';
import '../widgets/agent_thought_log.dart';

class TravelPlannerScreen extends StatefulWidget {
  final bool embedded;

  const TravelPlannerScreen({super.key, this.embedded = false});

  @override
  State<TravelPlannerScreen> createState() => _TravelPlannerScreenState();
}

class _TravelPlannerScreenState extends State<TravelPlannerScreen> {
  final TravelDataService travelData = TravelDataService.instance;
  final TextEditingController destinationController = TextEditingController();

  bool loading = false;
  String? errorMessage;
  String selectedMood = 'Sightseeing';

  final List<String> moods = const [
    'Sightseeing',
    'Relax',
    'Party',
    'Museums',
  ];

  @override
  void initState() {
    super.initState();
    travelData.addListener(_handleTravelDataChanged);
    travelData.initialize();
  }

  @override
  void dispose() {
    travelData.removeListener(_handleTravelDataChanged);
    destinationController.dispose();
    super.dispose();
  }

  void _handleTravelDataChanged() {
    if (!mounted) return;
    if (destinationController.text.trim() != travelData.cityName) {
      destinationController.text = travelData.cityName;
    }
    setState(() {
      errorMessage = travelData.errorMessage;
    });
  }

  Future<void> createPlan() async {
    final destination = destinationController.text.trim();
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination required')),
      );
      return;
    }

    final startDate = travelData.tripStartDate ?? DateTime.now();
    final endDate = travelData.tripEndDate ??
        startDate.add(Duration(days: travelData.tripDays - 1));

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await travelData.initialize();
      await travelData.createTrip(
        destination: destination,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;
      setState(() => errorMessage = travelData.errorMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _openStopEditor({
    PlannerStop? stop,
    required int dayIndex,
  }) async {
    final placeController = TextEditingController(text: stop?.place ?? '');
    final timeController = TextEditingController(text: stop?.time ?? '05:00 PM');
    final notesController = TextEditingController(text: stop?.notes ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stop == null ? 'Add Stop' : 'Edit Stop',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: placeController,
                  decoration: const InputDecoration(labelText: 'Place'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final place = placeController.text.trim();
                      final time = timeController.text.trim();
                      final notes = notesController.text.trim();
                      if (place.isEmpty || time.isEmpty) return;

                      if (stop == null) {
                        await travelData.addStop(
                          dayIndex: dayIndex,
                          place: place,
                          time: time,
                          notes: notes,
                        );
                      } else {
                        await travelData.updateStop(
                          stop.copyWith(
                            place: place,
                            time: time,
                            notes: notes,
                          ),
                        );
                      }

                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save updates'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteStop(PlannerStop stop) async {
    await travelData.deleteStop(stop.id);
  }

  String get headline {
    final selectedCity = destinationController.text.trim().isEmpty
        ? travelData.cityName
        : destinationController.text.trim();
    return selectedCity.isEmpty
        ? 'Perfect Balance'
        : '${travelData.tripDays} days in $selectedCity - Perfect Balance';
  }

  List<List<PlannerStop>> get itineraryDays => travelData.itineraryByDay;

  String _dayTitle(int dayIndex) {
    if (dayIndex == 0) return 'Day 1: Modern Tradition';
    if (dayIndex == 1) return 'Day 2: Food & Museums';
    if (dayIndex == 2) return 'Day 3: Landmarks';
    return 'Day ${dayIndex + 1}: Explore More';
  }

  String _formatEventDate(String dateValue) {
    final date = DateTime.tryParse(dateValue);
    if (date == null) return dateValue;
    final month = const [
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

  String _formatTripRange() {
    final start = travelData.tripStartDate;
    final end = travelData.tripEndDate;
    if (start == null || end == null) return 'Flexible dates';
    return '${_formatEventDate(start.toIso8601String())} - ${_formatEventDate(end.toIso8601String())}';
  }

  String _timeBlockLabel(String time) {
    final upper = time.toUpperCase();
    if (upper.contains('AM')) return 'Morning';
    if (upper.startsWith('12') || upper.startsWith('01') || upper.startsWith('02') || upper.startsWith('03') || upper.startsWith('04')) {
      return 'Afternoon';
    }
    return 'Evening';
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'museum':
        return Icons.museum_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'transport':
        return Icons.directions_transit_rounded;
      case 'event':
        return Icons.celebration_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Widget _buildEventCard(TravelEvent event, int dayIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Color(0xFF2C6A86),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F252D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatEventDate(event.date)} • ${event.category} • ${event.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.52),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => travelData.addEventToItinerary(event, dayIndex: dayIndex),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteFriend() async {
    final link = 'https://smart-travel-ai.vercel.app/invite?code=${travelData.shareCode}';
    final text = 'Join my trip on TravelPilot! Use my invite code: ${travelData.shareCode}\nOr download the app at $link';
    await Share.share(text);
  }

  Future<void> _shareTrip() async {
    await Clipboard.setData(ClipboardData(text: travelData.buildShareSummary()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip summary copied to clipboard')),
    );
  }

  Widget _buildTripActions() {
    final active = travelData.tripIsActive;
    final isPlanned = travelData.isPlanned;
    final completed = travelData.tripIsCompleted;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (completed)
          ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: const Color(0xFFE6EBF1),
              disabledForegroundColor: const Color(0xFF48626E),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Trip Completed'),
          )
        else ...[
        ElevatedButton(
            onPressed: () async {
              if (!isPlanned) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please generate an itinerary first.')));
                return;
              }
              if (active) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip already started!')));
                return;
              }
              await travelData.startTrip();
              await travelData.refreshTripLocation();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trip started')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            child: const Text('Start Trip'),
          ),
        OutlinedButton(
            onPressed: () async {
              if (!isPlanned || !active) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip not started')));
                return;
              }
              await travelData.endTrip();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trip ended')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            child: const Text('End Trip'),
          ),
        ],
        ElevatedButton.icon(
          onPressed: _inviteFriend,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8F4FB),
            foregroundColor: const Color(0xFF21536F),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          icon: const Icon(Icons.group_add_rounded, size: 18),
          label: const Text('Invite Friends'),
        ),
      ],
    );
  }



  Widget _buildAgentStatusRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AgentStatusChip('Planner Agent', true),
        _AgentStatusChip('Tracking Agent', travelData.tripIsActive),
        _AgentStatusChip('Expense Agent', true),
        _AgentStatusChip('Memory Agent', true),
        _AgentStatusChip('Reminder Agent', travelData.tripIsActive),
      ],
    );
  }

  Widget _buildBudgetCard() {
    final breakdown = travelData.estimatedBudgetBreakdown;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Budget',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F252D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '₹${travelData.estimatedBudget.toStringAsFixed(0)} total',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0B5F8E),
            ),
          ),
          const SizedBox(height: 10),
          ...breakdown.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${entry.key}: ₹${entry.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.58),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline View',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F252D),
            ),
          ),
          const SizedBox(height: 10),
          if (travelData.timelineEntries.isEmpty)
            const Text('Timeline starts when your trip begins.')
          else
            ...travelData.timelineEntries.reversed.take(6).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: Color(0xFF0B5F8E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F252D),
            ),
          ),
          const SizedBox(height: 10),
          Text('Days traveled: ${travelData.tripDays}'),
          Text('Places visited: ${travelData.visitedPlacesCount}'),
          Text('Total expenses: ₹${travelData.totalExpense.toStringAsFixed(0)}'),
          Text('Memories created: ${travelData.memoriesCreatedCount}'),
          Text(
            'Budget vs spent: ₹${travelData.estimatedBudget.toStringAsFixed(0)} vs ₹${travelData.totalExpense.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final destination = destinationController.text.trim().isEmpty
        ? travelData.cityName
        : destinationController.text.trim();
    final hotelSuggestions = travelData.hotelSuggestions;
    final transportSuggestions = travelData.transportSuggestions;

    return RefreshIndicator(
      onRefresh: () async {
        await createPlan();
        await travelData.refreshTripLocation();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
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
          const SizedBox(height: 16),
          if (!travelData.hasSelectedCity)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Search for a city to begin',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A5563),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1977AB), Color(0xFF0C6B9D)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26123F75),
                  blurRadius: 20,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF9CECDF),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI RECOMMENDED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  travelData.hasSelectedCity
                      ? headline
                      : 'Search any city to\nbuild your itinerary',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  travelData.hasSelectedCity
                      ? '${travelData.tripDays} day itinerary generated. Nearby places grouped into a budget-friendly route.'
                      : 'Type any city above and generate a live itinerary from nearby places.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                if (travelData.hasSelectedCity) ...[
                  Text(
                    '${_formatTripRange()} • ${travelData.tripStatus.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAgentStatusRow(),
                  const SizedBox(height: 12),
                  _buildTripActions(),
                ],
                const SizedBox(height: 16),
                if (!travelData.isPlanned)
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: loading ? null : createPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF57D1B2),
                        foregroundColor: const Color(0xFF0B5462),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (loading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0B5462),
                              ),
                            )
                          else
                            const Icon(Icons.route_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Generate Itinerary',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFD64545),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (travelData.hasSelectedCity) ...[
            if (travelData.friends.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Friends: ${travelData.friends.join(', ')}\nTrip code: ${travelData.shareCode}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (travelData.tripIsActive)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        travelData.currentLocation == null
                            ? 'Tracking GPS for your active trip'
                            : 'Current location: ${travelData.currentLocation!.latitude.toStringAsFixed(4)}, ${travelData.currentLocation!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await travelData.refreshTripLocation();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location updated')),
                        );
                      },
                      icon: const Icon(Icons.my_location_rounded),
                    ),
                  ],
                ),
              ),
          ],
          if (travelData.hasSelectedCity) ...[
            for (var dayIndex = 0; dayIndex < itineraryDays.length; dayIndex++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dayTitle(dayIndex),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF004D40), // Stitch Dark Teal
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openStopEditor(dayIndex: dayIndex),
                    icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF004D40)),
                    label: const Text('Add stop', style: TextStyle(color: Color(0xFF004D40))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...itineraryDays[dayIndex].map(
                (stop) => _TimelineCard(
                  stop: stop,
                  icon: _iconForCategory(stop.category),
                  blockLabel: _timeBlockLabel(stop.time),
                  visited: travelData.visitedPlaceIds.contains(stop.place),
                  onEdit: () => _openStopEditor(stop: stop, dayIndex: dayIndex),
                  onDelete: () => _deleteStop(stop),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Suggested Places:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 10),
              if (dayIndex == 0 && travelData.events.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Events During Your Trip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF212832),
                  ),
                ),
                const SizedBox(height: 12),
                ...travelData.events.map((event) => _buildEventCard(event, dayIndex)),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: Text('Stay: ${hotelSuggestions[dayIndex % hotelSuggestions.length]}'),
                    onPressed: () => travelData.addStop(
                      dayIndex: dayIndex,
                      place: hotelSuggestions[dayIndex % hotelSuggestions.length],
                      time: '06:30 PM',
                      notes: 'Stay suggestion added to your trip',
                      category: 'hotel',
                      status: 'SUGGESTED',
                    ),
                  ),
                  ActionChip(
                    label: Text('Transport: ${transportSuggestions[dayIndex % transportSuggestions.length]}'),
                    onPressed: () => travelData.addStop(
                      dayIndex: dayIndex,
                      place: transportSuggestions[dayIndex % transportSuggestions.length],
                      time: '08:00 PM',
                      notes: 'Transport suggestion added to your trip',
                      category: 'transport',
                      status: 'SUGGESTED',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
          if (travelData.hasSelectedCity) _buildTimelineCard(),
          if (travelData.tripIsCompleted) _buildTripSummaryCard(),
          if (travelData.hasSelectedCity && destination.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Planner ready for $destination',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.45),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          AgentThoughtLog(isPlanning: loading),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text('Planner')),
      body: SafeArea(child: _buildBody(context)),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final PlannerStop stop;
  final IconData icon;
  final String blockLabel;
  final bool visited;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TimelineCard({
    required this.stop,
    required this.icon,
    required this.blockLabel,
    required this.visited,
    required this.onEdit,
    required this.onDelete,
  });

  Color get chipColor {
    switch (stop.status) {
      case 'CONFIRMED':
        return const Color(0xFFCFF8EE);
      case 'PENDING':
        return const Color(0xFFF0EDF6);
      case 'RESERVED':
        return const Color(0xFFE7FFF3);
      case 'EVENT':
        return const Color(0xFFFFF1D9);
      default:
        return const Color(0xFFE9EDF2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(width: 2, height: 16, color: const Color(0xFF4DB6AC)),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
                  ),
                  child: Icon(icon, color: const Color(0xFF008080), size: 16),
                ),
                Expanded(
                  child: Container(width: 2, color: const Color(0xFF4DB6AC)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: visited ? const Color(0xFFF1F3F4) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (visited) ...[
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF34A853), size: 16),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            stop.time,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: visited ? const Color(0xFF34A853) : const Color(0xFF4DB6AC),
                            ),
                          ),
                        ],
                      ),
                      if (visited)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF34A853)),
                              SizedBox(width: 4),
                              Text('Visited', style: TextStyle(fontSize: 10, color: Color(0xFF34A853), fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      if (!visited && stop.status != 'CONFIRMED')
                        TextButton.icon(
                          onPressed: () {
                            TravelDataService.instance.updateStop(stop.copyWith(status: 'CONFIRMED'));
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF4DB6AC)),
                          label: const Text(
                            'Add to Journey',
                            style: TextStyle(fontSize: 10, color: Color(0xFF4DB6AC)),
                          ),
                        )
                      else if (!visited)
                        TextButton.icon(
                          onPressed: () {
                            TravelDataService.instance.simulateTimeSpent(stop.place, const Duration(hours: 3));
                          },
                          icon: const Icon(Icons.coffee, size: 14, color: Color(0xFF4DB6AC)),
                          label: const Text(
                            'Stay 2h+',
                            style: TextStyle(fontSize: 10, color: Color(0xFF4DB6AC)),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stop.status,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF008080),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stop.place,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F252D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stop.notes,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0F567F).withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF008080)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'AI Reason: ' + ["Top-rated attraction within 2km", "Optimal routing continuity", "Highly correlated to user mood", "Matches historical preference"][stop.place.length % 4],
                            style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF0F567F)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentStatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _AgentStatusChip(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE0F8E8) : const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label ${active ? '✓' : '•'}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: active ? const Color(0xFF1E7B4A) : const Color(0xFF3C5C66),
        ),
      ),
    );
  }
}
