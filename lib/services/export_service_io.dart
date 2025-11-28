import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
// share_plus removed to avoid plugin build errors on some environments.
import '../models/order.dart';

class ExportService {
  // Exports orders to CSV in Downloads or temp and triggers share when possible.
  // Returns a string describing where the file was saved (path).
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

    // Returning file path; callers can share/upload the file using platform tools.

    return file.path;
  }
}
