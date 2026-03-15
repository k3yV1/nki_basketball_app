import 'dart:convert';
import 'package:http/http.dart' as http;

class QueueService {
  final String baseUrl = "http://localhost:3000/api";

  /// Получить участников 
  

  
  /// Получить очередь по дате
  Future<List<String>> getQueue(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.get(
      Uri.parse("$baseUrl/trainings/queue?date=$formattedDate"),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      // объединяем name + last_name
      return data
          .map((e) => "${e["name"]} ${e["last_name"]}".trim())
          .toList()
          .cast<String>();
    } else {
      throw Exception("Ошибка загрузки очереди: ${response.body}");
    }
  }

  /// Встать на тренировку/в очередь по дате
  Future<Map<String, dynamic>> joinTraining(int userId, DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.post(
      Uri.parse("$baseUrl/trainings/join"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"userId": userId, "trainingDate": formattedDate}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      String errorMessage;
      try {
        final data = json.decode(response.body);
        errorMessage = data["message"] ?? "Не удалось записаться";
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : "Не удалось записаться";
      }
      throw Exception(errorMessage);
    }
  }

  /// Выйти из тренировки/очереди по дате
  Future<void> leaveTraining(int userId, DateTime date) async {
    print("leaveTraining called with userId: $userId and date: $date");
    final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    print("Formatted date for leaveTraining: $formattedDate");
    final response = await http.post(
      Uri.parse("$baseUrl/trainings/leave"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"userId": userId, "trainingDate": formattedDate}),
    );

    if (response.statusCode != 200) {
      String errorMessage;
      try {
        final data = json.decode(response.body);
        errorMessage = data["message"] ?? "Не удалось выйти";
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : "Не удалось выйти";
      }
      throw Exception(errorMessage);
    }
  }
}