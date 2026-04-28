class Expense {
  final int id;
  final double amount;
  final String category;
  final String note;
  final String date;
  final String tripId;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.note = '',
    this.date = '',
    this.tripId = '',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] ?? '',
      note: json['note']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      tripId: json['tripId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date,
      'tripId': tripId,
    };
  }
}
