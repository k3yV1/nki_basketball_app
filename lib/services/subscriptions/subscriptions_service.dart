import 'dart:convert';
import 'package:http/http.dart' as http;

class Subscription {
  final int id;
  final int user_id;
  final String name;
  final String last_name;
  final bool isPaid;
  final bool is_ready;

  Subscription({
    required this.id,
    required this.user_id,
    required this.name,
    required this.last_name,
    required this.isPaid,
    required this.is_ready,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'] ?? 'Unknown User',
      last_name: json['last_name'] ?? 'Unknown Last Name',
      user_id: json['user_id'],
      isPaid: json['is_paid'] == 1 || json['is_paid'],
      is_ready: json['is_ready'] == 1 || json['is_ready'] == true,
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
        print("active_subscriptions: ${jsonList}");
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

  Future<bool> isActiveSubscription(int userId) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/subscriptions/is_active_user_subscription/$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final isActive = data['isActive']?['subscription'] as bool? ?? false;
      return isActive;
    } else {
      print('Failed to fetch subscriptions: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error fetching subscriptions: $e');
    return false;
  }
}

Future<bool> getReadyStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/get_ready_status/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final isReady = data['isReady'] as bool? ?? false;
        print("User ready status: $isReady");
        return isReady;
      } else {
        print('Failed to fetch user ready status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error fetching user ready status: $e');
      return false;
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

  Future<bool> updateUserReadyStatus(int id, bool isReady) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/subscriptions/is_ready_user_to_be_training/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_ready': isReady}),
      );

      if (response.statusCode == 200) {
        print('User ready status updated successfully');
        return true;
      } else {
        print('Failed to update user ready status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating user ready status: $e');
      return false;
    }
  }
}
