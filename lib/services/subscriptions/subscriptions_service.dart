import 'dart:convert';
import 'package:http/http.dart' as http;

class Subscription {
  final int id;
  final int userId;
  final String name;
  final String last_name;
  final bool isPaid;

  Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.last_name,
    required this.isPaid,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'] ?? 'Unknown User',
      last_name: json['last_name'] ?? 'Unknown Last Name',
      userId: json['user_id'],
      isPaid: json['is_paid'] == 1 || json['is_paid'] == true,
    );
  }
}

class SubscriptionsService {
  final String _baseUrl = 'http://localhost:3000/api';

  Future<List<Subscription>> fetchSubscriptions() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/subscriptions/active_subscriptions'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Subscription.fromJson(json)).toList();
      } else {
        print('Failed to fetch subscriptions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      return [];
    }
  }

  Future<bool> updateSubscriptionStatus(int id, bool isPaid) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/subscriptions/active_subscription/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_paid': isPaid}),
      );

      if (response.statusCode == 200) {
        print('Subscription updated successfully');
        return true;
      } else {
        print('Failed to update subscription: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating subscription: $e');
      return false;
    }
  }
}
