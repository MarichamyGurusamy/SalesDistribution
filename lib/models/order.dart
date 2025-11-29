import 'product.dart';
import 'order_item.dart';

enum PaymentMethod { cash, qr, invoice, unknown }

class Order {
  final String id;
  final String customer;

  // legacy single-product fields (optional)
  Product? product;
  int? quantity;

  // legacy total storage (nullable) — kept so older JSON/constructors still work.
  double? _legacyTotal;

  // multi-item support
  List<OrderItem> items;

  String? customerName;
  String? phone;
  String? address;

  final DateTime date;
  double paidAmount;
  PaymentMethod paymentMethod;
  final String? note;
  bool isSettled;

  Order({
    required this.id,
    required this.customer,
    this.product,
    this.quantity,
    List<OrderItem>? items,
    this.customerName,
    this.phone,
    this.address,
    this.paidAmount = 0.0,
    this.paymentMethod = PaymentMethod.unknown,
    this.note,
    DateTime? date,
    this.isSettled = false,
    double? total, // legacy constructor param mapped to private _legacyTotal
  })  : _legacyTotal = total,
        items = items ?? _createFromLegacy(product, quantity, total),
        date = date ?? DateTime.now();

  // Always return a (possibly empty) List<OrderItem> — never null.
  static List<OrderItem> _createFromLegacy(Product? product, int? qty, double? total) {
    if (product == null) return <OrderItem>[];
    final q = qty ?? 1;
    // Determine a sensible unitPrice: prefer explicit total if present.
    final unit = (total != null && q > 0) ? (total / q) : (product.unitPrice);
    return [OrderItem(productId: product.id, product: product, quantity: q, unitPrice: unit)];
  }

  // Computed total across items.
  double get computedTotal => items.fold(0.0, (s, it) => s + it.total);

  // Non-null total getter used throughout app (falls back to legacy total if present).
  double get total => _legacyTotal ?? computedTotal;

  // Short alias kept for readability in some places
  double get totalAmount => total;

  double get pending {
    final val = total - paidAmount;
    return val <= 0 ? 0.0 : val;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer': customer,
        'items': items.map((i) => i.toJson()).toList(),
        'paidAmount': paidAmount,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'date': date.toIso8601String(),
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'note': note,
        'isSettled': isSettled,
        'total': total,
      };

  factory Order.fromJson(Map<String, dynamic> json, {List<Product>? products}) {
    final itemsJson = (json['items'] as List?) ?? [];
    final parsedItems = itemsJson.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final pid = m['productId'] as String;
      final prod = products?.firstWhere((p) => p.id == pid, orElse: () => Product(id: pid, name: pid, unitPrice: 0.0));
      return OrderItem.fromJson(m, product: prod);
    }).toList();

    Product? legacyProd;
    if (parsedItems.isEmpty && json['product'] != null) {
      final p = json['product'];
      if (p is Map) {
        legacyProd = Product(
          id: p['id'] ?? '',
          name: p['name'] ?? '',
          unitPrice: (p['unitPrice'] ?? 0.0).toDouble(),
        );
      }
    }

    return Order(
      id: json['id'] ?? '',
      customer: json['customer'] ?? '',
      product: legacyProd,
      quantity: (json['quantity'] as int?) ?? json['qty'] as int?,
      items: parsedItems.isNotEmpty ? parsedItems : null,
      paidAmount: (json['paidAmount'] ?? 0.0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == (json['paymentMethod'] ?? 'unknown'),
        orElse: () => PaymentMethod.unknown,
      ),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      customerName: json['customerName'],
      phone: json['phone'],
      address: json['address'],
      note: json['note'],
      isSettled: json['isSettled'] == true,
      total: (json['total'] as num?)?.toDouble(),
    );
  }
}
