import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nki_basketball/features/members/members_view.dart';
import 'package:nki_basketball/data/models/member_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  DateTime _nextWeekday(int weekday) {
    final today = DateTime.now();
    final delta = (weekday - today.weekday + 7) % 7;
    return today.add(Duration(days: delta));
  }

  List<DateTime> _highlightedDays() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final end = now.add(const Duration(days: 30));
    final days = <DateTime>[];
    for (var d = start; d.isBefore(end); d = d.add(const Duration(days: 1))) {
      if ([DateTime.monday, DateTime.wednesday, DateTime.friday].contains(d.weekday)) {
        days.add(d);
      }
    }
    return days;
  }

  void _navigateToMembersView(BuildContext context, DateTime date, String type) {
    final members = [
      Member(name: 'Алексей', isPresent: true),
      Member(name: 'Дмитрий', isPresent: false),
      Member(name: 'Сергей', isPresent: true),
    ];

    final queue = ['Пётр', 'Николай', 'Игорь'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembersView(
          date: date,
          type: type,
          members: members,
          queue: queue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = _highlightedDays();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) {
              final userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

              final String name = userData?['name'] ?? 'Иван';
              final String lastName = userData?['last_name'] ?? 'Иванов';

              return GestureDetector(
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
                    const CircleAvatar(
                      backgroundImage: AssetImage('assets/avatar.png'),
                      radius: 18,
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              );
            },
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
                onTap: () => _navigateToMembersView(context, date, type),
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
                      Text(
                        '$weekdayStr – ${date.day}.${date.month}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
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
                rowHeight: 43,
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
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: Colors.white),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                ),
                focusedDay: DateTime.now(),
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
