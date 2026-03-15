import 'dart:convert';
import 'package:http/http.dart' as http;

class TrainingService {
  final String baseUrl = "http://localhost:3000/api";

  /// Получить пользователей с абонементом
  Future<List<Map<String, dynamic>>> getSubscribers() async {
    final response = await http.get(
      Uri.parse("$baseUrl/subscriptions/active_subscriptions"),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        json.decode(response.body),
      );
    } else {
      throw Exception("Ошибка загрузки участников");
    }
  }

  /// Пользователь не придёт на тренировку
  Future<void> skipTraining(String userId, DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.post(
      Uri.parse("$baseUrl/training/skip"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "userId": userId,
        "trainingDate": formattedDate,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Не удалось отменить участие");
    }
  }

  /// Встать в очередь
  Future<void> joinQueue(String userId, DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.post(
      Uri.parse("$baseUrl/training/queue"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "userId": userId,
        "trainingDate": formattedDate,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Не удалось встать в очередь");
    }
  }
}