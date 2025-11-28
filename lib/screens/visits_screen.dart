import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/visit.dart';

class VisitsScreen extends StatefulWidget {
  final List<Visit> visits;
  final List<String>? existingShops;

  VisitsScreen({required this.visits, this.existingShops});

  @override
  _VisitsScreenState createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  void _addVisitDialog() async {
    final shopController = TextEditingController();
    final ordersController = TextEditingController(text: '0');
    final settledController = TextEditingController(text: '0.0');
    bool hadOrder = false;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Visit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: shopController, decoration: InputDecoration(labelText: 'Shop name')),
              SizedBox(height: 8),
              Row(children: [
                Checkbox(value: hadOrder, onChanged: (v) { hadOrder = v ?? false; setState(() {}); }),
                Text('Took Order?'),
              ]),
              SizedBox(height: 8),
              TextField(controller: ordersController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Orders count')),
              SizedBox(height: 8),
              TextField(controller: settledController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Settled amount')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(onPressed: () {
            final id = const Uuid().v4();
            final shop = shopController.text.trim();
            final orders = int.tryParse(ordersController.text.trim()) ?? 0;
            final settled = double.tryParse(settledController.text.trim()) ?? 0.0;
            if (shop.isEmpty) return;
            final visit = Visit(id: id, shop: shop, hadOrder: hadOrder, ordersCount: orders, settledAmount: settled);
            widget.visits.add(visit);
            Navigator.pop(ctx, true);
          }, child: Text('Save')),
        ],
      ),
    );

    if (res == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Visits')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVisitDialog,
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: widget.visits.isEmpty
            ? Center(child: Text('No visits logged yet'))
            : ListView.builder(
                itemCount: widget.visits.length,
                itemBuilder: (context, idx) {
                  final v = widget.visits[idx];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(v.shop),
                      subtitle: Text('${v.date.toLocal().toString().split(' ')[0]} • Orders: ${v.ordersCount} • Settled: ₹${v.settledAmount.toStringAsFixed(2)}'),
                      trailing: v.hadOrder ? Icon(Icons.check_circle, color: Colors.green) : Icon(Icons.remove_circle, color: Colors.orange),
                      onTap: () async {
                        // edit visit
                        final ordersController = TextEditingController(text: v.ordersCount.toString());
                        final settledController = TextEditingController(text: v.settledAmount.toStringAsFixed(2));
                        bool had = v.hadOrder;
                        final changed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Edit Visit'),
                            content: Column(mainAxisSize: MainAxisSize.min, children: [
                              Row(children: [Checkbox(value: had, onChanged: (val) { had = val ?? false; setState(() {}); }), Text('Took Order?')]),
                              TextField(controller: ordersController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Orders count')),
                              TextField(controller: settledController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Settled amount')),
                            ],),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')), ElevatedButton(onPressed: () {
                              v.hadOrder = had;
                              v.ordersCount = int.tryParse(ordersController.text.trim()) ?? v.ordersCount;
                              v.settledAmount = double.tryParse(settledController.text.trim()) ?? v.settledAmount;
                              Navigator.pop(ctx, true);
                            }, child: Text('Save'))],
                          ),
                        );
                        if (changed == true) setState(() {});
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
