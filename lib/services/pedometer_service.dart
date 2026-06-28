import 'dart:async';
import 'dart:io';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/logger.dart';
import '../providers/workout_provider.dart';

/// 만보기 서비스 - 하루 자동 누적 (00:00~23:59)
class PedometerService {
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  Timer? _midnightCheckTimer;

  final _stepCountController = StreamController<int>.broadcast();
  Stream<int> get stepCountStream => _stepCountController.stream;

  int _todayInitialSteps = 0;  // 오늘 00시 시점의 걸음 수
  int _currentSteps = 0;  // 현재 총 걸음 수
  bool _isTracking = false;
  String _currentDate = '';  // YYYY-MM-DD 형식

  // Riverpod Ref (Firebase 저장용)
  Ref? _ref;

  // SharedPreferences 키
  static const String _keyIsTracking = 'pedometer_is_tracking';
  static const String _keyTodayInitialSteps = 'pedometer_today_initial_steps';
  static const String _keyCurrentDate = 'pedometer_current_date';
  static const String _keyLastSavedSteps = 'pedometer_last_saved_steps';  // Firebase 저장용

  bool get isTracking => _isTracking;
  int get todaySteps => _currentSteps - _todayInitialSteps;  // 오늘 걸은 총 걸음 수
  String get currentDate => _currentDate;

  /// Ref 설정 (Firebase 저장을 위해 필요)
  void setRef(Ref ref) {
    _ref = ref;
  }

  /// 권한 요청
  Future<PermissionStatus> requestPermission() async {
    try {
      // iOS는 CoreMotion을 사용하며 별도 권한 불필요
      // Android만 activityRecognition 권한 필요
      if (Platform.isAndroid) {
        final status = await Permission.activityRecognition.request();
        return status;
      } else {
        // iOS는 자동으로 허용됨
        return PermissionStatus.granted;
      }
    } catch (e) {
      logger.e('Error requesting activity recognition permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// 권한 상태 확인
  Future<PermissionStatus> checkPermission() async {
    try {
      if (Platform.isAndroid) {
        return await Permission.activityRecognition.status;
      } else {
        // iOS는 자동으로 허용됨
        return PermissionStatus.granted;
      }
    } catch (e) {
      logger.e('Error checking activity recognition permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// 오늘 날짜 가져오기 (YYYY-MM-DD)
  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 자정 넘어갔는지 확인하고 리셋
  Future<void> _checkAndResetIfNewDay() async {
    final today = _getTodayDate();
    
    if (_currentDate.isNotEmpty && _currentDate != today) {
      logger.i('New day detected! Previous: $_currentDate, Current: $today');
      
      // 어제 걸음 수 자동 저장 (Firebase)
      await _autoSavePreviousDaySteps();
      
      // 오늘로 리셋
      _todayInitialSteps = _currentSteps;
      _currentDate = today;
      
      await _saveTrackingState();
      _stepCountController.add(0);
      
      logger.i('Reset to new day: $_currentDate, Initial steps: $_todayInitialSteps');
    }
  }

  /// 어제 걸음 수 자동 저장 (Firebase에 저장)
  Future<void> _autoSavePreviousDaySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final yesterdaySteps = prefs.getInt(_keyLastSavedSteps) ?? 0;
      
      if (yesterdaySteps > 0 && _ref != null) {
        logger.i('Auto-saving previous day steps: $yesterdaySteps');
        
        // Firebase에 저장
        final workoutActions = _ref!.read(workoutActionProvider);
        final success = await workoutActions.addWalkSteps(yesterdaySteps);
        
        if (success) {
          logger.i('Previous day steps saved successfully to Firebase');
        } else {
          logger.e('Failed to save previous day steps to Firebase');
        }
      }
      
      // 저장 후 초기화
      await prefs.setInt(_keyLastSavedSteps, 0);
    } catch (e) {
      logger.e('Error auto-saving previous day steps: $e');
    }
  }

  /// 저장된 추적 상태 복원
  Future<void> restoreTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasTracking = prefs.getBool(_keyIsTracking) ?? false;
      
      if (wasTracking) {
        _todayInitialSteps = prefs.getInt(_keyTodayInitialSteps) ?? 0;
        _currentDate = prefs.getString(_keyCurrentDate) ?? _getTodayDate();
        
        // 날짜가 바뀌었는지 확인
        await _checkAndResetIfNewDay();
        
        logger.i('Restored tracking state: date=$_currentDate, initial=$_todayInitialSteps');
        
        // 추적 재개
        final permissionStatus = await checkPermission();
        if (permissionStatus.isGranted) {
          await _subscribeToStreams();
          _isTracking = true;
          
          // 자정 체크 타이머 시작
          _startMidnightCheckTimer();
        } else {
          // 권한이 없으면 저장된 상태 초기화
          await _clearSavedState();
        }
      }
    } catch (e) {
      logger.e('Error restoring tracking state: $e');
    }
  }

  /// 자정 체크 타이머 시작 (1분마다)
  void _startMidnightCheckTimer() {
    _midnightCheckTimer?.cancel();
    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkAndResetIfNewDay();
    });
  }

