import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  final int id;
  final String name;
  final String email;
  final String last_name;
  final bool is_ready;
  bool subscription;
  bool is_paid;


  User({
    required this.id,
    required this.name,
    required this.email,
    required this.last_name,
    required this.is_ready,
    required this.subscription,
    required this.is_paid,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? 'Unknown Email',
      last_name: json['last_name'] ?? 'Unknown Last Name',
      is_ready: json['is_ready'] == 1 || json['is_ready'] == true,
      subscription: json['subscription'] == 1 || json['subscription'] == true,
      name: json['name'] ?? 'Unknown User',
      is_paid: json['is_paid'] == 1 || json['is_paid'] == true,
    );
  }
}


class UsersService {
  final String _baseUrl = 'http://localhost:3000/api';

  Future<List<User>> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        print('Failed to fetch users: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<void> updateSubscription(int user_id, bool isPaid) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/subscriptions/active_subscription/$user_id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'is_paid': isPaid}),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при обновлении подписки');
    }
  }

  Future<void> activateSubscription(int user_id) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/subscriptions/upsert_user_subscription/$user_id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': user_id, 'is_paid': true}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Ошибка при активации абонемента: ${response.statusCode} ${response.body}',
      );
    }
  }
}