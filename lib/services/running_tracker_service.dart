import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/logger.dart';

/// 러닝 추적 서비스 - GPS 기반 거리 측정 (하루 누적 지원)
class RunningTrackerService {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _midnightCheckTimer;
  
  final _distanceController = StreamController<double>.broadcast();
  final _speedController = StreamController<double>.broadcast();
  
  Stream<double> get distanceStream => _distanceController.stream;
  Stream<double> get speedStream => _speedController.stream;

  Position? _lastPosition;
  double _todayTotalDistance = 0.0; // 오늘 총 누적 거리 (km)
  double _sessionDistance = 0.0; // 현재 세션 거리 (km)
  bool _isTracking = false;
  DateTime? _sessionStartTime;
  String _currentDate = '';  // YYYY-MM-DD 형식

  // 속도 제한 (차량 이동 필터링)
  static const double MAX_RUNNING_SPEED_KMH = 25.0;  // 25km/h 이상은 차량으로 간주
  static const double MAX_INSTANT_DISTANCE_KM = 0.1;  // 한 번에 100m 이상 이동 무시

  // SharedPreferences 키
  static const String _keyIsTracking = 'running_is_tracking';
  static const String _keyTodayTotalDistance = 'running_today_total_distance';
  static const String _keyCurrentDate = 'running_current_date';
  static const String _keySessionDistance = 'running_session_distance';
  static const String _keySessionStartTime = 'running_session_start_time';

