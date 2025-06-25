import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpService {
  final String _baseUrl = 'http://localhost:3000/api';

  Future<dynamic> register({
    required String email,
    required String password,
    required String name,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'last_name': lastName,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        print('✅ Регистрация успешна. Токен: $token');
        print("true");
        return true; // Успешно
      } else {
        final error = jsonDecode(response.body);
        print('❌ Ошибка регистрации: $error');
        return {
          'error': error['message'] ?? 'Неизвестная ошибка регистрации',
        };
      }
    } catch (e) {
      print('❌ Ошибка сети/исключение: $e');
      return {
        'error': 'Ошибка сети: $e',
      };
    }
  }
}
