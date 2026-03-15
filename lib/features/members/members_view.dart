import 'package:flutter/material.dart';
import 'package:nki_basketball/data/models/member_model.dart';
import 'package:nki_basketball/services/subscriptions/subscriptions_service.dart';
import 'package:nki_basketball/services/queue/queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MembersView extends StatefulWidget {
  final DateTime date;
  final String type;

  const MembersView({
    Key? key,
    required this.date,
    required this.type,
  }) : super(key: key);

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  static final Map<String, bool> _absenceCache = {}; // persist within app session (short-living)
  static const _prefsKey = 'absent_trainings';


  final _subscriptionsService = SubscriptionsService();
  final _queueService = QueueService();

  List<Member> _members = [];
  List<String> _queue = [];
  bool _isLoading = true;

  late int _userId;
  String _currentUserName = '';

  bool _isUserActive = false; // Есть ли абонемент
  bool _isUserInQueue = false; // В очереди ли сейчас
  bool _isUserInMembers = false; // В основном ли списке (абонементщик)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _userId = int.tryParse(args?['id']?.toString() ?? '0') ?? 0;
      await _loadAbsentCache();
      await _fetchData();
    });
  }

  Future<void> _fetchData() async {
    try {
      // 1. Получаем всех, у кого есть абонемент
      final subscriptions = await _subscriptionsService.fetchSubscriptions();
      
      // 2. Получаем текущую очередь на эту дату из БД
      final queue = await _queueService.getQueue(widget.date);

      // 3. Находим данные текущего пользователя
      final matchingSubs = subscriptions.where((s) => s.user_id == _userId);
      final userSub = matchingSubs.isNotEmpty ? matchingSubs.first : null;
      
      String normalizeName(String name, String lastName) =>
          '${name.trim()} ${lastName.trim()}'.trim().toLowerCase();

      final String currentUserName = userSub != null
          ? normalizeName(userSub.name, userSub.last_name)
          : 'неизвестный пользователь';

      final String cacheKey = "${_userId}_${_dateKey(widget.date)}";
      final bool cachedAbsent = _absenceCache[cacheKey] ?? false;


      // 4. Формируем список участников:
      // Это люди с абонементом, которых НЕТ в списке очереди (т.е. они не выписались и не ушли в конец)
      // В реальной БД тут может быть доп. флаг "is_absent", но пока фильтруем по отсутствию в очереди
      final members = subscriptions
          .where((s) =>
              s.isPaid &&
              !queue.contains(normalizeName(s.name, s.last_name)) &&
              !(s.user_id == _userId && cachedAbsent))
          .map((s) => Member(
                name: '${s.name} ${s.last_name}',
                isReady: s.is_ready,
              ))
          .toList();

      setState(() {
        _members = members;
        _queue = queue;
        _currentUserName = currentUserName;
        _isUserActive = userSub?.isPaid ?? false;
        String normalizeListEntry(String entry) =>
            entry.trim().replaceAll(RegExp(r"\s+"), " ").toLowerCase();

        final normalizedCurrent = currentUserName.trim().replaceAll(RegExp(r"\s+"), " ");

        _isUserInQueue = queue
            .map(normalizeListEntry)
            .contains(normalizedCurrent);
        _isUserInMembers = members
            .map((m) => normalizeListEntry(m.name))
            .contains(normalizedCurrent);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Ошибка загрузки: $e");
      setState(() => _isLoading = false);
    }
  }

  String _dateKey(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<void> _loadAbsentCache() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? [];
    _absenceCache.clear();
    for (final key in stored) {
      _absenceCache[key] = true;
    }
  }

  Future<void> _saveAbsentCache() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _absenceCache.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    await prefs.setStringList(_prefsKey, stored);
  }

  Future<void> _joinTraining() async {
    try {
      final result = await _queueService.joinTraining(_userId, widget.date);
      
      // Удаляем из локальном кэше отсутствие, т.к. пользователь встал в очередь
      final cacheKey = "${_userId}_${_dateKey(widget.date)}";
      _absenceCache.remove(cacheKey);
      await _saveAbsentCache();

      String message = result["status"] == "player" 
          ? "Вы добавлены в список участников" 
          : "Вы встали в очередь";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  Future<void> _leaveTraining() async {
    try {
      // Метод должен либо удалять запись, либо добавлять в список "отсутствующих"
      await _queueService.leaveTraining(_userId, widget.date);

      final cacheKey = "${_userId}_${_dateKey(widget.date)}";
      _absenceCache[cacheKey] = true;
      await _saveAbsentCache();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Вы выписаны из списка на эту дату")),
      );
      setState(() {
        _isUserInMembers = false;
        _isUserInQueue = false;
      });
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${widget.type} — ${widget.date.day}.${widget.date.month}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff2c5364), Color(0xff203e43), Color(0xff0f2027)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ШАПКА УЧАСТНИКОВ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Участники (${_members.length}/15)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/teams'),
                            child: const Text(
                              'Команды',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView(
                          children: [
                            /// СПИСОК УЧАСТНИКОВ (Абонементщики по умолчанию)
                            ..._members.map((m) => _buildPersonTile(
                                  m.name,
                                  Icons.check_circle,
                                  Colors.greenAccent,
                                  isCurrentUser: m.name.trim().toLowerCase() == _currentUserName,
                                )),


                            const SizedBox(height: 24),

                            /// ОЧЕРЕДЬ
                            if (_queue.isNotEmpty) ...[
                              const Text(
                                'Очередь:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._queue.asMap().entries.map((entry) {
                                final entryName = entry.value.trim().toLowerCase();
                                return _buildPersonTile(
                                  "${entry.key + 1}. ${entry.value}",
                                  Icons.hourglass_empty,
                                  Colors.orangeAccent,
                                  isCurrentUser: entryName == _currentUserName,
                                );
                              }),
                            ],
                          ],
                        ),
                      ),

                      /// ДИНАМИЧЕСКИЕ КНОПКИ ДЛЯ АБОНЕМЕНТЩИКА
                      if (_isUserActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            children: [
                              // 1. Если в основном списке -> Кнопка "Не смогу прийти"
                              if (_isUserInMembers)
                                _buildActionButton(
                                  "Не смогу прийти",
                                  Colors.redAccent,
                                  _leaveTraining,
                                )
                              // 2. Если вычеркнут и не в очереди -> Кнопка "Встать в очередь"
                              else if (!_isUserInQueue)
                                _buildActionButton(
                                  "Встать в очередь",
                                  Colors.white,
                                  _joinTraining,
                                  textColor: Colors.black,
                                )
                              // 3. Если уже в очереди -> Кнопка "Выйти из очереди"
                              else if (_isUserInQueue)
                                _buildActionButton(
                                  "Выйти из очереди",
                                  Colors.orange,
                                  _leaveTraining,
                                ),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Вспомогательный виджет для плитки игрока
  Widget _buildPersonTile(String name, IconData icon, Color iconColor, {bool isCurrentUser = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrentUser ? Colors.blueAccent : Colors.white24, width: isCurrentUser ? 2 : 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Text(
            name, 
            style: TextStyle(
              color: Colors.white, 
              fontSize: 16,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isCurrentUser) ...[
            const Spacer(),
            const Icon(Icons.person, color: Colors.blueAccent),
          ],
        ],
      ),
    );
  }

  /// Вспомогательный виджет для кнопки
  Widget _buildActionButton(String text, Color color, VoidCallback onPressed, {Color textColor = Colors.white}) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}