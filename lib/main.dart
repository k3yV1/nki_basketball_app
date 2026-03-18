import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'services/notifications/notifications_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // init timezone
  tz.initializeTimeZones();

  // init notifications
  NotificationsService().initialize();

  // schedule notification for training at 19:00 (1 hour before)
  final now = DateTime.now();
  final trainingTime = DateTime(now.year, now.month, now.day, 19, 0);
  final notifyTime = trainingTime.subtract(const Duration(hours: 1));
  if (now.isBefore(notifyTime)) {
    NotificationsService().scheduleNotification(
      id: 1,
      title: '🏀 Тренировка через час',
      body: 'Тренировка в 19:00. Не забудь подготовиться и взять кроссовки!',
      scheduledTime: notifyTime,
    );
  }

  runApp(NkiBasketballApp());
}

class NkiBasketballApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NKI BASKETBALL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Poppins",
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      initialRoute: AppRoutes.start,
      routes: AppRoutes.routes,
      builder: (context, child) {
        return Container(
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
          child: child,
        );
      },
    );
  }
}
