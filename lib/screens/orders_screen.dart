import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/visit.dart';
import '../widgets/order_form.dart';

enum OrderFilter { all, today, month }

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late List<Product> products;
  late List<Order> orders;
  List<Visit>? visits;
  OrderFilter _filter = OrderFilter.all;

  List<Order> get _filteredOrders {
    final now = DateTime.now();
    if (_filter == OrderFilter.today) {
      return orders.where((o) {
        final d = o.date.toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();
    } else if (_filter == OrderFilter.month) {
      return orders.where((o) {
        final d = o.date.toLocal();
        return d.year == now.year && d.month == now.month;
      }).toList();
    }
    return orders;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is Map) {
      products = (arg['products'] as List<Product>?) ?? [];
      orders = (arg['orders'] as List<Order>?) ?? [];
      visits = (arg['visits'] as List<Visit>?) ?? [];
    } else {
      products = [];
      orders = [];
    }
  }

  void _addOrder(Order o) {
    // For QR orders, always start as Pending (paidAmount = 0)
    if (o.paymentMethod.toString().toLowerCase().contains('qr')) {
      o.paidAmount = 0;
    }

    setState(() {
      orders.add(o);
    });

    try {
      if (visits != null) {
        final now = DateTime.now();
        final found = visits!.cast().firstWhere(
          (v) =>
              v.shop == o.customer &&
              v.date.year == now.year &&
              v.date.month == now.month &&
              v.date.day == now.day,
          orElse: () => null,
        );
        if (found != null) {
          found.hadOrder = true;
          found.ordersCount = (found.ordersCount ?? 0) + 1;
          found.settledAmount = (found.settledAmount ?? 0) + o.paidAmount;
        } else {
          final v = (() {
            try {
              return Visit(
                id: const Uuid().v4(),
                shop: o.customer,
                hadOrder: true,
                ordersCount: 1,
                settledAmount: o.paidAmount,
              );
            } catch (_) {
              return null;
            }
          })();
          if (v != null) visits!.add(v);
        }
      }
    } catch (_) {}
  }

  void _showItemsPopup(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Ordered Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(flex: 4, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: order.items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, idx) {
                        final it = order.items[idx];
                        final pname = it.product?.name ?? it.productId;
                        final lineTotal = it.quantity * it.unitPrice;
                        return Row(
                          children: [
                            Expanded(flex: 4, child: Text(pname)),
                            Expanded(flex: 1, child: Text('${it.quantity}')),
                            Expanded(flex: 2, child: Text('₹${it.unitPrice.toStringAsFixed(2)}')),
                            Expanded(flex: 2, child: Text('₹${lineTotal.toStringAsFixed(2)}')),
                          ],
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQRWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI integration required for QR payment.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA502).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFA502), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Orders', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${orders.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFA502))),
                    ],
                  ),
                  Icon(Icons.receipt_long, size: 56, color: const Color(0xFFFFA502).withOpacity(0.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Filters
            Row(
              children: [
                ChoiceChip(label: const Text('All'), selected: _filter == OrderFilter.all, onSelected: (_) => setState(() => _filter = OrderFilter.all)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Today'), selected: _filter == OrderFilter.today, onSelected: (_) => setState(() => _filter = OrderFilter.today)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('This Month'), selected: _filter == OrderFilter.month, onSelected: (_) => setState(() => _filter = OrderFilter.month)),
                const Spacer(),
                Text('Showing: ${_filteredOrders.length}', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 12),
            // Orders List
            Expanded(
              child: _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No orders yet', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Take your first order to get started', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, i) {
                        final o = _filteredOrders[i];

                        final total = o.total;
                        final paid = o.paidAmount;
                        final pending = o.total - o.paidAmount;
                        final isPaid = pending <= 0;
                        final statusColor = isPaid ? Colors.green : Colors.orange;
                        final statusLabel = isPaid ? 'PAID' : 'PENDING';
                        final showQR = o.paymentMethod.toString().toLowerCase().contains('qr') && !isPaid;

                        return StatefulBuilder(builder: (context, setStateTile) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 8, offset: const Offset(0, 4))],
                              border: Border.all(color: Colors.grey[200]!, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Customer Name + Status + QR
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          o.customerName ?? o.customer,
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (showQR)
                                            GestureDetector(
                                              onTap: _showQRWarning,
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: Colors.blue, width: 1.5),
                                                ),
                                                child: const Icon(Icons.qr_code, size: 20, color: Colors.blue),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: statusColor, width: 1.5),
                                            ),
                                            child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Details row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _DetailItem(label: 'Total', value: '₹${total.toStringAsFixed(2)}', icon: Icons.price_change, color: const Color(0xFFE23744)),
                                      _DetailItem(label: 'Paid', value: '₹${paid.toStringAsFixed(2)}', icon: Icons.check_circle, color: Colors.green),
                                      _DetailItem(label: 'Due', value: '₹${pending.toStringAsFixed(2)}', icon: Icons.warning_rounded, color: Colors.orange),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Footer
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.payment, size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(o.paymentMethod.toString().split('.').last.toUpperCase(),
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 12),
                                          Text(o.date.toLocal().toString().split(' ')[0], style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () => _showItemsPopup(o),
                                        child: Text('View items (${o.items.length})'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      },
                    ),
            ),
            // Add order button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: const Text('Take Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final Order? result = await showModalBottomSheet<Order>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => OrderForm(products: products, existingCustomers: orders.map((o) => o.customer).toSet().toList()),
                  );
                  if (result != null) _addOrder(result);
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFFE23744)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _DetailItem({
    required String label,
    required String value,
    required IconData icon,
    Color color = const Color(0xFFE23744),
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.7)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
