import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nki_basketball/data/models/member_model.dart';
import 'package:nki_basketball/services/subscriptions/subscriptions_service.dart';
import 'package:nki_basketball/services/queue/queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MembersView extends StatefulWidget {
  final DateTime date;
  final String type;

  const MembersView({Key? key, required this.date, required this.type})
    : super(key: key);

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  static final Map<String, bool> _absenceCache =
      {}; // persist within app session (short-living)
  static const _prefsKey = 'absent_trainings';

  final _subscriptionsService = SubscriptionsService();
  final _queueService = QueueService();

  List<Member> _members = [];
  List<QueueEntry> _queue = [];
  bool _isLoading = true;
  bool _isFetching = false;
  Timer? _pollTimer;
  static const Duration _pollInterval = Duration(seconds: 8);

  late int _userId;
  String _currentUserName = '';

  bool _isUserInQueue = false; // В очереди ли сейчас
  bool _isUserInMembers = false; // В основном ли списке (абонементщик)
  bool _confirmedAsParticipant =
      false; // Бэкенд подтвердил участие (training_participants)

  @override
  void initState() {
    super.initState();
    print('queue list: ${_queueService.getQueue(widget.date)}');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _userId =
          int.tryParse((args?['id'] ?? args?['user_id'] ?? '0').toString()) ??
          0;
      await _loadAbsentCache();
      await _fetchData();
      _startPolling();
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      _fetchData();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      // 1. Загружаем всё параллельно
      final results = await Future.wait([
        _subscriptionsService.fetchSubscriptions(),
        _queueService.getQueue(widget.date),
        _queueService.getParticipants(widget.date),
      ]);

      final subscriptions = results[0] as List;
      final queue = (results[1] as List).cast<QueueEntry>();
      final participants = (results[2] as List).cast<QueueEntry>();

      // 2. Данные текущего пользователя из маршрута
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final String routeName = args?['name']?.toString() ?? '';
      final String routeLastName = args?['last_name']?.toString() ?? '';

      String normalizeName(String name, String lastName) =>
          '${name.trim()} ${lastName.trim()}'.trim().toLowerCase();
      String normalizeEntry(String entry) =>
          entry.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

      final matchingSubs = (subscriptions as dynamic).where(
        (s) => s.user_id == _userId,
      );
      final userSub = (matchingSubs as Iterable).isNotEmpty
          ? matchingSubs.first
          : null;

      final String routeUserName = normalizeName(routeName, routeLastName);
      final String currentUserName = routeUserName.isNotEmpty
          ? routeUserName
          : (userSub != null
                ? normalizeName(userSub.name, userSub.last_name)
                : '');

      debugPrint(
        '[MembersView] _fetchData: userId=$_userId currentUserName="$currentUserName"',
      );
      debugPrint(
        '[MembersView] queue(${queue.length}): ${queue.map((e) => '{id:${e.userId}, name:${e.fullName}}').toList()}',
      );
      debugPrint(
        '[MembersView] participants(${participants.length}): ${participants.map((e) => '{id:${e.userId}, name:${e.fullName}}').toList()}',
      );

      final String cacheKey = '${_userId}_${_dateKey(widget.date)}';
      final bool cachedAbsent = _absenceCache[cacheKey] ?? false;

      final queueIds = queue.map((e) => e.userId).toSet();
      final queueNames = queue.map((e) => normalizeEntry(e.fullName)).toSet();
      final participantIds = participants.map((e) => e.userId).toSet();
      final participantNames = participants
          .map((e) => normalizeEntry(e.fullName))
          .toSet();

      // 3. Формируем список участников:
      //    а) фактические участники из training_participants (включая безабонементных)
      //    б) абонементщики, которые не в очереди и не отсутствуют
      // Исключаем дубли по userId / нормализованному имени.
      final seenIds = <int>{};
      final seenNames = <String>{};
      final members = <Member>[];

      // а) Реальные участники (training_participants)
      for (final p in participants) {
        final name = normalizeEntry(p.fullName);
        if ((p.userId != 0 && seenIds.contains(p.userId)) ||
            seenNames.contains(name))
          continue;
        if (p.userId != 0) seenIds.add(p.userId);
        seenNames.add(name);
        members.add(Member(name: p.fullName, isReady: false));
      }

      // б) Абонементщики по умолчанию (не в очереди, не отсутствуют, ещё не добавлены)
      for (final s in (subscriptions as Iterable)) {
        if (!s.isPaid) continue;
        if (s.user_id == _userId && cachedAbsent) continue;
        final fullName = '${s.name} ${s.last_name}';
        final name = normalizeEntry(fullName);
        if (queueIds.contains(s.user_id) || queueNames.contains(name)) {
          continue;
        }
        if (participantIds.contains(s.user_id) ||
            participantNames.contains(name)) {
          continue; // уже добавлен через участников
        }
        if ((s.user_id != 0 && seenIds.contains(s.user_id)) ||
            seenNames.contains(name))
          continue;
        if (s.user_id != 0) seenIds.add(s.user_id as int);
        seenNames.add(name);
        members.add(Member(name: fullName, isReady: s.is_ready));
      }

      setState(() {
        _members = members;
        _queue = queue;
        _currentUserName = currentUserName;

        final normalizedCurrent = normalizeEntry(currentUserName);

        final inQueueById = _userId != 0 && queueIds.contains(_userId);
        final inQueueByName = queueNames.contains(normalizedCurrent);
        _isUserInQueue = inQueueById || inQueueByName;

        final inMembersById = _userId != 0 && participantIds.contains(_userId);
        final inMembersByName =
            participantNames.contains(normalizedCurrent) ||
            members.any((m) => normalizeEntry(m.name) == normalizedCurrent);
        _isUserInMembers = inMembersById || inMembersByName;

        // Если бэкенд ранее подтвердил участие, но /participants ещё не вернул
        // пользователя (endpoint не реализован) — добавляем вручную.
        if (_confirmedAsParticipant &&
            !_isUserInMembers &&
            !_isUserInQueue &&
            currentUserName.isNotEmpty) {
          _isUserInMembers = true;
          final nameNorm = normalizeEntry(currentUserName);
          if (!members.any((m) => normalizeEntry(m.name) == nameNorm)) {
            members.add(Member(name: currentUserName, isReady: false));
            _members = List.of(members);
          }
        }

        debugPrint(
          '[MembersView] result: inQueue=$_isUserInQueue inMembers=$_isUserInMembers members=${_members.length} queue=${_queue.length}',
        );

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки: $e');
      setState(() => _isLoading = false);
    } finally {
      _isFetching = false;
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
      if (_userId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Не удалось определить пользователя")),
        );
        return;
      }

      final result = await _queueService.joinTraining(_userId, widget.date);

      // Удаляем из локальном кэше отсутствие, т.к. пользователь встал в очередь
      final cacheKey = "${_userId}_${_dateKey(widget.date)}";
      _absenceCache.remove(cacheKey);
      await _saveAbsentCache();

      String message = result["status"] == "player"
          ? "Вы добавлены в список участников"
          : result["status"] == "already_joined"
          ? "Вы уже записаны. Обновили ваш статус"
          : "Вы встали в очередь";

      setState(() {
        final status = (result['status'] ?? '').toString().toLowerCase();
        final isPlayer = status == 'player';
        final isAlreadyJoined = status == 'already_joined';

        if (isPlayer || isAlreadyJoined) {
          // Списки участников/очереди синхронизируем только через _fetchData.
          _confirmedAsParticipant = true;
          _isUserInMembers = true;
          _isUserInQueue = false;
        } else {
          // Списки участников/очереди синхронизируем только через _fetchData.
          _confirmedAsParticipant = false;
          _isUserInQueue = true;
          _isUserInMembers = false;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
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
        _confirmedAsParticipant = false;
      });
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${widget.type} — ${widget.date.day.toString().padLeft(2, '0')}.${widget.date.month.toString().padLeft(2, '0')}.${widget.date.year}',
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
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            onPressed: () =>
                                Navigator.pushNamed(context, '/teams'),
                            child: const Text(
                              'Команды',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: [
                            ..._members.map(
                              (m) => _buildPersonTile(
                                m.name,
                                Icons.check_circle,
                                Colors.greenAccent,
                                isCurrentUser:
                                    m.name
                                        .trim()
                                        .replaceAll(RegExp(r"\s+"), " ")
                                        .toLowerCase() ==
                                    _currentUserName
                                        .trim()
                                        .replaceAll(RegExp(r"\s+"), " ")
                                        .toLowerCase(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Очередь:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_queue.isEmpty)
                              const Text(
                                'Пока пусто',
                                style: TextStyle(color: Colors.white70),
                              )
                            else
                              ..._queue.asMap().entries.map((entry) {
                                final entryName = entry.value.fullName
                                    .trim()
                                    .replaceAll(RegExp(r"\s+"), " ")
                                    .toLowerCase();
                                return _buildPersonTile(
                                  '${entry.key + 1}. ${entry.value.fullName}',
                                  Icons.hourglass_empty,
                                  Colors.orangeAccent,
                                  isCurrentUser:
                                      entry.value.userId == _userId ||
                                      entryName ==
                                          _currentUserName
                                              .trim()
                                              .replaceAll(RegExp(r"\s+"), " ")
                                              .toLowerCase(),
                                );
                              }),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            if (_isUserInMembers)
                              _buildActionButton(
                                'Не смогу прийти',
                                Colors.redAccent,
                                _leaveTraining,
                              )
                            else if (!_isUserInQueue)
                              _buildActionButton(
                                'Записаться на тренировку',
                                Colors.white,
                                _joinTraining,
                                textColor: Colors.black,
                              )
                            else if (_isUserInQueue)
                              _buildActionButton(
                                'Выйти из очереди',
                                Colors.orange,
                                _leaveTraining,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Вспомогательный виджет для плитки игрока
  Widget _buildPersonTile(
    String name,
    IconData icon,
    Color iconColor, {
    bool isCurrentUser = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.blue.withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? Colors.blueAccent : Colors.white24,
          width: isCurrentUser ? 2 : 1,
        ),
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
  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    Color textColor = Colors.white,
  }) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
