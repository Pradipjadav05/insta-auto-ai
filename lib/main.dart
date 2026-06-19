import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/theme.dart';
import 'core/widgets/sidebar_layout.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/generator/presentation/generator_screen.dart';
import 'features/calendar/presentation/calendar_screen.dart';
import 'features/scheduler/presentation/scheduler_screen.dart';
import 'features/instagram/presentation/instagram_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initializer fallback for local preview testing
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization info: Running with client mocks. (Error: $e)");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'InstaAuto AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _buildHomeRoute(authState, ref),
    );
  }

  Widget _buildHomeRoute(AuthState state, WidgetRef ref) {
    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.neonPurple,
          ),
        ),
      );
    }

    if (state.isAuthenticated) {
      return SidebarLayout(
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
        screens: const [
          DashboardScreen(),
          GeneratorScreen(),
          CalendarScreen(),
          SchedulerScreen(),
          InstagramScreen(),
        ],
      );
    }

    // Default route
    return const LoginScreen();
  }
}
