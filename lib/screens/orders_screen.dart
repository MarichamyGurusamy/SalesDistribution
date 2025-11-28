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
    setState(() {
      orders.add(o);
    });
    // If a visits list was provided, update or create today's visit for this shop
    try {
      if (visits != null) {
        final now = DateTime.now();
        final found = visits!.cast().firstWhere((v) => v.shop == o.customer && v.date.year == now.year && v.date.month == now.month && v.date.day == now.day, orElse: () => null);
        if (found != null) {
          found.hadOrder = true;
          found.ordersCount = (found.ordersCount ?? 0) + 1;
          found.settledAmount = (found.settledAmount ?? 0) + o.paidAmount;
        } else {
          // create a new visit entry
          final v = 
            // avoid importing Visit here by constructing via Map-like fields
            ((){
              try {
                // dynamic creation assuming Visit class available
                return Visit(id: const Uuid().v4(), shop: o.customer, hadOrder: true, ordersCount: 1, settledAmount: o.paidAmount);
              } catch (_) { return null; }
            })();
          if (v != null) visits!.add(v);
        }
      }
    } catch (_) {}
  }

  Future<void> _logVisitNoOrder() async {
    final shopController = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Visit (No Order)'),
        content: TextField(controller: shopController, decoration: InputDecoration(labelText: 'Shop name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(onPressed: () {
            final shop = shopController.text.trim();
            if (shop.isEmpty) return;
            try {
              final v = Visit(id: const Uuid().v4(), shop: shop, hadOrder: false, ordersCount: 0, settledAmount: 0.0);
              visits?.add(v);
            } catch (_) {}
            Navigator.pop(ctx, true);
          }, child: Text('Save'))
        ],
      ),
    );

    if (res == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with count
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFA502).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFFA502), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Orders',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${orders.length}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFA502),
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.receipt_long, size: 56, color: Color(0xFFFFA502).withOpacity(0.5)),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Filter chips: All / Today / This Month
            Row(
              children: [
                ChoiceChip(
                  label: Text('All'),
                  selected: _filter == OrderFilter.all,
                  onSelected: (_) => setState(() => _filter = OrderFilter.all),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Today'),
                  selected: _filter == OrderFilter.today,
                  onSelected: (_) => setState(() => _filter = OrderFilter.today),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('This Month'),
                  selected: _filter == OrderFilter.month,
                  onSelected: (_) => setState(() => _filter = OrderFilter.month),
                ),
                Spacer(),
                Text('Showing: ${_filteredOrders.length}', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            SizedBox(height: 12),
            // Orders list
            Expanded(
              child: _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Take your first order to get started',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, i) {
                        final o = _filteredOrders[i];
                        final isPaid = o.pending <= 0;
                        final statusColor = isPaid ? Colors.green : Colors.orange;
                        final statusLabel = isPaid ? 'PAID' : 'PENDING';
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[300]!,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey[200]!, width: 1),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Customer and status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            o.customer,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            o.product.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor, width: 1.5),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                // Details row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _DetailItem(
                                      label: 'Qty',
                                      value: '${o.quantity}',
                                      icon: Icons.shopping_cart,
                                    ),
                                    _DetailItem(
                                      label: 'Total',
                                      value: '₹${o.total.toStringAsFixed(2)}',
                                      icon: Icons.price_change,
                                      color: Color(0xFFE23744),
                                    ),
                                    _DetailItem(
                                      label: 'Paid',
                                      value: '₹${o.paidAmount.toStringAsFixed(2)}',
                                      icon: Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    _DetailItem(
                                      label: 'Due',
                                      value: '₹${o.pending.toStringAsFixed(2)}',
                                      icon: Icons.warning_rounded,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                // Footer info
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                                          SizedBox(width: 6),
                                          Text(
                                            o.paymentMethod.toString().split('.').last.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      o.date.toLocal().toString().split(' ')[0],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Add order button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.add_shopping_cart, size: 20),
                label: Text('Take Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final Order? result = await showModalBottomSheet<Order>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => OrderForm(
                          products: products,
                          existingCustomers: orders.map((o) => o.customer).toSet().toList(),
                        ),
                  );
                  if (result != null) _addOrder(result);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Color(0xFFFFA502),
                ),
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
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
