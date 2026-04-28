import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/travel_data_service.dart';
import '../services/sync_service.dart';

class ExpenseScreen extends StatefulWidget {
  final bool embedded;

  const ExpenseScreen({super.key, this.embedded = false});

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TravelDataService travelData = TravelDataService.instance;

  List<Expense> expenses = [];
  bool loading = false;
  bool addingExpense = false;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchExpenses();
    travelData.addListener(_handleTravelDataChanged);
  }

  @override
  void dispose() {
    travelData.removeListener(_handleTravelDataChanged);
    amountController.dispose();
    categoryController.dispose();
    noteController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void _handleTravelDataChanged() {
    if (!mounted) return;
    setState(() {
      expenses = travelData.expenses;
    });
  }

  Future<void> fetchExpenses() async {
    try {
      setState(() => loading = true);
      await travelData.initialize();
      setState(() {
        expenses = travelData.expenses;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load expenses: $e')));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> addExpense({Expense? editingExpense}) async {
    final amountText = amountController.text.trim();
    final category = categoryController.text.trim();
    final note = noteController.text.trim();
    final date = dateController.text.trim();

    if (amountText.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount and category are required')),
      );
      return;
    }

    try {
      setState(() => addingExpense = true);
      final amount = double.parse(amountText);

      if (editingExpense != null) {
        final updated = Expense(
          id: editingExpense.id,
          amount: amount,
          category: category,
          note: note,
          date: date.isNotEmpty ? date : editingExpense.date,
          tripId: editingExpense.tripId,
        );
        await travelData.updateExpense(updated);
      } else {
        await travelData.addExpense(
          amount: amount,
          category: category,
          note: note,
          date: date,
        );
      }

      if (!mounted) return;

      amountController.clear();
      categoryController.clear();
      noteController.clear();
      dateController.clear();

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editingExpense != null ? 'Expense updated successfully' : 'Expense added successfully')),
      );

      await fetchExpenses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => addingExpense = false);
      }
    }
  }

  double get totalAmount {
    return travelData.totalExpense;
  }

  double get remainingAmount => travelData.remainingBudget;

  int get spentPercent => (travelData.spentPercentage * 100).round();

  int get daysRemaining {
    if (travelData.tripEndDate == null) return 1;
    final diff = travelData.tripEndDate!.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  double get dailySafeSpend => remainingAmount / daysRemaining;

  List<Expense> get filteredExpenses {
    if (selectedFilter == 'All') return expenses;
    return expenses.where((expense) {
      final value = expense.category.toLowerCase();
      switch (selectedFilter) {
        case 'Dining':
          return value.contains('food') ||
              value.contains('dining') ||
              value.contains('restaurant');
        case 'Stay':
          return value.contains('hotel') || value.contains('stay');
        case 'Transport':
          return value.contains('travel') ||
              value.contains('transport') ||
              value.contains('metro');
        case 'Others':
          return !(value.contains('food') ||
              value.contains('dining') ||
              value.contains('restaurant') ||
              value.contains('hotel') ||
              value.contains('stay') ||
              value.contains('travel') ||
              value.contains('transport') ||
              value.contains('metro'));
        default:
          return true;
      }
    }).toList();
  }

  String get insightText {
    return expenses.isEmpty
        ? 'Looks like your spending is more on dining today than usual. Consider exploring local markets for dinner.'
        : 'Looks like your spending is more on ${filteredExpenses.isEmpty ? expenses.first.category.toLowerCase() : filteredExpenses.first.category.toLowerCase()} today than usual. Consider exploring local markets for dinner.';
  }

  Color _categoryColor(String category) {
    final value = category.toLowerCase();
    if (value.contains('food') || value.contains('dining')) {
      return const Color(0xFF85E4C8);
    }
    if (value.contains('travel') || value.contains('transport')) {
      return const Color(0xFFB7D9FF);
    }
    if (value.contains('hotel') || value.contains('stay')) {
      return const Color(0xFFD9D3FF);
    }
    return const Color(0xFFE4E8EE);
  }

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();
    if (value.contains('food') || value.contains('dining')) {
      return Icons.restaurant_rounded;
    }
    if (value.contains('travel') || value.contains('transport')) {
      return Icons.train_rounded;
    }
    if (value.contains('hotel') || value.contains('stay')) {
      return Icons.hotel_rounded;
    }
    if (value.contains('shopping')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  void _showAddExpenseSheet({Expense? editingExpense}) {
    if (editingExpense != null) {
      amountController.text = editingExpense.amount.toString();
      categoryController.text = editingExpense.category;
      noteController.text = editingExpense.note;
      dateController.text = editingExpense.date;
    } else {
      amountController.clear();
      categoryController.clear();
      noteController.clear();
      dateController.clear();
    }

    showModalBottomSheet<void>(
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
                  editingExpense != null ? 'Edit Expense' : 'Add Expense',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: addingExpense ? null : () => addExpense(editingExpense: editingExpense),
                    child: Text(addingExpense ? 'Saving...' : (editingExpense != null ? 'Update Expense' : 'Add Expense')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        amountController.clear();
        categoryController.clear();
        noteController.clear();
        dateController.clear();
      }
    });
  }

  Widget _buildFilterChip(String label) {
    final active = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0B5F8E) : const Color(0xFFF0F2F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : const Color(0xFF737B87),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseTile(Expense expense, int index) {
    final amount = expense.amount.toStringAsFixed(2);
    final chipColor = _categoryColor(expense.category);
    final icon = _categoryIcon(expense.category);
    String timeText = expense.date.isNotEmpty ? expense.date.split('T').first : '';
    
    if (expense.tripId.isNotEmpty) {
      final trip = travelData.previousTrips.where((t) => t.id == expense.tripId).firstOrNull;
      if (trip != null && trip.destination.isNotEmpty) {
        timeText = timeText.isEmpty ? trip.destination : '$timeText • ${trip.destination}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  expense.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF29465B),
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _showAddExpenseSheet(editingExpense: expense);
                    },
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF008080),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      TravelDataService.instance.deleteExpense(expense.id);
                    },
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF008080)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.note.isEmpty ? expense.category : expense.note,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2530),
                      ),
                    ),
                    if (timeText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '₹$amount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF008080),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!travelData.tripIsActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flight_takeoff_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Trip is not started',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2530)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please plan and start a trip first.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final visibleExpenses = filteredExpenses;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: fetchExpenses,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF004D40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004D40).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total spent',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF80CBC4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.auto_awesome_rounded, color: Color(0xFF80CBC4), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Good standing',
                                style: TextStyle(
                                  color: Color(0xFF80CBC4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Dining'),
                    _buildFilterChip('Stay'),
                    _buildFilterChip('Transport'),
                    _buildFilterChip('Others'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F252D),
                ),
              ),
              const SizedBox(height: 14),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visibleExpenses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'No expenses found',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ...visibleExpenses.asMap().entries.map(
                  (entry) => _buildExpenseTile(entry.value, entry.key),
                ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddExpenseSheet(editingExpense: null),
            backgroundColor: const Color(0xFF008080),
            elevation: 0,
            highlightElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded),
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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text('Expenses')),
      body: SafeArea(child: _buildBody()),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String label;
  final bool active;

  const _CurrencyChip(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE9F4FA) : const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: active ? const Color(0xFF0B5F8E) : const Color(0xFF818B97),
        ),
      ),
    );
  }
}
