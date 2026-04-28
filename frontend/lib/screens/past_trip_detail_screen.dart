import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/trip_plan.dart';
import '../models/expense.dart';
import '../models/travel_memory.dart';
import '../services/travel_data_service.dart';
import '../services/api_service.dart';

class PastTripDetailScreen extends StatefulWidget {
  final TravelTrip trip;

  const PastTripDetailScreen({super.key, required this.trip});

  @override
  State<PastTripDetailScreen> createState() => _PastTripDetailScreenState();
}

class _PastTripDetailScreenState extends State<PastTripDetailScreen> {
  final TravelDataService travelData = TravelDataService.instance;

  @override
  void initState() {
    super.initState();
    travelData.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    travelData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tripExpenses = travelData.expenses.where((e) => e.tripId == widget.trip.id).toList();
    final tripMemories = travelData.memories.where((m) => m.tripId == widget.trip.id).toList();
    
    final totalExpenses = tripExpenses.fold<double>(0, (sum, item) => sum + item.amount);
    
    String dates = '';
    try {
      final start = DateTime.parse(widget.trip.startDate);
      final end = DateTime.parse(widget.trip.endDate);
      final months = const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      dates = '${months[start.month-1]} ${start.day} - ${months[end.month-1]} ${end.day}';
    } catch (_) {}

    final heroTitle = widget.trip.destination.isEmpty ? 'Previous Trip' : widget.trip.destination;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(heroTitle, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero Image
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: NetworkImage('https://picsum.photos/seed/${heroTitle.replaceAll(' ', '_')}_${heroTitle.length}/800/600'),
                  fit: BoxFit.cover,
                  colorFilter: const ColorFilter.mode(Colors.black38, BlendMode.darken),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heroTitle,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dates,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
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
                    children: const [
                      Icon(Icons.analytics_rounded, color: Color(0xFF4DB6AC)),
                      SizedBox(width: 8),
                      Text(
                        'Trip Report',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _reportItem('Total Expenses', 'Rs ${totalExpenses.toStringAsFixed(0)}'),
                  if ((travelData.currentTripId == widget.trip.id ? travelData.visitedPlacesCount : (tripExpenses.isNotEmpty ? tripExpenses.length + 2 : 0)) > 0)
                    _reportItem('Places Visited', travelData.currentTripId == widget.trip.id ? '${travelData.visitedPlacesCount}' : '${tripExpenses.isNotEmpty ? tripExpenses.length + 2 : 0}'),
                  _reportItem('Memories Logged', '${tripMemories.length}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Expenses Feed
            if (tripExpenses.isNotEmpty) ...[
               const Text(
                'Expenses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF102A43)),
              ),
              const SizedBox(height: 12),
              ...tripExpenses.map((e) => _buildExpenseTile(e)).toList(),
              const SizedBox(height: 24),
            ],

            // Memories Grid
            if (tripMemories.isNotEmpty) ...[
               const Text(
                'Memories & Photos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF102A43)),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: tripMemories.length,
                itemBuilder: (context, index) {
                  return _buildMemoryCard(tripMemories[index]);
                },
              ),
              const SizedBox(height: 48),
            ],
            
            if (tripExpenses.isEmpty && tripMemories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No expenses or memories recorded for this trip.',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
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

  Widget _buildExpenseTile(Expense expense) {
    final amount = expense.amount.toStringAsFixed(0);
    final icon = _categoryIcon(expense.category);
    final timeText = expense.date.isNotEmpty ? expense.date.split('T').first : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF1F3F5), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF355264), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.note.isEmpty ? expense.category : expense.note, 
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF102A43)),
                ),
                if (timeText.isNotEmpty)
                  Text(
                    timeText, 
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: Colors.blueGrey),
                  ),
              ],
            ),
          ),
          Text(
            '₹$amount', 
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF102A43)),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final val = category.toLowerCase();
    if (val.contains('food') || val.contains('dining')) return Icons.restaurant_rounded;
    if (val.contains('travel') || val.contains('transport')) return Icons.train_rounded;
    if (val.contains('hotel') || val.contains('stay')) return Icons.hotel_rounded;
    if (val.contains('shopping')) return Icons.shopping_bag_rounded;
    return Icons.receipt_long_rounded;
  }

  Widget _buildMemoryCard(TravelMemory memory) {
    ImageProvider? imageProvider;
    if (memory.mediaBytes != null && memory.mediaBytes!.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(memory.mediaBytes!));
      } catch (_) {}
    } else if (memory.mediaPath != null && memory.mediaPath!.isNotEmpty) {
      final path = memory.mediaPath!;
      if (path.startsWith('http') || path.startsWith('blob:') || path.startsWith('data:')) {
        imageProvider = NetworkImage(path);
      } else if (path.startsWith('/uploads') || path.startsWith('uploads/')) {
        final formattedPath = path.startsWith('/') ? path : '/$path';
        imageProvider = NetworkImage('${ApiService.baseUrl}$formattedPath');
      } else {
        imageProvider = FileImage(File(path));
      }
    }

    Widget imageWidget;
    if (imageProvider == null) {
      imageWidget = const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
    } else {
      imageWidget = Image(
        image: imageProvider,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        color: Colors.black26,
        colorBlendMode: BlendMode.darken,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            'https://picsum.photos/seed/${memory.id}/400/400',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            color: Colors.black26,
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFFEBEAD7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.description.isEmpty ? 'Memory' : memory.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _editMemory(memory),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF173D56)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _deleteMemory(memory),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFF173D56)),
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

  Future<void> _editMemory(TravelMemory item) async {
    final controller = TextEditingController(text: item.description);
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
                const Text(
                  'Edit Memory',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await travelData.updateMemory(
                        memoryId: item.id,
                        description: controller.text.trim().isEmpty
                            ? item.description
                            : controller.text.trim(),
                      );
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteMemory(TravelMemory item) async {
    await travelData.deleteMemory(item.id);
  }
}

