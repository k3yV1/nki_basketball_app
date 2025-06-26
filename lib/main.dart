import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'services/notifications/notifications_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // init notifications
  NotificationsService().initialize();

  Future.delayed(Duration(seconds: 5), () {
    NotificationsService().showNotification(
      id: 0,
      title: '🏀 Тренировка сегодня',
      body: 'Не забудь подготовиться и взять кроссовки!',
    );
  });

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
