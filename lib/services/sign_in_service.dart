import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nki_basketball/services/tokenStorage/token_storage.dart';

class SignInService {
  final String _baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final token = responseData['token']; // <-- JWT

      // Теперь запросим данные пользователя с этим токеном
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/auth/me'), // или /auth/me, в зависимости от API
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final token = responseData['token'];
        print('Токен: $token');
        //await _storage.write(key: 'token', value: token);
        await TokenStorage().saveToken(token);

        return userData; // Данные пользователя
      } else {
        print('Ошибка получения данных пользователя');
        return null;
      }
    } else {
      print('Ошибка логина: ${response.body}');
      return null;
    }
  }
}
