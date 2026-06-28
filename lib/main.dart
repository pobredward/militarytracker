import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/database/local_storage.dart';
import 'services/notification_service.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/community/presentation/community_screen.dart';
import 'features/workout/presentation/workout_screen.dart';
import 'features/ranking/presentation/ranking_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 (중복 초기화 방지)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Firebase가 이미 초기화된 경우 무시
    debugPrint('Firebase initialization: $e');
  }
  
  // Local Storage 초기화
  await LocalStorage.init();
  
  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);
  
  // 알림 서비스 초기화 (실패해도 앱은 계속 실행)
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }
  
  runApp(
    const ProviderScope(
      child: MilitaryTrackerApp(),
    ),
  );
}

class MilitaryTrackerApp extends ConsumerWidget {
  const MilitaryTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '밀리터리트래커',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          brightness: Brightness.dark,
          primary: const Color(0xFF00C853),
          secondary: const Color(0xFF69F0AE),
          surface: const Color(0xFF1A1A1A),
          background: const Color(0xFF121212),
          error: const Color(0xFFCF6679),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF2A2A2A),
              width: 1,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0E0E0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00C853), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCF6679)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          hintStyle: const TextStyle(color: Color(0xFF616161)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE0E0E0),
            side: const BorderSide(color: Color(0xFF2A2A2A)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00C853),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2A2A2A),
          thickness: 1,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          indicatorColor: const Color(0xFF00C853).withOpacity(0.15),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00C853),
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9E9E9E),
            );
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Color(0xFF00C853));
            }
            return const IconThemeData(color: Color(0xFF9E9E9E));
          }),
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 인증 가드: 로그인 상태에 따라 화면 전환
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        debugPrint('AuthGate - User: ${user?.uid ?? "null"}');
        if (user == null) {
          // 로그인되지 않은 경우 로그인 화면 표시
          return const LoginScreen();
        }
        // 로그인된 경우 메인 화면 표시
        return const MainScreen();
      },
      loading: () {
        debugPrint('AuthGate - Loading...');
        return const Scaffold(
          backgroundColor: Color(0xFF121212),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF00C853),
                ),
                SizedBox(height: 16),
                Text(
                  '로딩 중...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        debugPrint('AuthGate - Error: $error');
        debugPrint('StackTrace: $stackTrace');
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '오류가 발생했습니다:\n$error',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // 앱 재시작 (로그인 화면으로)
                    ref.invalidate(authStateProvider);
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  final List<Widget> _screens = const [
    HomeScreen(),
    CommunityScreen(),
    WorkoutScreen(),
    RankingScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 앱 생명주기 옵저버 등록
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 앱 생명주기 옵저버 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 앱이 백그라운드/포그라운드 전환 시 로깅
    debugPrint('App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // 포그라운드로 복귀 - 만보기는 자동으로 계속 추적
        debugPrint('App resumed - Pedometer continues tracking in background');
        break;
      case AppLifecycleState.inactive:
        // 비활성 상태 (전화 수신 등)
        debugPrint('App inactive');
        break;
      case AppLifecycleState.paused:
        // 백그라운드로 전환 - 만보기는 계속 추적
        debugPrint('App paused - Pedometer continues tracking in background');
        break;
      case AppLifecycleState.detached:
        // 앱 종료 직전
        debugPrint('App detached');
        break;
      case AppLifecycleState.hidden:
        // 앱이 숨겨짐 (iOS 13+)
        debugPrint('App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);
    
    return Scaffold(
      body: _screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '커뮤니티',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: '운동',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: '랭킹',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
