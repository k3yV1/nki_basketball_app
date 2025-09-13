import 'package:flutter/material.dart';
import 'package:nki_basketball/services/logout_service.dart';
import 'package:nki_basketball/services/subscriptions/subscriptions_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late int userId;
  late bool isReady;
  bool? selectedReady;
  bool isActiveSubscription = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isReady = false;
    selectedReady = null;
    isActiveSubscription = false;
    isLoading = true;
  }

  Future<void> _checkActiveSubscription(int userId) async {
    final hasActive = await SubscriptionsService().isActiveSubscription(userId);
    setState(() {
      isActiveSubscription = hasActive;
      isLoading = false;
    });

    // if (!hasActive) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('У вас нет активного абонемента')),
    //   );
    // }
  }

  Future<void> _updatePresence(bool ready) async {
    final success =
        await SubscriptionsService().updateUserReadyStatus(userId, ready);
    if (success) {
      setState(() {
        isReady = ready;
        selectedReady = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ready ? 'Вы записались на тренировку' : 'Вы отказались от участия',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при обновлении статуса')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String name = userData?['name'] ?? 'Имя';
    final String lastName = userData?['last_name'] ?? 'Фамилия';
    final String email = userData?['email'] ?? 'email@example.com';
    final String avatarUrl = userData?['avatar_url'] ??
        'https://api.dicebear.com/7.x/bottts/png?seed=$name+$lastName';
    final bool isAdmin = userData?['is_admin'] ?? false;

    userId = userData?['id'] ?? 0;
    isReady = userData?['is_ready'] ?? false;

    // При первом рендере запускаем проверку подписки
    if (isLoading) {
      _checkActiveSubscription(userId);
    }

    final bool shouldShowSave = selectedReady != null;

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
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Функция загрузки аватара в разработке')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Загрузить изображение'),
            ),
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

            // Блок показывается только если есть активная подписка
            if (isActiveSubscription)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.green),
                        label: const Text('Я буду'),
                        onPressed: () => setState(() => selectedReady = true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.green),
                          backgroundColor: (selectedReady ?? isReady) == true
                              ? Colors.green.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon:
                            const Icon(Icons.close, color: Colors.redAccent),
                        label: const Text('Не буду'),
                        onPressed: () => setState(() => selectedReady = false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                              color: Color.fromARGB(255, 249, 201, 201)),
                          backgroundColor: (selectedReady ?? isReady) == false
                              ? Colors.redAccent.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),
            const Spacer(),
            if (shouldShowSave)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _updatePresence(selectedReady!),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Сохранить изменения',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

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
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/signin', (route) => false);
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
