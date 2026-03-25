import 'dart:convert';
import 'package:http/http.dart' as http;

class QueueEntry {
  final int userId;
  final String fullName;

  QueueEntry({required this.userId, required this.fullName});
}

class QueueService {
  final String baseUrl = "http://localhost:3000/api";

  bool _isAlreadyJoinedMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('уже записаны') ||
        normalized.contains('already') && normalized.contains('join');
  }

  /// Получить фактических участников тренировки (training_participants)
  Future<List<QueueEntry>> getParticipants(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final url = "$baseUrl/trainings/participants?date=$formattedDate";
    print('[QueueService] getParticipants → GET $url');

    final response = await http.get(Uri.parse(url));
    print('[QueueService] getParticipants ← status=${response.statusCode} body=${response.body}');

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      final List<dynamic> entries = decoded is List ? decoded : [];

      final result = entries
          .map((e) {
            if (e is! Map<String, dynamic>) return null;
            final int parsedUserId =
                int.tryParse(
                  (e['user_id'] ?? e['id'] ?? e['userId'] ?? 0).toString(),
                ) ??
                0;
            final String fullName =
                (e['full_name'] ??
                        e['fullName'] ??
                        "${e['name'] ?? ''} ${e['last_name'] ?? e['lastName'] ?? ''}")
                    .toString()
                    .trim();
            if (fullName.isEmpty) return null;
            return QueueEntry(userId: parsedUserId, fullName: fullName);
          })
          .whereType<QueueEntry>()
          .toList();

      print('[QueueService] getParticipants parsed: ${result.map((e) => '{userId:${e.userId}, name:${e.fullName}}').toList()}');
      return result;
    } else {
      // endpoint may not exist yet — return empty list gracefully
      print('[QueueService] getParticipants endpoint not available (${response.statusCode}), returning []');
      return [];
    }
  }

  /// Получить очередь по дате
  Future<List<QueueEntry>> getQueue(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final url = "$baseUrl/trainings/queue?date=$formattedDate";
    print('[QueueService] getQueue → GET $url');

    final response = await http.get(Uri.parse(url));
    print('[QueueService] getQueue ← status=${response.statusCode} body=${response.body}');

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);

      List<dynamic> entries;
      if (decoded is List) {
        entries = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final dynamic queueData =
            decoded['queue'] ?? decoded['data'] ?? decoded['items'] ?? [];
        entries = queueData is List ? queueData : [];
      } else {
        entries = [];
      }

      final result = entries
          .map((e) {
            if (e is String) {
              return QueueEntry(userId: 0, fullName: e.trim());
            }

            final Map<String, dynamic> item = e is Map<String, dynamic>
                ? e
                : <String, dynamic>{};

            final int parsedUserId =
                int.tryParse(
                  (item['user_id'] ?? item['userId'] ?? item['id'] ?? 0)
                      .toString(),
                ) ??
                0;
            final String fullName =
                (item['full_name'] ??
                        item['fullName'] ??
                        "${item['name'] ?? ''} ${item['last_name'] ?? item['lastName'] ?? ''}")
                    .toString()
                    .trim();

            return QueueEntry(userId: parsedUserId, fullName: fullName);
          })
          .where((entry) => entry.fullName.isNotEmpty)
          .toList();

      print('[QueueService] getQueue parsed: ${result.map((e) => '{userId:${e.userId}, name:${e.fullName}}').toList()}');
      return result;
    } else {
      print('[QueueService] getQueue endpoint error (${response.statusCode}): ${response.body}, returning []');
      return [];
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
        errorMessage = response.body.isNotEmpty
            ? response.body
            : "Не удалось записаться";
      }

      if (_isAlreadyJoinedMessage(errorMessage)) {
        // Backward compatibility: some backend paths return 500 instead of 409
        // for "already joined"; treat this as an existing queue/training state.
        return {"status": "already_joined", "message": errorMessage};
      }

      throw Exception(errorMessage);
    }
  }

  /// Выйти из тренировки/очереди по дате
  /// Автоматически промотирует первого из очереди на место участника, если оно освободилось
  Future<Map<String, dynamic>> leaveTraining(int userId, DateTime date) async {
    print("leaveTraining called with userId: $userId and date: $date");
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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
        errorMessage = response.body.isNotEmpty
            ? response.body
            : "Не удалось выйти";
      }
      throw Exception(errorMessage);
    }
    
    // Успешно вышли, можно распарсить ответ
    try {
      return json.decode(response.body);
    } catch (e) {
      return {"message": "Вы успешно вышли из тренировки"};
    }
  }
}
