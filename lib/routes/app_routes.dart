import '../features/start/start_view.dart';
import '../features/auth/views/sign_in_view.dart';
import '../features/auth/views/sign_up_view.dart';
import '../features/home/home_view.dart';
import '../features/profile/profile_view.dart';

class AppRoutes {
  static const start = '/';
  static const signIn = '/signin';
  static const signUp = '/signup';
  static const home = '/home';
  static const profile = '/profile';

  static final routes = {
    start: (context) => StartView(),
    signIn: (context) => SignInView(),
    signUp: (context) => SignUpView(),
    home: (context) => HomeView(),
    profile: (context) => ProfileView(),
  };
}