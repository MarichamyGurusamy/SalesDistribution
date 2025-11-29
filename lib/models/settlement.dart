class Settlement {
  final String id;
  final DateTime date;
  final double totalCollected;
  final double totalExpected;
  final int orderCount;

  Settlement({
    required this.id,
    required this.date,
    required this.totalCollected,
    required this.totalExpected,
    required this.orderCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'totalCollected': totalCollected,
        'totalExpected': totalExpected,
        'orderCount': orderCount,
      };

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      totalCollected: (json['totalCollected'] as num?)?.toDouble() ?? 0.0,
      totalExpected: (json['totalExpected'] as num?)?.toDouble() ?? 0.0,
      orderCount: (json['orderCount'] as int?) ?? (json['order_count'] as int?) ?? 0,
    );
  }
}