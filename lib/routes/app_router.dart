import 'package:field_survey_nifaa/screens/survey_page.dart';
import 'package:field_survey_nifaa/screens/splash_screen.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/dashboard/dashboard_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/profile/edit_profile_page.dart';

class AppRouter {
  // =========================
  // ROUTES
  // =========================
  static const String splash = '/splash';
  static const String login = '/';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String survey = '/survey';
}

final GoRouter appRouter = GoRouter(
  // =========================
  // SPLASH JADI HALAMAN PERTAMA
  // =========================
  initialLocation: AppRouter.splash,

  routes: [
    // =========================
    // SPLASH
    // =========================
    GoRoute(
      path: AppRouter.splash,
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    // =========================
    // LOGIN
    // =========================
    GoRoute(
      path: AppRouter.login,
      builder: (context, state) {
        return const LoginPage();
      },
    ),

    // =========================
    // REGISTER
    // =========================
    GoRoute(
      path: AppRouter.register,
      builder: (context, state) {
        return const RegisterPage();
      },
    ),

    // =========================
    // DASHBOARD
    // =========================
    GoRoute(
      path: AppRouter.dashboard,
      builder: (context, state) {
        return const DashboardPage();
      },
    ),

    // =========================
    // PROFILE
    // =========================
    GoRoute(
      path: AppRouter.profile,
      builder: (context, state) {
        return const ProfilePage();
      },
    ),

    // =========================
    // SURVEY
    // =========================
    GoRoute(
      path: AppRouter.survey,
      builder: (context, state) {
        return const SurveyPage();
      },
    ),

    // =========================
    // EDIT PROFILE
    // =========================
    GoRoute(
      path: AppRouter.editProfile,
      builder: (context, state) {
        final profile = state.extra as Map<String, dynamic>?;

        return EditProfilePage(
          profile: profile,
        );
      },
    ),
  ],
);