import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/settlement.dart';

class SettlementService {
  static final List<Settlement> _settlementHistory = [];

  // Get settlement history
  static List<Settlement> getSettlementHistory() => _settlementHistory;

  // Calculate total cash to be settled (all CASH payment orders that are NOT settled)
  static double calculateDailyCash(List<Order> orders) {
    // Sum the total order value for unsettled CASH orders so partial payments
    // are included in the final settlement calculation (paid + pending).
    return orders
      .where((o) => o.paymentMethod == PaymentMethod.cash && !o.isSettled)
      .fold(0.0, (sum, o) => sum + o.total);
  }

  // Get count of cash orders (not yet settled)
  static int getCashOrderCount(List<Order> orders) {
    return orders.where((o) => o.paymentMethod == PaymentMethod.cash && !o.isSettled).length;
  }

  // Create settlement record
  static Settlement createSettlement(List<Order> orders) {
    // For cash settlement, only include unsettled CASH orders
    final cashOrders = orders.where((o) => o.paymentMethod == PaymentMethod.cash && !o.isSettled).toList();
    // totalExpected is the sum of order totals for included cash orders
    final totalExpected = cashOrders.fold(0.0, (s, o) => s + o.total);
    // totalCollected is the sum of amounts already collected (partial/full)
    final totalCollected = cashOrders.fold(0.0, (s, o) => s + o.paidAmount);

    return Settlement(
      id: const Uuid().v4(),
      date: DateTime.now(),
      totalCollected: totalCollected,
      totalExpected: totalExpected,
      orderCount: cashOrders.length,
    );
  }

  // Mark cash orders as settled (set isSettled flag to true)
  static void markOrdersSettled(List<Order> orders, Settlement settlement) {
    // Mark unsettled CASH orders as settled and clear their pending by setting paidAmount = total
    final cashOrders = orders.where((o) => o.paymentMethod == PaymentMethod.cash && !o.isSettled).toList();
    for (final o in cashOrders) {
      // ensure the cash order is fully paid when settling cash
      o.paidAmount = o.total;
      o.isSettled = true;
    }
    
    // Add settlement to history
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

  // Get total settled today
  static double getTotalSettledToday() {
    // Sum collected amounts from today's settlements
    return getTodaySettlements().fold(0.0, (sum, s) => sum + s.totalCollected);
  }

  // Calculate total invoice due (sum of pending for invoice orders)
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

