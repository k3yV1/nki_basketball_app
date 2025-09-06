import 'dart:convert';
import 'package:http/http.dart' as http;

class QueueService {
  final String baseUrl = "http://localhost:3000/api/trainings"; 

  /// Получить очередь по дате
Future<List<String>> getQueue(DateTime date) async {
  final formattedDate =
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  final response = await http.get(
    Uri.parse("$baseUrl/queue?date=$formattedDate"),
  );

  if (response.statusCode == 200) {
    final List data = json.decode(response.body);

    // объединяем name + last_name
    return data
        .map((e) => "${e["name"]} ${e["last_name"]}")
        .toList()
        .cast<String>();
  } else {
    throw Exception("Ошибка при загрузке очереди: ${response.body}");
  }
}


  /// Встать в очередь
  Future<void> addToQueue(String trainingId, String userId, DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.post(
      Uri.parse("$baseUrl/$trainingId/queue"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"userId": userId, "trainingDate": formattedDate}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        json.decode(response.body)["message"] ?? "Не удалось добавить",
      );
    }
  }

  /// Убрать из очереди
  Future<void> removeFromQueue(String userId, DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.delete(
      Uri.parse("$baseUrl/queue"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"userId": userId, "date": formattedDate}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        json.decode(response.body)["message"] ?? "Не удалось удалить",
      );
    }
  }
}
