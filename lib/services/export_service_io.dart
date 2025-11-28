import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class ExportService {
  // Exports orders to CSV in Downloads or temp and returns saved file path.
  static Future<String> exportOrdersCsv(List<Order> orders, {String? filename}) async {
    if (orders.isEmpty) throw Exception('No orders to export');

    final List<List<dynamic>> rows = [
      [
        'Order ID',
        'Date',
        'Customer',
        'Products', // joined product names / ids
        'UnitPrices', // joined unit prices per item
        'Quantities', // joined quantities per item
        'LineTotals', // joined per-item totals
        'Total', // order total
        'Paid',
        'Pending',
        'PaymentMethod',
        'Note'
      ]
    ];

    for (final o in orders) {
      // Build an item list — prefer multi-item Order.items, fall back to legacy product/quantity
      final List<OrderItem> items = (o.items.isNotEmpty)
          ? o.items
          : (o.product != null ? [OrderItem(productId: o.product!.id, product: o.product, quantity: o.quantity ?? 1, unitPrice: o.product!.unitPrice)] : []);

      final productNames = items.map((it) => it.product?.name ?? it.productId).join(' | ');
      final unitPrices = items.map((it) => it.unitPrice.toStringAsFixed(2)).join(' | ');
      final quantities = items.map((it) => it.quantity.toString()).join(' | ');
      final lineTotals = items.map((it) => it.total.toStringAsFixed(2)).join(' | ');

      rows.add([
        o.id,
        o.date.toIso8601String(),
        o.customer,
        productNames,
        unitPrices,
        quantities,
        lineTotals,
        o.total.toStringAsFixed(2),
        o.paidAmount.toStringAsFixed(2),
        o.pending.toStringAsFixed(2),
        o.paymentMethod.toString().split('.').last,
        o.note ?? ''
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    Directory? outputDir;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        outputDir = await getDownloadsDirectory();
      } else {
        outputDir = await getTemporaryDirectory();
      }
    } catch (_) {
      outputDir = null;
    }

    if (outputDir == null) outputDir = Directory.systemTemp;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final name = filename ?? 'orders_$timestamp.csv';
    final file = File('${outputDir.path}${Platform.pathSeparator}$name');
    await file.writeAsString(csv, flush: true);
    return file.path;
  }
}
