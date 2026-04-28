import 'dart:async';
import 'package:flutter/material.dart';

class AgentThoughtLog extends StatefulWidget {
  final bool isPlanning;

  const AgentThoughtLog({Key? key, required this.isPlanning}) : super(key: key);

  @override
  State<AgentThoughtLog> createState() => _AgentThoughtLogState();
}

class _AgentThoughtLogState extends State<AgentThoughtLog> {
  final List<String> _thoughts = [];
  final ScrollController _scrollController = ScrollController();
  
  Timer? _timer;
  int _stepIndex = 0;

  final List<String> _mockSteps = [
    'Connecting to Travel Intelligence API...',
    'Analyzing weather patterns for destination...',
    'Cross-referencing budget with local transport costs...',
    'Optimizing routes for rural areas...',
    'Agent Suggestion: High traffic detected, adjusting start time by 30 mins',
    'Syncing with local storage...',
    'Trip Plan successfully compiled.'
  ];

  @override
  void didUpdateWidget(AgentThoughtLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlanning && !oldWidget.isPlanning) {
      _startMockReasoning();
    } else if (!widget.isPlanning && oldWidget.isPlanning) {
      // Keep showing the final state or clear if preferred.
      // For demo, we leave it visible until new planning starts.
    }
  }

  void _startMockReasoning() {
    _thoughts.clear();
    _stepIndex = 0;
    
    _addNextThought();

    _timer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
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
    if (!widget.isPlanning && _thoughts.isEmpty) {
      return const SizedBox.shrink(); 
    }

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black, // Dark background
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.greenAccent, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              const Text(
                'AGENT THOUGHT LOG',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (widget.isPlanning && _stepIndex < _mockSteps.length)
                const SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.green),
          const SizedBox(height: 8),
          
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
                      color: Colors.greenAccent, // Green text
                      fontFamily: 'monospace',
                      fontSize: 11,
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
