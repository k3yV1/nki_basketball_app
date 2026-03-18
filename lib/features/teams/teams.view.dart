import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:nki_basketball/services/subscriptions/subscriptions_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerInfo {
  final String name;
  final String lastName;

  PlayerInfo({required this.name, required this.lastName});

  String get fullName => '$name $lastName';

  Map<String, dynamic> toJson() => {
    'name': name,
    'lastName': lastName,
  };

  factory PlayerInfo.fromJson(Map<String, dynamic> json) => PlayerInfo(
    name: json['name'] as String,
    lastName: json['lastName'] as String,
  );
}

class TeamsView extends StatefulWidget {
  const TeamsView({Key? key}) : super(key: key);

  @override
  State<TeamsView> createState() => _TeamsViewState();
}

class _TeamsViewState extends State<TeamsView> {
  final _subscriptionsService = SubscriptionsService();
  
  int _userId = 0;

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  void initState() {
    super.initState();
  }
  
  Future<String> _getCurrentUserName() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final routeName = (args?['name']?.toString() ?? '').trim();
    final routeLastName = (args?['last_name']?.toString() ?? '').trim();
    if (routeName.isNotEmpty || routeLastName.isNotEmpty) {
      return _normalizeName('$routeName $routeLastName');
    }

    if (_userId == 0) {
      _userId = int.tryParse(args?['id']?.toString() ?? '0') ?? 0;
    }
    
    try {
      final subscriptions = await _subscriptionsService.fetchSubscriptions();
      for (var sub in subscriptions) {
        if (sub.user_id == _userId) {
          return _normalizeName('${sub.name} ${sub.last_name}');
        }
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return '';
  }

  Future<Map<String, dynamic>> _loadTeamsWithUserName() async {
    final teams = await _loadAndGenerateTeams();
    final currentUserName = await _getCurrentUserName();
    return {
      'teams': teams,
      'currentUserName': currentUserName,
    };
  }

  String _getTrainingDateKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  bool _isTrainingDay() {
    final today = DateTime.now();
    // Дни тренировок: 1 (Пн), 3 (Ср), 5 (Пт)
    return today.weekday == 1 || today.weekday == 3 || today.weekday == 5;
  }

  Future<List<List<PlayerInfo>>> _loadAndGenerateTeams() async {
    if (!_isTrainingDay()) {
      return [];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _getTrainingDateKey();
      final cacheKey = 'teams_$dateKey';

      // Проверяем, есть ли уже составленные команды на этот день
      final cachedTeams = prefs.getString(cacheKey);
      if (cachedTeams != null && cachedTeams.isNotEmpty) {
        print('Загружены сохраненные команды для $dateKey');
        return _decodeTeams(cachedTeams);
      }

      // Если команды не существуют, составляем новые
      final subscriptions = await _subscriptionsService.fetchSubscriptions();
      final activePlayers = subscriptions
          .where((sub) => sub.isPaid)
          .map((sub) => PlayerInfo(name: sub.name, lastName: sub.last_name))
          .toList();

      if (activePlayers.isEmpty) {
        return [];
      }

      // Перемешиваем игроков
      activePlayers.shuffle(Random());

      // Распределяем на команды
      final teams = _distributeTeams(activePlayers);

      // Сохраняем команды на этот день
      await prefs.setString(cacheKey, _encodeTeams(teams));
      print('Команды составлены и сохранены для $dateKey');

      return teams;
    } catch (e) {
      print('Error loading teams: $e');
      return [];
    }
  }

  String _encodeTeams(List<List<PlayerInfo>> teams) {
    final teamsJson = teams
        .map((team) => team.map((player) => player.toJson()).toList())
        .toList();
    return jsonEncode(teamsJson);
  }

  List<List<PlayerInfo>> _decodeTeams(String teamsJson) {
    final List<dynamic> teamsData = jsonDecode(teamsJson);
    return teamsData
        .map((teamData) => (teamData as List<dynamic>)
            .map((playerData) => PlayerInfo.fromJson(playerData as Map<String, dynamic>))
            .toList())
        .toList();
  }

  List<List<PlayerInfo>> _distributeTeams(List<PlayerInfo> players) {
    final playerCount = players.length;
    final teams = <List<PlayerInfo>>[];

    if (playerCount < 2) {
      return [players];
    }

    // Логика распределения в зависимости от количества игроков
    if (playerCount <= 6) {
      // 2 команды
      final teamSize = playerCount ~/ 2;
      teams.add(players.sublist(0, teamSize));
      teams.add(players.sublist(teamSize));
    } else if (playerCount <= 12) {
      // 2 команды более равномерно
      final teamSize = (playerCount / 2).ceil();
      teams.add(players.sublist(0, teamSize));
      teams.add(players.sublist(teamSize));
    } else {
      // 3 и более команд
      final teamsCount = (playerCount / 5).ceil();
      final baseTeamSize = playerCount ~/ teamsCount;
      final remainder = playerCount % teamsCount;

      int startIndex = 0;
      for (int i = 0; i < teamsCount; i++) {
        final size = baseTeamSize + (i < remainder ? 1 : 0);
        teams.add(players.sublist(startIndex, startIndex + size));
        startIndex += size;
      }
    }

    return teams;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Команды', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
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
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _loadTeamsWithUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Ошибка при загрузке команд',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              final teams = data['teams'] as List<List<PlayerInfo>>? ?? [];
              final currentUserName = data['currentUserName'] as String? ?? '';

              if (!_isTrainingDay()) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white54, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Сегодня не день тренировки',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Тренировки: пн, ср, пт в 19:00',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              if (teams.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.group, color: Colors.white54, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Нет участников с активными абонементами',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 20, left: 16, right: 16),
                children: List.generate(teams.length, (index) {
                  final team = teams[index];
                  final colors = [
                    Colors.red.shade400,
                    Colors.blue.shade400,
                    Colors.orange.shade400,
                    Colors.green.shade400,
                  ];
                  final teamColor = colors[index % colors.length];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: teamColor.withOpacity(0.5), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: teamColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Команда ${index + 1}',
                              style: TextStyle(
                                color: teamColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${team.length})',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: team.asMap().entries.map((entry) {
                            final player = entry.value;
                            final playerFullName = _normalizeName(player.fullName);
                            final isCurrentUser = playerFullName == currentUserName;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white12,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${entry.key + 1}.',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.person, color: Colors.white70, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      player.fullName,
                                      style: TextStyle(
                                        color: isCurrentUser ? Colors.blueAccent : Colors.white,
                                        fontSize: 16,
                                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
