import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';

class CustomerStorage {
  static const _key = "customers";

  static Future<List<Customer>> loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];

    final decoded = jsonDecode(data) as List;
    return decoded.map((e) => Customer.fromJson(e)).toList();
  }

  static Future<void> saveCustomers(List<Customer> customers) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(customers.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
