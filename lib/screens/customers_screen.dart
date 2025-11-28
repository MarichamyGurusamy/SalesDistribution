import 'package:flutter/material.dart';
import '../models/order.dart';

class CustomersScreen extends StatefulWidget {
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Order> _orders = [];

  // Store editable customer meta separately to avoid mutating Order objects
  final Map<String, Map<String, String>> _customerInfo = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final route = ModalRoute.of(context);
      if (route == null) return;
      final args = route.settings.arguments;
      if (args is Map && args['orders'] is List<Order>) {
        _orders = args['orders'] as List<Order>;
      } else if (args is List<Order>) {
        _orders = args;
      } else if (args is List<dynamic>) {
        final casted = args.whereType<Order>().toList();
        if (casted.isNotEmpty) _orders = casted;
      }
    } catch (e, st) {
      debugPrint('didChangeDependencies parse error: $e\n$st');
    }

    // populate _customerInfo with any existing details from orders (first available)
    for (final o in _orders) {
      final key = o.customer ?? '';
      if (key.isEmpty) continue;
      _customerInfo.putIfAbsent(key, () {
        final map = <String, String>{};
        if ((o.customerName ?? '').isNotEmpty) map['contact'] = o.customerName!;
        if ((o.phone ?? '').isNotEmpty) map['phone'] = o.phone!;
        if ((o.address ?? '').isNotEmpty) map['address'] = o.address!;
        return map;
      });
    }
  }

  List<String> get _customers {
    final set = <String>{};
    for (final o in _orders) {
      if ((o.customer ?? '').isNotEmpty) set.add(o.customer!);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  double _totalPaidFor(String customer) =>
      _orders.where((o) => o.customer == customer).fold(0.0, (s, o) => s + (o.paidAmount ?? 0.0));

  double _totalPendingFor(String customer) =>
      _orders.where((o) => o.customer == customer).fold(0.0, (s, o) => s + (o.pending ?? 0.0));

  List<Order> _ordersFor(String customer) =>
      _orders.where((o) => o.customer == customer).toList();

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    try {
      setState(fn);
    } catch (e) {
      debugPrint('safeSetState error: $e');
    }
  }

  void _showCustomerDetails(String customer) {
    try {
      final orders = _ordersFor(customer);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                minChildSize: 0.4,
                maxChildSize: 0.95,
                builder: (_, controller) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(customer, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('Paid: ₹${_totalPaidFor(customer).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.green[700], fontWeight: FontWeight.w600)),
                              Text('Due: ₹${_totalPendingFor(customer).toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.red[700])),
                            ]),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  final changed = await _showEditCustomerDialog(customer);
                                  if (changed == true) {
                                    _safeSetState(() {});
                                    setStateSheet(() {});
                                  }
                                } catch (e) {
                                  debugPrint('edit dialog error: $e');
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to edit customer')));
                                }
                              },
                              child: const Text('Edit Details'),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: orders.isEmpty
                            ? const Center(child: Text('No orders for this customer'))
                            : ListView.builder(
                                controller: controller,
                                itemCount: orders.length,
                                itemBuilder: (context, idx) {
                                  final o = orders[idx];
                                  final isPaid = (o.pending ?? 0) <= 0;
                                  final statusColor = isPaid ? Colors.green : Colors.orange;
                                  final statusLabel = isPaid ? 'PAID' : 'PENDING';

                                  final productName = o.product?.name ?? 'Unknown';
                                  final qty = o.quantity ?? 0;
                                  final total = o.total ?? 0.0;
                                  final paid = o.paidAmount ?? 0.0;
                                  final pending = o.pending ?? 0.0;
                                  final paymentLabel = (o.paymentMethod?.toString().split('.').last.toUpperCase()) ?? 'UNKNOWN';
                                  final dateLabel = (o.date != null) ? o.date!.toLocal().toString().split(' ')[0] : '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 8, offset: const Offset(0, 4))],
                                      border: Border.all(color: Colors.grey[200]!, width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
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
                                                    Text(productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                                                    const SizedBox(height: 4),
                                                    Text('$qty pcs', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: statusColor, width: 1.2),
                                                ),
                                                child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(child: _DetailItem(label: 'Total', value: '₹${total.toStringAsFixed(2)}', icon: Icons.price_change, color: const Color(0xFFE23744))),
                                              const SizedBox(width: 12),
                                              Expanded(child: _DetailItem(label: 'Paid', value: '₹${paid.toStringAsFixed(2)}', icon: Icons.check_circle, color: Colors.green)),
                                              const SizedBox(width: 12),
                                              Expanded(child: _DetailItem(label: 'Due', value: '₹${pending.toStringAsFixed(2)}', icon: Icons.warning_rounded, color: Colors.orange)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(children: [const Icon(Icons.payment, size: 16, color: Colors.grey), const SizedBox(width: 6), Text(paymentLabel, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))]),
                                              Row(children: [Text(dateLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(width: 8), ElevatedButton(onPressed: pending <= 0 ? null : () async {
                                                final paidAdded = await _showAddPaymentDialog(o);
                                                if (paidAdded != null && paidAdded > 0) {
                                                  _safeSetState(() {});
                                                  setStateSheet(() {});
                                                }
                                              }, child: const Text('Add Payment'))])
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
                  );
                },
              ),
            );
          });
        },
      );
    } catch (e, st) {
      debugPrint('showCustomerDetails failed: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open customer details')));
    }
  }

  Future<double?> _showAddPaymentDialog(Order order) async {
    double? result;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: (order.pending ?? 0.0).toStringAsFixed(2));
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Order: ${order.product?.name ?? 'Unknown'} • Due: ₹${(order.pending ?? 0).toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: '₹ ', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(controller.text) ?? 0;
                  final toApply = (v.clamp(0, order.pending ?? 0)).toDouble();
                  if (toApply <= 0) return;
                  try {
                    order.paidAmount = (order.paidAmount ?? 0) + toApply;
                    result = toApply;
                  } catch (e) {
                    debugPrint('Failed to apply payment: $e');
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to update order in memory')));
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        });
      },
    );
    return result;
  }

  Future<bool?> _showEditCustomerDialog(String customer) async {
    // Use _customerInfo map to avoid mutating Order objects directly
    final info = _customerInfo.putIfAbsent(customer, () => {'contact': '', 'phone': '', 'address': ''});
    bool changed = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController(text: info['contact'] ?? '');
        final phoneController = TextEditingController(text: info['phone'] ?? '');
        final addressController = TextEditingController(text: info['address'] ?? '');

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Details for "$customer"'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // NOTE: don't repeat contact info here — it's displayed on the Customer List only
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Contact person')),
                  const SizedBox(height: 8),
                  TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 8),
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final n = nameController.text.trim();
                  final p = phoneController.text.trim();
                  final a = addressController.text.trim();

                  // Save into _customerInfo map (safe, won't mutate Order objects)
                  _customerInfo[customer] = {'contact': n, 'phone': p, 'address': a};
                  changed = true;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Save'),
              )
            ],
          );
        });
      },
    );

    return result ?? changed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header summary similar to Orders
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE23744).withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE23744), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customers', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${_customers.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE23744))),
                    ],
                  ),
                  Icon(Icons.people, size: 56, color: const Color(0xFFE23744).withOpacity(0.6)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _customers.isEmpty
                  ? const Center(child: Text('No customers yet'))
                  : ListView.builder(
                      itemCount: _customers.length,
                      itemBuilder: (context, idx) {
                        final name = _customers[idx];
                        final paid = _totalPaidFor(name);
                        final due = _totalPendingFor(name);
                        final count = _orders.where((o) => o.customer == name).length;
                        final info = _customerInfo[name];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 8, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey[200]!, width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // show contact / phone / address only on the customer-list page (single place)
                                  if ((info?['contact']?.isNotEmpty ?? false) || (info?['phone']?.isNotEmpty ?? false) || (info?['address']?.isNotEmpty ?? false))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if ((info?['contact']?.isNotEmpty ?? false))
                                            Text('Contact: ${info!['contact']}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                          if ((info?['phone']?.isNotEmpty ?? false))
                                            Text('Phone: ${info!['phone']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                          if ((info?['address']?.isNotEmpty ?? false))
                                            Text('Address: ${info!['address']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                        ],
                                      ),
                                    ),
                                  // spaced Orders | Paid | Due row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: _DetailItem(label: 'Orders', value: '$count', icon: Icons.list_alt, color: const Color(0xFFE23744))),
                                      const SizedBox(width: 12),
                                      Expanded(child: _DetailItem(label: 'Paid', value: '₹${paid.toStringAsFixed(2)}', icon: Icons.check_circle, color: Colors.green)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _DetailItem(label: 'Due', value: '₹${due.toStringAsFixed(2)}', icon: Icons.warning_rounded, color: Colors.orange)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
    return Column(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center),
      ],
    );
  }
}
