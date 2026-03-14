import 'package:flutter/material.dart';
import 'package:nki_basketball/services/logout_service.dart';
import 'package:nki_basketball/services/subscriptions/subscriptions_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int userId = 0;
  bool isReady = false; 
  
  bool? selectedReady;
  bool isActiveSubscription = false;
  bool isLoading = true;
  bool _dataInitialized = false; // Флаг для однократной инициализации

  @override
  void initState() {
    super.initState();
    selectedReady = null;
    isActiveSubscription = false;
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
      _checkActiveSubscription(userId);
      _dataInitialized = true;
    }
  }

  // ⭐️ ИЗМЕНЕНО: Загружаем не только подписку, но и актуальный isReady
  Future<void> _checkActiveSubscription(int userId) async {
    // ⚠️ ПРЕДПОЛАГАЕТСЯ, что SubscriptionsService().getSubscriptionStatus(userId)
    // возвращает актуальные данные: {'hasActive': bool, 'isReady': bool}
    
    // Вам нужно будет реализовать этот метод в SubscriptionsService, 
    // чтобы он возвращал оба поля из БД.
    final hasActive = await SubscriptionsService().isActiveSubscription(userId);
    // ❌ ВАЖНО: Вместо hasActive, вам нужно получать полный статус, 
    // включая isReady, из БД. Так как у меня нет вашего SubscriptionsService, 
    // я просто беру hasActive, но ВАМ нужно тут получить и актуальный isReady с сервера.
    // 
    // Пример, если бы у вас был метод getReadyStatus:
    final currentIsReady = await SubscriptionsService().getReadyStatus(userId);
    
    if (mounted) {
      setState(() {
        isActiveSubscription = hasActive;
        isReady = currentIsReady; // ⭐️ Устанавливаем isReady АКТУАЛЬНЫМ значением с сервера
        isLoading = false;
      });
    }
  }

  Future<void> _updatePresence(bool ready) async {
    final success =
        await SubscriptionsService().updateUserReadyStatus(userId, ready);
    if (success) {
      if (mounted) {
        setState(() {
          isReady = ready; // isReady теперь обновляется только здесь
          selectedReady = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ready ? 'Вы записались на тренировку' : 'Вы отказались от участия',
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при обновлении статуса')),
        );
      }
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

            // Блок показывается только если есть активная подписка
            if (isActiveSubscription && !isLoading) // Добавляем проверку isLoading
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
                          // ЛОГИКА
                          backgroundColor: (selectedReady == true || (selectedReady == null && isReady == true))
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
                          // ЛОГИКА
                          backgroundColor: (selectedReady == false || (selectedReady == null && isReady == false))
                              ? Colors.redAccent.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white)), // Показываем загрузку, пока не получим isReady

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