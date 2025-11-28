import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/order.dart';

class OrderForm extends StatefulWidget {
  final List<Product> products;
  final List<String>? existingCustomers;

  OrderForm({required this.products, this.existingCustomers});

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  Product? _selected;
  late TextEditingController _customerController;
  bool _customerListenerAttached = false;
  final _personController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  double _paid = 0;
  late TextEditingController _paidController;
  PaymentMethod _method = PaymentMethod.cash;
  final _note = TextEditingController();

  @override
  void dispose() {
    if (_customerListenerAttached) _customerController.removeListener(_customerListener);
    try {
      _customerController.dispose();
    } catch (_) {}
    _quantity.dispose();
    _paidController.dispose();
    _note.dispose();
    _personController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _customerListener() => setState(() {});

  void _submit() {
    if (_formKey.currentState!.validate() && _selected != null) {
      final qty = int.parse(_quantity.text.trim());
      final id = const Uuid().v4();
      final paidVal = double.tryParse(_paidController.text) ?? _paid;
      final order = Order(
        id: id,
        customer: _customerController.text.trim(),
        customerName: _personController.text.trim().isEmpty ? null : _personController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        product: _selected!,
        quantity: qty,
        paidAmount: paidVal,
        paymentMethod: _method,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      Navigator.of(context).pop(order);
    }
  }

  double get _total => (_selected?.unitPrice ?? 0) * (int.tryParse(_quantity.text) ?? 0);

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController();
    _customerController.addListener(_customerListener);
    _customerListenerAttached = true;
    _paidController = TextEditingController(text: _paid.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Take Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: Column(children: [
              // Customer name with autocomplete suggestions
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final list = widget.existingCustomers ?? [];
                    if (textEditingValue.text == '') return list;
                    return list.where((c) => c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (selection) {
                    _customerController.text = selection;
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    // Keep a reference to the internal controller so we can read value on submit
                    if (_customerController != textEditingController) {
                      // dispose our previous controller (created in initState) to avoid leaks
                      try {
                        _customerController.removeListener(_customerListener);
                        _customerController.dispose();
                      } catch (_) {}
                      _customerController = textEditingController;
                    }
                    // ensure listener is attached
                    if (!_customerListenerAttached) {
                      _customerController.addListener(_customerListener);
                      _customerListenerAttached = true;
                    }
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'Customer name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter customer' : null,
                    );
                  },
                ),
              ),
              // If this is a new customer (not in existing list) show optional contact fields
              Builder(builder: (context) {
                final existing = widget.existingCustomers ?? [];
                final current = _customerController.text.trim();
                final isNew = current.isNotEmpty && !existing.any((c) => c.toLowerCase() == current.toLowerCase());
                if (!isNew) return SizedBox.shrink();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: _personController,
                        decoration: const InputDecoration(labelText: 'Contact person (optional)'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone (optional)'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address (optional)'),
                        maxLines: 2,
                      ),
                    ),
                  ],
                );
              }),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: widget.products
                      .map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.unitPrice.toStringAsFixed(2)})')))
                      .toList(),
                  onChanged: (v) => setState(() {
                        _selected = v;
                        // update paid based on current method
                        if (_method == PaymentMethod.cash) {
                          _paid = _total;
                        } else {
                          _paid = _paid.clamp(0, _total);
                        }
                        _paidController.text = _paid.toStringAsFixed(2);
                      }),
                  validator: (v) => (v == null) ? 'Choose product' : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _quantity,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {
                        // when qty changes, update paid amount for cash payments
                        if (_method == PaymentMethod.cash) {
                          _paid = _total;
                        } else {
                          _paid = _paid.clamp(0, _total);
                        }
                        _paidController.text = _paid.toStringAsFixed(2);
                      }),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter qty';
                    final val = int.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Enter valid qty';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total: ${_total.toStringAsFixed(2)}'),
                Text('Paid: ${_paid.toStringAsFixed(2)}'),
              ]),
              const SizedBox(height: 12),
              // Payment input: for Cash, force full-paid and show numeric readonly; for Invoice allow numeric input
              if (_method == PaymentMethod.cash)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paid (Cash - full payment)'),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _paidController,
                        readOnly: true,
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paid (Invoice - partial allowed)'),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _paidController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          hintText: 'Enter paid amount',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0;
                          setState(() {
                            _paid = parsed.clamp(0, _total);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<PaymentMethod>(
                  value: _method,
                  decoration: const InputDecoration(labelText: 'Payment method'),
                  items: PaymentMethod.values
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.toString().split('.').last.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setState(() {
                        _method = v ?? PaymentMethod.cash;
                        // If cash selected, default paid to total; otherwise clamp paid to total
                        if (_method == PaymentMethod.cash) {
                          _paid = _total;
                        } else {
                          _paid = _paid.clamp(0, _total);
                        }
                        _paidController.text = _paid.toStringAsFixed(2);
                      }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _submit, child: const Text('Save')),
              ]),
            ]),
          )
        ]),
      ),
    );
  }
}
