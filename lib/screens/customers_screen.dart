import 'package:flutter/material.dart';
import '../models/order.dart';

class CustomersScreen extends StatefulWidget {
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Order> _orders = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map && args['orders'] is List<Order>) {
      _orders = args['orders'] as List<Order>;
    }
  }

  List<String> get _customers {
    final set = <String>{};
    for (final o in _orders) set.add(o.customer);
    final list = set.toList();
    list.sort();
    return list;
  }

  double _totalPaidFor(String customer) => _orders.where((o) => o.customer == customer).fold(0.0, (s, o) => s + o.paidAmount);

  double _totalPendingFor(String customer) => _orders.where((o) => o.customer == customer).fold(0.0, (s, o) => s + o.pending);

  List<Order> _ordersFor(String customer) => _orders.where((o) => o.customer == customer).toList();

  void _showCustomerDetails(String customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final orders = _ordersFor(customer);
        return StatefulBuilder(builder: (context, setStateSheet) {
          void refresh() => setState(() { setStateSheet(() {}); });

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, controller) => Column(
                children: [
                  SizedBox(height: 12),
                  Container(width: 40, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8))),
                  SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(customer, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('Paid: ₹${_totalPaidFor(customer).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.green[700], fontWeight: FontWeight.w600)),
                          Text('Due: ₹${_totalPendingFor(customer).toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.red[700])),
                        ])
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: orders.isEmpty
                        ? Center(child: Text('No orders for this customer'))
                        : ListView.builder(
                            controller: controller,
                            itemCount: orders.length,
                            itemBuilder: (context, idx) {
                              final o = orders[idx];
                              final isPaid = o.pending <= 0;
                              final statusColor = isPaid ? Colors.green : Colors.orange;
                              final statusLabel = isPaid ? 'PAID' : 'PENDING';

                              return Container(
                                margin: EdgeInsets.only(bottom: 12, left: 12, right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 8, offset: Offset(0, 4))],
                                  border: Border.all(color: Colors.grey[200]!, width: 1),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(o.product.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                                SizedBox(height: 4),
                                                Text('${o.quantity} pcs', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: statusColor, width: 1.2),
                                            ),
                                            child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(child: _DetailItem(label: 'Total', value: '₹${o.total.toStringAsFixed(2)}', icon: Icons.price_change, color: Color(0xFFE23744))),
                                          Expanded(child: _DetailItem(label: 'Paid', value: '₹${o.paidAmount.toStringAsFixed(2)}', icon: Icons.check_circle, color: Colors.green)),
                                          Expanded(child: _DetailItem(label: 'Due', value: '₹${o.pending.toStringAsFixed(2)}', icon: Icons.warning_rounded, color: Colors.orange)),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(children: [Icon(Icons.payment, size: 16, color: Colors.grey[600]), SizedBox(width: 6), Text(o.paymentMethod.toString().split('.').last.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600))]),
                                          Row(children: [Text(o.date.toLocal().toString().split(' ')[0], style: TextStyle(fontSize: 12, color: Colors.grey[500])), SizedBox(width: 8), ElevatedButton(onPressed: o.pending<=0?null:() async { final paid = await _showAddPaymentDialog(o); if (paid!=null && paid>0){ setState((){}); setStateSheet((){});} }, child: Text('Add Payment'))])
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<double?> _showAddPaymentDialog(Order order) async {
    final controller = TextEditingController(text: order.pending.toStringAsFixed(2));
    double? result;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order: ${order.product.name} • Due: ₹${order.pending.toStringAsFixed(2)}'),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(prefixText: '₹ ', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text) ?? 0;
              final toApply = (v.clamp(0, order.pending)).toDouble();
              if (toApply <= 0) return;
              order.paidAmount += toApply;
              result = toApply;
              Navigator.pop(ctx);
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customers')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header summary similar to Orders
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE23744).withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE23744), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customers', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text('${_customers.length}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE23744))),
                    ],
                  ),
                  Icon(Icons.people, size: 56, color: Color(0xFFE23744).withOpacity(0.6)),
                ],
              ),
            ),
            SizedBox(height: 18),
            Expanded(
              child: _customers.isEmpty
                  ? Center(child: Text('No customers yet'))
                  : ListView.builder(
                      itemCount: _customers.length,
                      itemBuilder: (context, idx) {
                        final name = _customers[idx];
                        final paid = _totalPaidFor(name);
                        final due = _totalPendingFor(name);
                        final count = _orders.where((o) => o.customer == name).length;
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 8, offset: Offset(0, 4))],
                            border: Border.all(color: Colors.grey[200]!, width: 1),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  _DetailItem(label: 'Orders', value: '$count', icon: Icons.list_alt, color: Color(0xFFE23744)),
                                  _DetailItem(label: 'Paid', value: '₹${paid.toStringAsFixed(2)}', icon: Icons.check_circle, color: Colors.green),
                                  _DetailItem(label: 'Due', value: '₹${due.toStringAsFixed(2)}', icon: Icons.warning_rounded, color: Colors.orange),
                                ],
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
                            onTap: () => _showCustomerDetails(name),
                          ),
                        );
                      },
                    ),
            ),
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
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
