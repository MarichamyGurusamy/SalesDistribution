import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/order_item.dart';
import '../models/order.dart';

class OrderForm extends StatefulWidget {
  final List<Product> products;
  final List<String>? existingCustomers;

  const OrderForm({
    Key? key,
    required this.products,
    this.existingCustomers,
  }) : super(key: key);

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();

  // Customer fields
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final TextEditingController _paidController = TextEditingController(text: '0');
  final TextEditingController _noteController = TextEditingController();

  // Items + controllers
  final List<OrderItem> _items = [];
  final List<TextEditingController> _qtyControllers = [];

  bool _recalcScheduled = false;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  OrderItem _createEmptyItem() {
    return OrderItem(productId: '', product: null, quantity: 1, unitPrice: 0.0);
  }

  void _addItem() {
    final item = _createEmptyItem();
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    qtyCtrl.addListener(_scheduleRecalc);

    setState(() {
      _items.add(item);
      _qtyControllers.add(qtyCtrl);
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) {
      setState(() {
        _items[0] = _createEmptyItem();
        _qtyControllers[0].text = '1';
      });
      return;
    }

    try {
      _qtyControllers[index].removeListener(_scheduleRecalc);
      _qtyControllers[index].dispose();
    } catch (_) {}

    setState(() {
      _items.removeAt(index);
      _qtyControllers.removeAt(index);
    });

    _scheduleRecalc();
  }

  void _scheduleRecalc() {
    if (_recalcScheduled) return;
    _recalcScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performRecalc();
      _recalcScheduled = false;
    });
  }

  void _performRecalc() {
    for (var i = 0; i < _items.length; i++) {
      final q = int.tryParse(_qtyControllers[i].text) ?? 0;
      _items[i].quantity = q > 0 ? q : 0;
    }

    // Auto-fill paid amount for Cash/Invoice
    final totalAmount = _items.fold(0.0, (sum, item) => sum + item.total);
    if (_paymentMethod != PaymentMethod.qr) {
      _paidController.text = totalAmount.toStringAsFixed(2);
    }

    if (mounted) setState(() {});
  }

  double get _total => _items.fold(0.0, (s, it) => s + it.total);

  bool _validateAndSave() {
    if (!_formKey.currentState!.validate()) return false;
    final validItems = _items.where((it) => it.productId.isNotEmpty && it.quantity > 0).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product with quantity')),
      );
      return false;
    }
    return true;
  }

  void _submit() {
    if (!_validateAndSave()) return;

    final paid = (double.tryParse(_paidController.text) ?? 0.0).clamp(0.0, double.infinity);
    final cleanedItems = _items.where((it) => it.productId.isNotEmpty && it.quantity > 0).toList();
    final order = Order(
      id: const Uuid().v4(),
      customer: _customerController.text.trim(),
      items: cleanedItems,
      paidAmount: paid,
      paymentMethod: _paymentMethod,
      customerName: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    Navigator.of(context).pop(order);
  }

  @override
  void dispose() {
    _customerController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _paidController.dispose();
    _noteController.dispose();

    for (final c in _qtyControllers) {
      try {
        c.removeListener(_scheduleRecalc);
      } catch (_) {}
      c.dispose();
    }

    super.dispose();
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _customerController,
          decoration: const InputDecoration(labelText: 'Customer *', border: OutlineInputBorder()),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contactController,
          decoration: const InputDecoration(labelText: 'Contact Person', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Address (optional)', border: OutlineInputBorder()),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildItemRow(int idx) {
    final item = _items[idx];
    final qtyController = _qtyControllers[idx];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product dropdown
            DropdownButtonFormField<String>(
              value: item.productId.isEmpty ? null : item.productId,
              decoration: const InputDecoration(
                  labelText: 'Product *', border: OutlineInputBorder()),
              items: widget.products
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (₹${p.unitPrice.toStringAsFixed(2)})'),
                      ))
                  .toList(),
              onChanged: (val) {
                final prod = widget.products.firstWhere(
                    (p) => p.id == val,
                    orElse: () => Product(id: '', name: '', unitPrice: 0));
                setState(() {
                  item.productId = val ?? '';
                  item.product = val != null && val.isNotEmpty ? prod : null;
                  item.unitPrice = prod.unitPrice;
                });
              },
              validator: (_) => (item.productId.isEmpty) ? 'Select product' : null,
            ),
            const SizedBox(height: 10),
            // Quantity / Total / Delete row
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: qtyController,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(signed: false),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Qty > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Unit Price: ₹${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text('Total: ₹${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
                  onPressed: () => _removeItem(idx),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                          child: Text('Take Order',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold))),
                      ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Icon(Icons.add, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCustomerSection(),
                  const SizedBox(height: 16),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Products',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600))),
                  const SizedBox(height: 8),
                  ListView.builder(
                    itemCount: _items.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (ctx, idx) => _buildItemRow(idx),
                  ),
                  const SizedBox(height: 16),
                  // Payment + Paid Amount
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PaymentMethod>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(
                              labelText: 'Payment Method',
                              border: OutlineInputBorder()),
                          items: PaymentMethod.values
                              .where((pm) =>
                                  pm == PaymentMethod.cash ||
                                  pm == PaymentMethod.qr ||
                                  pm == PaymentMethod.invoice)
                              .map((pm) => DropdownMenuItem(
                                  value: pm,
                                  child: Text(
                                      pm.toString().split('.').last.toUpperCase())))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _paymentMethod = v ?? PaymentMethod.cash;
                              _performRecalc(); // auto update paid for QR/Cash/Invoice
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _paidController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Paid Amount', prefixText: '₹', border: OutlineInputBorder()),
                          readOnly: _paymentMethod == PaymentMethod.qr,
                          validator: (v) {
                            final paid = double.tryParse(v ?? '');
                            if (paid == null || paid < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                        labelText: 'Note (optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Order Total:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      const SizedBox(width: 8),
                      Text('₹${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Save Order'),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14))),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
