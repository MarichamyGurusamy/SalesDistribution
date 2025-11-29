import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/settlement.dart';

class SettlementService {
  static final List<Settlement> _settlementHistory = [];

  // Get settlement history
  static List<Settlement> getSettlementHistory() => List.unmodifiable(_settlementHistory);

  // Calculate total cash to be settled (sum of order totals for unsettled CASH orders)
  // (this includes partial payments by adding pending + paid when needed since total is full order value)
  static double calculateDailyCash(List<Order> orders) {
    return orders
        .where((o) => o.paymentMethod == PaymentMethod.cash && !o.isSettled)
        .fold(0.0, (sum, o) => sum + o.total);
  }

  // Get count of cash orders (not yet settled)
  static int getCashOrderCount(List<Order> orders) {
    return orders.where((o) => o.paymentMethod == PaymentMethod.cash && !o.isSettled).length;
  }

  // Create settlement record (includes unsettled CASH orders)
  static Settlement createSettlement(List<Order> orders) {
    final cashOrders = orders.where((o) => o.paymentMethod == PaymentMethod.cash && !o.isSettled).toList();

    final totalExpected = cashOrders.fold(0.0, (s, o) => s + o.total);
    final totalCollected = cashOrders.fold(0.0, (s, o) => s + o.paidAmount);
    final count = cashOrders.length;

    return Settlement(
      id: const Uuid().v4(),
      date: DateTime.now(),
      totalCollected: totalCollected,
      totalExpected: totalExpected,
      orderCount: count,
    );
  }

  // Mark cash orders as settled (set isSettled flag and mark paidAmount = total)
  static void markOrdersSettled(List<Order> orders, Settlement settlement) {
    final cashOrders = orders.where((o) => o.paymentMethod == PaymentMethod.cash && !o.isSettled).toList();
    for (final o in cashOrders) {
      o.paidAmount = o.total;
      o.isSettled = true;
    }

    _settlementHistory.add(settlement);
  }

  // Get today's settlements
  static List<Settlement> getTodaySettlements() {
    final today = DateTime.now();
    return _settlementHistory.where((s) {
      return s.date.year == today.year &&
          s.date.month == today.month &&
          s.date.day == today.day;
    }).toList();
  }

  // Get total settled today (sum of collected amounts from today's settlements)
  static double getTotalSettledToday() {
    return getTodaySettlements().fold(0.0, (sum, s) => sum + s.totalCollected);
  }

  // Calculate total invoice due (sum of pending for invoice orders that are unsettled)
  static double calculateInvoiceDue(List<Order> orders) {
    return orders
        .where((o) => o.paymentMethod == PaymentMethod.invoice && !o.isSettled)
        .fold(0.0, (sum, o) => sum + o.pending);
  }

  // Count of invoice orders with due
  static int getInvoiceDueCount(List<Order> orders) {
    return orders.where((o) => o.paymentMethod == PaymentMethod.invoice && o.pending > 0 && !o.isSettled).length;
  }
}
