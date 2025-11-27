// Web implementation: create a downloadable blob and trigger browser download.
import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import '../models/order.dart';

class ExportService {
  // Exports orders to a CSV and triggers a browser download.
  // Returns a string describing the download (filename).
  static Future<String> exportOrdersCsv(List<Order> orders, {String? filename}) async {
    if (orders.isEmpty) throw Exception('No orders to export');

    final List<List<dynamic>> rows = [
      ['Order ID', 'Date', 'Customer', 'Product', 'UnitPrice', 'Quantity', 'Total', 'Paid', 'Pending', 'PaymentMethod', 'Note']
    ];
    for (final o in orders) {
      rows.add([
        o.id,
        o.date.toIso8601String(),
        o.customer,
        o.product.name,
        o.product.unitPrice,
        o.quantity,
        o.total,
        o.paidAmount,
        o.pending,
        o.paymentMethod.toString().split('.').last,
        o.note ?? ''
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final name = filename ?? 'orders_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', name)
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return name;
  }
}
