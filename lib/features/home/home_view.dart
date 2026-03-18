import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nki_basketball/features/members/members_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  DateTime _nextWeekday(int weekday) {
    final today = DateTime.now();
    final delta = (weekday - today.weekday + 7) % 7;
    return today.add(Duration(days: delta));
  }

  void _navigateToMembersView(
      BuildContext context, DateTime date, String type, Map<String, dynamic>? userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembersView(
          date: date,
          type: type,
        ),
        settings: RouteSettings(arguments: userData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String name = userData?['name'] ?? 'Unknown';
    final String lastName = userData?['last_name'] ?? 'Unknown';
    final String avatarUrl = userData?['avatar_url'] ??
        'https://api.dicebear.com/7.x/bottts/png?seed=$name+$lastName';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile', arguments: userData);
            },
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$name $lastName',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '🏅 x3',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                    avatarUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                      backgroundImage: AssetImage('assets/avatar.png'),
                      radius: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            const SizedBox(height: kToolbarHeight + 50),
            Column(
              children: [1, 3, 5].map((wday) {
                final date = _nextWeekday(wday);
                final weekdayStr = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][wday - 1];
                final type = wday == 5 ? 'Игра' : 'Тренировка';
                return InkWell(
                  onTap: () => _navigateToMembersView(context, date, type, userData),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const Text(
                              '19:00',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: type == 'Игра' ? Colors.blue : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: TableCalendar(
                locale: "en_US",
                rowHeight: 35,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                  titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.white),
                  weekendStyle: TextStyle(color: Colors.white),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: const TextStyle(color: Colors.white),
                  outsideTextStyle: const TextStyle(color: Colors.white38),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                ),
                calendarBuilders: CalendarBuilders(
                  todayBuilder: (context, day, focusedDay) {
                    final isWorkoutDay = day.weekday == 1 || day.weekday == 3;
                    final isGameDay = day.weekday == 5;
                    final backgroundColor = isWorkoutDay ? Colors.greenAccent : (isGameDay ? Colors.blueAccent : Colors.white);
                    final textColor = isWorkoutDay || isGameDay ? Colors.white : Colors.black;
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    final isWorkoutDay = day.weekday == 1 || day.weekday == 3;
                    final isGameDay = day.weekday == 5;
                    if (isGameDay && day.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    } else if (isWorkoutDay && day.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                focusedDay: DateTime.now(),
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
            ),
        )],
        ),
      ),
    );
  }
}
