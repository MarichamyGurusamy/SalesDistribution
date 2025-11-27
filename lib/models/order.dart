import 'product.dart';

enum PaymentMethod { cash, qr, invoice }

class Order {
  final String id;
  final String customer;
  final Product product;
  final int quantity;
  final DateTime date;
  double paidAmount;
  final PaymentMethod paymentMethod;
  final String? note;
  bool isSettled; // Track if cash order has been settled

  Order({
    required this.id,
    required this.customer,
    required this.product,
    required this.quantity,
    required this.paidAmount,
    required this.paymentMethod,
    this.note,
    DateTime? date,
    this.isSettled = false,
  }) : date = date ?? DateTime.now();

  double get total => product.unitPrice * quantity;
  
  // If order is cash and settled, pending is 0. Otherwise, pending = total - paid
  double get pending {
    if (paymentMethod == PaymentMethod.cash && isSettled) {
      return 0.0;
    }
    return (total - paidAmount) < 0 ? 0 : (total - paidAmount);
  }
}
