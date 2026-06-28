import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/workout/presentation/workout_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String community = '/community';
  static const String workout = '/workout';
  static const String profile = '/profile';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: community,
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        path: workout,
        builder: (context, state) => const WorkoutScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('페이지를 찾을 수 없습니다: ${state.uri.path}'),
      ),
    ),
  );
}

