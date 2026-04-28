import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class RunAllScreen extends StatefulWidget {
  @override
  _RunAllScreenState createState() => _RunAllScreenState();
}

class _RunAllScreenState extends State<RunAllScreen> {
  final ApiService api = ApiService();
  bool loading = false;
  Map<String, dynamic> data = {};
  String currentLocation = 'unknown';
  String currentTime = '';

  @override
  void initState() {
    super.initState();
    fetchRunAll();
  }

  Future<void> fetchRunAll() async {
    setState(() => loading = true);
    try {
      final locationPoint = await LocationService.getCurrentLocation();
      final locationName = locationPoint != null
          ? 'Lat ${locationPoint.latitude.toStringAsFixed(5)}, Lon ${locationPoint.longitude.toStringAsFixed(5)}'
          : 'unknown';

      final timestamp = DateTime.now().toIso8601String();
      setState(() {
        currentLocation = locationName;
        currentTime = timestamp;
      });

      final response = await api.runAllAgents(
        location: locationName,
        time: timestamp,
        latitude: locationPoint?.latitude,
        longitude: locationPoint?.longitude,
      );

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response['error']}')));
      } else {
        setState(() => data = response);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _buildSection(String title, Widget child) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseAnalysis() {
    final analysis = data['expense_analysis'];
    if (analysis == null || analysis is! Map) {
      return Text('No data available');
    }

    final total = analysis['total'] ?? 0;
    final categories = analysis['categories'] as Map<String, dynamic>? ?? {};
    final suggestion = analysis['suggestion'] ?? 'No suggestions yet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total: \$$total'),
        SizedBox(height: 6),
        Text(
          'Category breakdown:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        ...categories.entries.map((entry) {
          return Text('${entry.key}: ${entry.value}');
        }).toList(),
        SizedBox(height: 8),
        Text('Suggestion:'),
        Text(suggestion),
      ],
    );
  }

  Widget _buildReminders() {
    final reminders = data['reminders'];
    if (reminders == null) return Text('No reminders');
    if (reminders is List) {
      if (reminders.isEmpty) return Text('No reminders');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: reminders.map<Widget>((item) {
          return Text('- ${item.toString()}');
        }).toList(),
      );
    }
    return Text(reminders.toString());
  }

  Widget _buildTravelPlan() {
    final plan = data['travel_plan'];
    if (plan == null || plan is! Map) {
      return Text('No travel plan');
    }

    final activities = plan['activities'];
    if (activities is List && activities.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: activities.map<Widget>((activity) {
          return Text('- ${activity.toString()}');
        }).toList(),
      );
    }

    return Text(plan['advice']?.toString() ?? 'No details');
  }

  Widget _buildContext() {
    final contextData = data['context'];
    if (contextData == null) return Text('No context available');
    if (contextData is Map && contextData.containsKey('message')) {
      return Text(contextData['message'].toString());
    }
    return Text(contextData.toString());
  }

  Widget _buildMemories() {
    final memories = data['memories'];
    if (memories == null) return Text('No memories');

    if (memories is List && memories.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: memories.map<Widget>((item) {
          if (item is Map) {
            final note = item['note'] ?? item['text'] ?? item.toString();
            final timestamp = item['timestamp'] ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text('$timestamp - $note'),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(item.toString()),
          );
        }).toList(),
      );
    }

    return Text(memories.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TravelPilot AI'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ApiService.demoMode)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Demo Mode Active',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: fetchRunAll,
              child: Text('Reload AI Overview'),
            ),
            SizedBox(height: 8),
            Text('Current location: $currentLocation'),
            Text('Current time: $currentTime'),
            SizedBox(height: 12),
            if (loading) ...[
              SizedBox(height: 10),
              Center(child: CircularProgressIndicator()),
            ] else ...[
              data.isEmpty
                  ? Expanded(child: Center(child: Text('No data available')))
                  : Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              'Expense Analysis',
                              _buildExpenseAnalysis(),
                            ),
                            _buildSection('Reminders', _buildReminders()),
                            _buildSection('Travel Plan', _buildTravelPlan()),
                            _buildSection('Context', _buildContext()),
                            _buildSection('Memories', _buildMemories()),
                          ],
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
