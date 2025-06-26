import 'package:http/http.dart' as http;
import 'package:nki_basketball/services/tokenStorage/token_storage.dart';

class LogoutService {
  final String _baseUrl = 'http://localhost:3000/api';
  Future<void> logout() async {
    try {
      // Получаем токен
      final token = await TokenStorage().getToken();
      print('Токен для выхода: $token');
      // Отправляем запрос на сервер (если есть такая необходимость)
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }

      // Удаляем токен из локального хранилища
      //await _storage.delete(key: 'token');
      await TokenStorage().clearToken();
    } catch (e) {
      print('Ошибка при выходе: $e');
      // Можно показать Snackbar или Alert
    }
  }
}
