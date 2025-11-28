class Settlement {
  final String id;
  final DateTime date;
  // Amount already collected (sum of paidAmount at time of settlement creation)
  final double totalCollected;
  // Total expected to be collected for included orders (sum of order.total)
  final double totalExpected;
  final int orderCount;
  final String? notes;

  Settlement({
    required this.id,
    required this.date,
    required this.totalCollected,
    required this.totalExpected,
    required this.orderCount,
    this.notes,
  });

  double get totalDue => totalExpected - totalCollected;
}
