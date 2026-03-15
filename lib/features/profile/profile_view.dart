import 'package:flutter/material.dart';
import 'package:nki_basketball/services/logout_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int userId = 0;
  
  bool _dataInitialized = false; // Флаг для однократной инициализации

  @override
  void initState() {
    super.initState();
  }

  // ⭐️ ИСПОЛЬЗУЕМ didChangeDependencies ДЛЯ ИНИЦИАЛИЗАЦИИ И ЗАПУСКА ЗАГРУЗКИ
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataInitialized) { // Инициализируем только один раз
      final userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      // Инициализируем userId из аргументов
      userId = userData?['id'] ?? 0;
      
      // Запускаем асинхронную проверку, которая установит isLoading=false и isReady
      _dataInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Аргументы используем только для статических данных (имя, почта и т.д.)
    final userData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String name = userData?['name'] ?? 'Имя';
    final String lastName = userData?['last_name'] ?? 'Фамилия';
    final String email = userData?['email'] ?? 'email@example.com';
    final String avatarUrl = userData?['avatar_url'] ??
        'https://api.dicebear.com/7.x/bottts/png?seed=$name+$lastName';
    final bool isAdmin = userData?['is_admin'] ?? false;

    // ❌ УДАЛЕНО: Логика инициализации userId и isReady из userData

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff2c5364),
              Color(0xff203e43),
              Color(0xff0f2027),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 60),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                avatarUrl,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            // const SizedBox(height: 12),
            // OutlinedButton(
            //   onPressed: () {
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //           content: Text('Функция загрузки аватара в разработке')),
            //     );
            //   },
            //   style: OutlinedButton.styleFrom(
            //     side: const BorderSide(color: Colors.white),
            //     foregroundColor: Colors.white,
            //     shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8)),
            //   ),
            //   child: const Text('Загрузить изображение'),
            // ),
            const SizedBox(height: 24),
            Text(
              '$name $lastName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                '🏅 MVP: 3 награды',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 14),

            const Spacer(),

            if (isAdmin)
              Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/users');
                      },
                      child: const Text(
                        'Пользователи',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/subscriptions');
                      },
                      child: const Text(
                        'Активные абоненты',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Кнопка "Выйти"
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await LogoutService().logout();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/signin', (route) => false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Выйти',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}