  bool get isTracking => _isTracking;
  double get sessionDistance => _sessionDistance;  // 현재 세션만
  double get todayTotalDistance => _todayTotalDistance;  // 오늘 총 누적
  Duration get elapsedTime => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!) 
      : Duration.zero;
  String get currentDate => _currentDate;

  /// 위치 권한 요청
  Future<PermissionStatus> requestPermission() async {
    try {
      // 먼저 Geolocator로 직접 권한 요청 (iOS/Android 모두 호환)
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        logger.e('Location permission denied forever');
        return PermissionStatus.permanentlyDenied;
      }
      
      if (permission == LocationPermission.denied) {
        logger.e('Location permission denied');
        return PermissionStatus.denied;
      }

      // 위치 서비스 활성화 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.e('Location services are disabled');
        return PermissionStatus.denied;
      }

      logger.i('Location permission granted: $permission');
      return PermissionStatus.granted;
    } catch (e) {
      logger.e('Error requesting location permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// 위치 권한 상태 확인
  Future<PermissionStatus> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      
      switch (permission) {
        case LocationPermission.denied:
          return PermissionStatus.denied;
        case LocationPermission.deniedForever:
          return PermissionStatus.permanentlyDenied;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return PermissionStatus.granted;
        default:
          return PermissionStatus.denied;
      }
    } catch (e) {
      logger.e('Error checking location permission: $e');
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
      logger.i('New day detected for running! Previous: $_currentDate, Current: $today');
      
      // 어제 거리 자동 저장 (Firebase)
      await _autoSavePreviousDayDistance();
      
      // 오늘로 리셋
      _todayTotalDistance = 0.0;
      _currentDate = today;
      
      await _saveTrackingState();
      _distanceController.add(0.0);
      
      logger.i('Reset to new day: $_currentDate');
    }
  }

  /// 어제 거리 자동 저장 (Firebase에 저장)
  Future<void> _autoSavePreviousDayDistance() async {
    try {
      if (_todayTotalDistance > 0) {
        logger.i('Auto-saving previous day distance: ${_todayTotalDistance.toStringAsFixed(2)} km');
        // TODO: Firebase 저장 로직 호출
        // await workoutRepository.saveDailyRunning(date: _currentDate, distance: _todayTotalDistance);
      }
    } catch (e) {
      logger.e('Error auto-saving previous day distance: $e');
    }
  }

  /// 저장된 추적 상태 복원
  Future<void> restoreTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasTracking = prefs.getBool(_keyIsTracking) ?? false;
      
      if (wasTracking) {
        _todayTotalDistance = prefs.getDouble(_keyTodayTotalDistance) ?? 0.0;
        _sessionDistance = prefs.getDouble(_keySessionDistance) ?? 0.0;
        _currentDate = prefs.getString(_keyCurrentDate) ?? _getTodayDate();
        
        final startTimeMillis = prefs.getInt(_keySessionStartTime);
        if (startTimeMillis != null) {
          _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        }
        
        // 날짜가 바뀌었는지 확인
        await _checkAndResetIfNewDay();
        
        logger.i('Restored running state: date=$_currentDate, today=$_todayTotalDistance km, session=$_sessionDistance km');
        
        // 추적 재개
        final permissionStatus = await checkPermission();
        if (permissionStatus.isGranted) {
          await _resumeTracking();
          _isTracking = true;
          
          // 자정 체크 타이머 시작
          _startMidnightCheckTimer();
        } else {
          await _clearSavedState();
        }
      }
    } catch (e) {
      logger.e('Error restoring running state: $e');
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
      await prefs.setDouble(_keyTodayTotalDistance, _todayTotalDistance);
      await prefs.setDouble(_keySessionDistance, _sessionDistance);
      await prefs.setString(_keyCurrentDate, _currentDate);
      if (_sessionStartTime != null) {
        await prefs.setInt(_keySessionStartTime, _sessionStartTime!.millisecondsSinceEpoch);
      }
      logger.d('Running state saved: today=${_todayTotalDistance.toStringAsFixed(2)} km, session=${_sessionDistance.toStringAsFixed(2)} km');
    } catch (e) {
      logger.e('Error saving running state: $e');
    }
  }

  /// 저장된 상태 초기화
  Future<void> _clearSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsTracking);
      await prefs.remove(_keyTodayTotalDistance);
      await prefs.remove(_keySessionDistance);
      await prefs.remove(_keyCurrentDate);
      await prefs.remove(_keySessionStartTime);
      logger.d('Running saved state cleared');
    } catch (e) {
      logger.e('Error clearing running state: $e');
    }
  }

  /// 러닝 추적 시작 (권한 상태 반환)
  Future<PermissionStatus> startTracking() async {
    if (_isTracking) {
      logger.w('Running tracker is already tracking');
      return PermissionStatus.granted;
    }

    try {
      // 권한 확인
      final permissionStatus = await requestPermission();
      if (!permissionStatus.isGranted) {
        return permissionStatus;
      }

      // 오늘 날짜 설정
      _currentDate = _getTodayDate();

      // 초기 위치 가져오기
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 위치 업데이트 스트림 구독
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // 5m마다 업데이트
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate,
        onError: _onPositionError,
        cancelOnError: false,
      );

      _isTracking = true;
      _sessionStartTime = DateTime.now();
      _sessionDistance = 0.0;  // 새 세션 시작
      
      // 자정 체크 타이머 시작
      _startMidnightCheckTimer();
      
      // 상태 저장
      await _saveTrackingState();
      
      logger.i('Running tracker started for date: $_currentDate');
      return PermissionStatus.granted;
    } catch (e) {
      logger.e('Error starting running tracker: $e');
      return PermissionStatus.denied;
    }
  }

  /// 추적 재개 (내부용 - 상태 복원 시)
  Future<void> _resumeTracking() async {
    try {
      // 현재 위치 가져오기
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 위치 스트림 재구독
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate,
        onError: _onPositionError,
        cancelOnError: false,
      );

      logger.i('Running tracker resumed');
    } catch (e) {
      logger.e('Error resuming running tracker: $e');
    }
  }

  /// 러닝 추적 일시정지
  Future<void> pauseTracking() async {
    if (!_isTracking) return;
    
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    
    // 상태 저장 (세션은 유지)
    await _saveTrackingState();
    
    logger.i('Running tracker paused. Session: ${_sessionDistance.toStringAsFixed(2)} km, Today: ${_todayTotalDistance.toStringAsFixed(2)} km');
  }

  /// 러닝 추적 재개
  Future<bool> resumeTracking() async {
    if (_isTracking) return true;

    try {
      await _resumeTracking();
      _isTracking = true;
      logger.i('Running tracker resumed from pause');
      return true;
    } catch (e) {
      logger.e('Error resuming running tracker: $e');
      return false;
    }
  }

  /// 현재 세션 저장 및 종료 (오늘 총 거리에 누적)
  Future<void> saveAndFinishSession() async {
    if (_sessionDistance > 0) {
      // 오늘 총 거리에 누적
      _todayTotalDistance += _sessionDistance;
      logger.i('Session saved: +${_sessionDistance.toStringAsFixed(2)} km, Today total: ${_todayTotalDistance.toStringAsFixed(2)} km');
      
      // 세션 초기화
      _sessionDistance = 0.0;
      _sessionStartTime = null;
      
      await _saveTrackingState();
    }
  }

  /// 러닝 추적 완전 중지 (세션 버리기)
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _midnightCheckTimer?.cancel();
    
    _positionSubscription = null;
    _midnightCheckTimer = null;
    _lastPosition = null;
    _sessionDistance = 0.0;
    _isTracking = false;
    _sessionStartTime = null;
    
    // 상태 초기화 (오늘 총 거리는 유지)
    await _clearSavedState();
    
    logger.i('Running tracker stopped and session discarded');
  }

  /// 위치 업데이트 핸들러 (차량 이동 필터링 포함)
  void _onPositionUpdate(Position position) {
    if (_lastPosition != null) {
      // 두 지점 간 거리 계산 (미터)
      final distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // km로 변환
      final distanceInKm = distanceInMeters / 1000.0;
      
      // 속도 계산 (km/h)
      final speed = position.speed * 3.6; // m/s -> km/h
      
      // ⚠️ 차량 이동 필터링: 속도가 25km/h 이상이면 무시
      if (speed > MAX_RUNNING_SPEED_KMH) {
        logger.w('Vehicle movement detected! Speed: ${speed.toStringAsFixed(1)} km/h - IGNORED');
        _speedController.add(0.0);  // UI에 0으로 표시
        _lastPosition = position;  // 위치는 업데이트
        return;
      }
      
      // 비정상적으로 큰 거리 변화 필터링 (GPS 오류 방지)
      // 한 번에 100m 이상 이동하면 무시
      if (distanceInKm < MAX_INSTANT_DISTANCE_KM) {
        _sessionDistance += distanceInKm;
        _distanceController.add(_sessionDistance);
        _speedController.add(speed);
        
        // 주기적으로 상태 저장
        _saveTrackingState();
        
        logger.d('Distance: ${_sessionDistance.toStringAsFixed(3)} km (today: ${_todayTotalDistance.toStringAsFixed(3)} km), Speed: ${speed.toStringAsFixed(1)} km/h');
      } else {
        logger.w('Abnormal distance detected: ${distanceInKm.toStringAsFixed(3)} km - IGNORED');
      }
    }

    _lastPosition = position;
  }

  /// 위치 에러 핸들러
  void _onPositionError(error) {
    logger.e('Running tracker error: $error');
  }

  /// 평균 속도 계산 (km/h)
  double get averageSpeed {
    if (_sessionStartTime == null || _sessionDistance == 0) return 0.0;
    
    final hours = elapsedTime.inSeconds / 3600.0;
    return hours > 0 ? _sessionDistance / hours : 0.0;
  }

  /// 평균 페이스 계산 (분/km)
  double get averagePace {
    final avgSpeed = averageSpeed;
    return avgSpeed > 0 ? 60.0 / avgSpeed : 0.0;
  }

  /// 리소스 정리
  void dispose() {
    stopTracking();
    _distanceController.close();
    _speedController.close();
    _midnightCheckTimer?.cancel();
  }
}




