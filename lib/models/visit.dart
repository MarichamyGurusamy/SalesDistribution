class Visit {
  final String id;
  final String shop; // shop name (customer/shop)
  DateTime date;
  bool hadOrder;
  int ordersCount;
  double settledAmount; // amount collected/settled during visit
  String? notes;

  Visit({
    required this.id,
    required this.shop,
    DateTime? date,
    this.hadOrder = false,
    this.ordersCount = 0,
    this.settledAmount = 0.0,
    this.notes,
  }) : date = date ?? DateTime.now();
}
