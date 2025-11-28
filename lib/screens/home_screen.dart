import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/export_service.dart';
import '../services/settlement_service.dart';
import '../models/visit.dart';
import '../widgets/jana_masala_logo.dart';
import 'visits_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? salesman;

  // In-memory demo lists (replace with persistent storage/service in production)
  static final List<Product> _productsDemo = [
    Product(id: 'p1', name: 'Product A', unitPrice: 10.0),
    Product(id: 'p2', name: 'Product B', unitPrice: 25.5),
  ];
  static final List<Order> _ordersDemo = [];
  static final List<Visit> _visitsDemo = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is String) salesman = arg;
  }

  double get _totalPending => _ordersDemo.fold(0.0, (s, o) => s + o.pending);

  double get _totalPaid => _ordersDemo.fold(0.0, (s, o) => s + o.paidAmount);

  double get _totalCash => SettlementService.calculateDailyCash(_ordersDemo);

  int get _cashOrderCount => SettlementService.getCashOrderCount(_ordersDemo);

  int get _visitsToday {
    final today = DateTime.now();
    return _visitsDemo
        .where((v) =>
            v.date.year == today.year &&
            v.date.month == today.month &&
            v.date.day == today.day)
        .length;
  }

  int get _visitsWithOrdersToday {
    final today = DateTime.now();
    return _visitsDemo
        .where((v) =>
            v.hadOrder &&
            v.date.year == today.year &&
            v.date.month == today.month &&
            v.date.day == today.day)
        .length;
  }

  int get _visitsWithoutOrdersToday {
    final today = DateTime.now();
    return _visitsDemo
        .where((v) =>
            !v.hadOrder &&
            v.date.year == today.year &&
            v.date.month == today.month &&
            v.date.day == today.day)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            JanaMasalaLogo(size: 32, showText: false, logoColor: Colors.white),
            SizedBox(width: 12),
            Text('Welcome ${salesman ?? "Salesman"}'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero summary card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE23744), Color(0xFFFFA502)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Summary",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Pending',
                          amount: _totalPending,
                          icon: Icons.pending_actions,
                          color: Colors.orange[300]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Paid',
                          amount: _totalPaid,
                          icon: Icons.check_circle,
                          color: Colors.lightGreen[300]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Visits Today',
                          amount: _visitsToday.toDouble(),
                          icon: Icons.storefront,
                          color: Colors.amber[300]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Action buttons grid (responsive)
                  LayoutBuilder(builder: (context, constraints) {
                    final crossCount = constraints.maxWidth < 700 ? 2 : 4;
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.08,
                      ),
                      children: [
                        _ActionCard(
                          title: 'Products',
                          icon: Icons.inventory_2,
                          color: const Color(0xFFE23744),
                          onTap: () async {
                            await Navigator.pushNamed(context, '/products',
                                arguments: _productsDemo);
                            setState(() {});
                          },
                        ),
                        _ActionCard(
                          title: 'Orders',
                          icon: Icons.receipt_long,
                          color: const Color(0xFFFFA502),
                          onTap: () async {
                            await Navigator.pushNamed(context, '/orders',
                                arguments: {
                                  'products': _productsDemo,
                                  'orders': _ordersDemo,
                                  'visits': _visitsDemo
                                });
                            setState(() {});
                          },
                        ),
                        _ActionCard(
                          title: 'Customers',
                          icon: Icons.people,
                          color: const Color(0xFF6A1B9A),
                          onTap: () async {
                            await Navigator.pushNamed(context, '/customers',
                                arguments: {'orders': _ordersDemo});
                            setState(() {});
                          },
                        ),
                        _ActionCard(
                          title: 'Visits',
                          icon: Icons.storefront,
                          color: const Color(0xFF00796B),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VisitsScreen(
                                  visits: _visitsDemo,
                                  existingShops: _ordersDemo
                                      .map((o) => o.customer)
                                      .toSet()
                                      .toList(),
                                ),
                              ),
                            );
                            setState(() {});
                          },
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  // Cash settlement section
                  if (_cashOrderCount > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA502), Color(0xFFFF8C00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cash to Settle',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${_totalCash.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_cashOrderCount cash order${_cashOrderCount > 1 ? "s" : ""}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.payments, size: 56, color: Colors.white30),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showSettlementDialog,
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Settle Cash',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFFFFA502),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Export button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_ordersDemo.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('No orders to export')));
                          return;
                        }
                        try {
                          final result = await ExportService.exportOrdersCsv(_ordersDemo);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ Exported: $result')));
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('✗ Export failed: ${e.toString()}')));
                        }
                      },
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text('Export Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color(0xFFE23744),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Info box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: const Text(
                      'Manage your sales efficiently.\nAdd products and track orders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettlementDialog() {
    final settlement = SettlementService.createSettlement(_ordersDemo);
    final cashOrders = _ordersDemo.where((o) => o.paymentMethod == PaymentMethod.cash && !o.isSettled).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Cash Settlement', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA502).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFA502), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JANA MASALA - Settlement Summary',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE23744)),
                    ),
                    const SizedBox(height: 12),
                    _SettlementRow('Already Collected', '₹${settlement.totalCollected.toStringAsFixed(2)}', Colors.green),
                    const SizedBox(height: 8),
                    _SettlementRow('Total To Settle', '₹${settlement.totalExpected.toStringAsFixed(2)}', Colors.orange),
                    const SizedBox(height: 8),
                    _SettlementRow('Cash Orders', '${settlement.orderCount}', Colors.blue),
                    const SizedBox(height: 8),
                    _SettlementRow('Settlement Date', settlement.date.toString().split(' ')[0], Colors.grey[600]!),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'Orders Included:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...cashOrders.map((o) {
                      final firstItem = o.items.isNotEmpty ? o.items.first : null;
                      final productLabel = firstItem?.product?.name ?? firstItem?.productId ?? o.product?.name ?? 'Unknown product';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${o.customer} - $productLabel',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₹${o.paidAmount.toStringAsFixed(2)} / ₹${o.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirming will mark all cash payments as settled for today (partial payments included).',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              SettlementService.markOrdersSettled(_ordersDemo, settlement);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Settlement confirmed! Settled: ₹${settlement.totalExpected.toStringAsFixed(2)}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Confirm Settlement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _SettlementRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _SummaryCard({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(amount.toStringAsFixed(2), style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _ActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 8, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, color: color, size: 48), const SizedBox(height: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))],
        ),
      ),
    );
  }
}