  /// 추적 상태 저장
  Future<void> _saveTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsTracking, _isTracking);
      await prefs.setInt(_keyTodayInitialSteps, _todayInitialSteps);
      await prefs.setString(_keyCurrentDate, _currentDate);
      await prefs.setInt(_keyLastSavedSteps, todaySteps);  // 현재 걸음 수 저장
      logger.d('Tracking state saved: date=$_currentDate, steps=$todaySteps');
    } catch (e) {
      logger.e('Error saving tracking state: $e');
    }
  }

  /// 저장된 상태 초기화
  Future<void> _clearSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsTracking);
      await prefs.remove(_keyTodayInitialSteps);
      await prefs.remove(_keyCurrentDate);
      await prefs.remove(_keyLastSavedSteps);
      logger.d('Saved state cleared');
    } catch (e) {
      logger.e('Error clearing saved state: $e');
    }
  }

  /// 걸음 수 추적 시작 (권한 상태 반환)
  Future<PermissionStatus> startTracking() async {
    if (_isTracking) {
      logger.w('Pedometer is already tracking');
      return PermissionStatus.granted;
    }

    try {
      // 권한 확인
      final permissionStatus = await requestPermission();
      if (!permissionStatus.isGranted) {
        logger.e('Activity recognition permission denied');
        return permissionStatus;
      }

      // 오늘 날짜 설정
      _currentDate = _getTodayDate();

      // 스트림 구독
      await _subscribeToStreams();

      _isTracking = true;
      
      // 자정 체크 타이머 시작
      _startMidnightCheckTimer();
      
      // 상태 저장
      await _saveTrackingState();
      
      logger.i('Pedometer tracking started for date: $_currentDate');
      return PermissionStatus.granted;
    } catch (e) {
      logger.e('Error starting pedometer: $e');
      return PermissionStatus.denied;
    }
  }

  /// 스트림 구독 (내부 메서드)
  Future<void> _subscribeToStreams() async {
    // 걸음 수 스트림 구독
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: false,
    );

    // 보행자 상태 스트림 구독 (선택적)
    try {
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );
    } catch (e) {
      // 일부 디바이스에서는 pedestrianStatusStream을 지원하지 않을 수 있음
      logger.w('Pedestrian status stream not available: $e');
    }
  }

  /// 걸음 수 추적 중지
  Future<void> stopTracking() async {
    await _stepCountSubscription?.cancel();
    await _pedestrianStatusSubscription?.cancel();
    _midnightCheckTimer?.cancel();
    
    _stepCountSubscription = null;
    _pedestrianStatusSubscription = null;
    _midnightCheckTimer = null;
    _isTracking = false;
    
    // 저장된 상태 초기화
    await _clearSavedState();
    
    logger.i('Pedometer tracking stopped');
  }

  /// 오늘의 걸음 수를 Firebase에 즉시 저장 (수동 저장용)
  Future<void> saveTodaySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastSavedSteps, todaySteps);
      await _saveTrackingState();
      logger.i('Today steps manually saved: $todaySteps');
    } catch (e) {
      logger.e('Error saving today steps: $e');
    }
  }

  /// 걸음 수 업데이트 핸들러
  void _onStepCount(StepCount event) {
    _currentSteps = event.steps;
    
    // 오늘 첫 걸음이면 초기값 설정
    if (_todayInitialSteps == 0) {
      _todayInitialSteps = _currentSteps;
      _saveTrackingState();
    }
    
    final sessionSteps = todaySteps;
    _stepCountController.add(sessionSteps);
    
    // 주기적으로 상태 저장 (1분마다)
    _saveTrackingState();
    
    logger.d('Steps: $sessionSteps (Total: $_currentSteps, Initial: $_todayInitialSteps)');
  }

  /// 걸음 수 에러 핸들러
  void _onStepCountError(error) {
    logger.e('Pedometer error: $error');
    // 에러 발생 시에도 계속 추적
  }

  /// 보행자 상태 업데이트 핸들러
  void _onPedestrianStatus(PedestrianStatus event) {
    final status = event.status;
    logger.d('Pedestrian status: $status');
    // walking, stopped 등의 상태를 UI에 표시할 수 있음
  }

  /// 보행자 상태 에러 핸들러
  void _onPedestrianStatusError(error) {
    logger.e('Pedestrian status error: $error');
  }

  /// 리소스 정리
  void dispose() {
    stopTracking();
    _stepCountController.close();
    _midnightCheckTimer?.cancel();
  }
}

