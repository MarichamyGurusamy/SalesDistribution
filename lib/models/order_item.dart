import 'product.dart';

class OrderItem {
  String productId;
  Product? product;
  int quantity;
  double unitPrice;

  OrderItem({
    required this.productId,
    this.product,
    this.quantity = 1,
    this.unitPrice = 0.0,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json, {Product? product}) {
    return OrderItem(
      productId: json['productId'] ?? '',
      product: product,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? (product?.unitPrice ?? 0.0),
    );
  }
}
