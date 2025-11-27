class Settlement {
  final String id;
  final DateTime date;
  final double totalCash;
  final int orderCount;
  final String? notes;

  Settlement({
    required this.id,
    required this.date,
    required this.totalCash,
    required this.orderCount,
    this.notes,
  });
}
