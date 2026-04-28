import 'dart:async';
import 'package:flutter/material.dart';

class ThoughtLogWidget extends StatefulWidget {
  /// Set this to true when the user presses your "Sync" button.
  /// When true, it will play the mock "Agent Reasoning" steps.
  final bool isSyncing;

  const ThoughtLogWidget({Key? key, required this.isSyncing}) : super(key: key);

  @override
  State<ThoughtLogWidget> createState() => _ThoughtLogWidgetState();
}

class _ThoughtLogWidgetState extends State<ThoughtLogWidget> {
  final List<String> _thoughts = [];
  final ScrollController _scrollController = ScrollController();
  
  Timer? _timer;
  int _stepIndex = 0;

  final List<String> _mockSteps = [
    'Initializing synchronization sequence...',
    'Connecting to Travel Intelligence API...',
    'Analyzing trip data integrity...',
    'Optimizing routes for rural areas...',
    'Compressing image hashes...',
    'Syncing with local storage...',
    'Sync completed successfully.'
  ];

  @override
  void didUpdateWidget(ThoughtLogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing && !oldWidget.isSyncing) {
      _startMockReasoning();
    } else if (!widget.isSyncing && oldWidget.isSyncing) {
      _thoughts.clear();
      _stepIndex = 0;
      _timer?.cancel();
    }
  }

  void _startMockReasoning() {
    _thoughts.clear();
    _stepIndex = 0;
    
    // Add first thought immediately
    _addNextThought();

    // Then schedule the rest periodically
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_stepIndex < _mockSteps.length) {
        _addNextThought();
      } else {
        timer.cancel();
      }
    });
  }

  void _addNextThought() {
    if (!mounted || _stepIndex >= _mockSteps.length) return;
    
    setState(() {
      _thoughts.add(_mockSteps[_stepIndex]);
      _stepIndex++;
    });
    
    // Auto-scroll to bottom as new thoughts appear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSyncing && _thoughts.isEmpty) {
      // Hide completely when not syncing
      return const SizedBox.shrink(); 
    }

    return Container(
      height: 120, // Small scrolling list at the bottom
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: const [
              Icon(Icons.smart_toy, color: Colors.blueAccent, size: 16),
              SizedBox(width: 8),
              Text(
                'Agent Reasoning...',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Spacer(),
              SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 8),
          
          // Scrolling List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _thoughts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    '> ${_thoughts[index]}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
