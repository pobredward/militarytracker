import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import '../core/config/logger.dart';

// 운동 타입 (클래스 외부로 이동)
enum ExerciseType { squat, lunge }

// 스쿼트/런지 상태 (클래스 외부로 이동)
enum ExerciseState { standing, down }

/// 스쿼트/런지 자세 인식 및 카운팅 서비스 (개선된 정확도)
class PoseDetectionService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  ExerciseState _currentState = ExerciseState.standing;
  int _exerciseCount = 0;
  ExerciseType _currentExercise = ExerciseType.squat;
  
  // 오카운팅 방지를 위한 변수
  DateTime? _lastCountTime;
  double _lastValidAngle = 180.0;
  int _consecutiveStandingFrames = 0;
  int _consecutiveDownFrames = 0;
  
  // 임계값 설정
  static const int MIN_STANDING_FRAMES = 5;  // 서있다고 판단하는 최소 프레임 수
  static const int MIN_DOWN_FRAMES = 5;      // 앉았다고 판단하는 최소 프레임 수
  static const double MIN_COUNT_INTERVAL_MS = 800.0;  // 최소 카운트 간격 (0.8초)

  // 카운트 스트림
  final _countController = StreamController<int>.broadcast();
  Stream<int> get countStream => _countController.stream;

  int get currentCount => _exerciseCount;

  /// 운동 타입 설정
  void setExerciseType(ExerciseType type) {
    _currentExercise = type;
    resetCount();
  }

  /// 카운트 리셋
  void resetCount() {
    _exerciseCount = 0;
    _currentState = ExerciseState.standing;
    _lastCountTime = null;
    _lastValidAngle = 180.0;
    _consecutiveStandingFrames = 0;
    _consecutiveDownFrames = 0;
    _countController.add(_exerciseCount);
  }

  /// 현재 세션 카운트 누적 (기존 기록에 더하기용)
  void addToCount(int previousCount) {
    _exerciseCount = previousCount;
    _countController.add(_exerciseCount);
  }

  /// 카메라 이미지에서 자세 감지 및 카운팅
  Future<void> processImage(CameraImage image, CameraDescription camera) async {
    try {
      final inputImage = _convertCameraImage(image, camera);
      if (inputImage == null) {
        logger.w('InputImage conversion failed');
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) {
        logger.w('No poses detected in frame');
        return;
      }

      final pose = poses.first;
      _analyzePose(pose);
    } catch (e) {
      logger.e('Error processing pose: $e');
    }
  }

  /// 자세 분석 및 카운팅 로직
  void _analyzePose(Pose pose) {
    final landmarks = pose.landmarks;

    // 필요한 랜드마크 추출
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || rightHip == null || 
        leftKnee == null || rightKnee == null ||
        leftAnkle == null || rightAnkle == null) {
      logger.w('Missing required landmarks for pose analysis');
      return;
    }

    logger.d('📍 All required landmarks detected');

    if (_currentExercise == ExerciseType.squat) {
      _analyzeSquat(leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle);
    } else {
      _analyzeLunge(leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle);
    }
  }

  /// 스쿼트 분석 (개선된 정확도)
  void _analyzeSquat(
    PoseLandmark leftHip,
    PoseLandmark rightHip,
    PoseLandmark leftKnee,
    PoseLandmark rightKnee,
    PoseLandmark leftAnkle,
    PoseLandmark rightAnkle,
  ) {
    // 양쪽 무릎 각도 계산
    final leftAngle = _calculateAngle(
      leftHip.x, leftHip.y,
      leftKnee.x, leftKnee.y,
      leftAnkle.x, leftAnkle.y,
    );
    
    final rightAngle = _calculateAngle(
      rightHip.x, rightHip.y,
      rightKnee.x, rightKnee.y,
      rightAnkle.x, rightAnkle.y,
    );
    
    // 평균 무릎 각도 사용 (더 안정적)
    final avgAngle = (leftAngle + rightAngle) / 2;
    _lastValidAngle = avgAngle;
    
    // 매 프레임마다 각도 로깅 (디버깅용)
    logger.d('📐 Squat angles - L: ${leftAngle.toStringAsFixed(1)}°, R: ${rightAngle.toStringAsFixed(1)}°, Avg: ${avgAngle.toStringAsFixed(1)}°, State: $_currentState');
    
    // 스쿼트 판정 임계값
    const double squatDownThreshold = 120.0;  // 120도 이하면 앉은 상태
    const double squatUpThreshold = 150.0;    // 150도 이상이면 선 상태
    
    // 상태 전환 로직 (프레임 카운팅으로 안정화)
    if (avgAngle < squatDownThreshold) {
      _consecutiveDownFrames++;
      _consecutiveStandingFrames = 0;
      
      logger.d('⬇️  Down position detected: $_consecutiveDownFrames frames');
      
      // 충분한 프레임 동안 앉은 상태 유지 시 상태 전환
      if (_consecutiveDownFrames >= MIN_DOWN_FRAMES && 
          _currentState == ExerciseState.standing) {
        _currentState = ExerciseState.down;
        logger.i('🔽 Squat: Down state confirmed (angle: ${avgAngle.toStringAsFixed(1)}°)');
      }
    } else if (avgAngle > squatUpThreshold) {
      _consecutiveStandingFrames++;
      _consecutiveDownFrames = 0;
      
      logger.d('⬆️  Up position detected: $_consecutiveStandingFrames frames');
      
      // 충분한 프레임 동안 선 상태 유지 시 카운트 증가
      if (_consecutiveStandingFrames >= MIN_STANDING_FRAMES &&
          _currentState == ExerciseState.down) {
        // 마지막 카운트로부터 최소 시간 경과 확인 (오카운팅 방지)
        final now = DateTime.now();
        if (_lastCountTime == null ||
            now.difference(_lastCountTime!).inMilliseconds >= MIN_COUNT_INTERVAL_MS) {
          _currentState = ExerciseState.standing;
          _exerciseCount++;
          _lastCountTime = now;
          _countController.add(_exerciseCount);
          logger.i('✅ Squat count: $_exerciseCount (angle: ${avgAngle.toStringAsFixed(1)}°)');
        } else {
          logger.d('⏱️  Count blocked: too soon (${now.difference(_lastCountTime!).inMilliseconds}ms < ${MIN_COUNT_INTERVAL_MS}ms)');
        }
      }
    } else {
      // 중간 각도: 프레임 카운터 리셋하지 않음 (자연스러운 전환 허용)
      logger.d('↔️  Transition zone (${avgAngle.toStringAsFixed(1)}°)');
    }
  }

  /// 런지 분석 (개선된 정확도)
  void _analyzeLunge(
    PoseLandmark leftHip,
    PoseLandmark rightHip,
    PoseLandmark leftKnee,
    PoseLandmark rightKnee,
    PoseLandmark leftAnkle,
    PoseLandmark rightAnkle,
  ) {
    // 왼쪽/오른쪽 무릎 각도 계산
    final leftAngle = _calculateAngle(
      leftHip.x, leftHip.y,
      leftKnee.x, leftKnee.y,
      leftAnkle.x, leftAnkle.y,
    );
    
    final rightAngle = _calculateAngle(
      rightHip.x, rightHip.y,
      rightKnee.x, rightKnee.y,
      rightAnkle.x, rightAnkle.y,
    );

    // 런지 판정: 한쪽 무릎은 굽히고 다른 쪽은 펴진 상태
    const double lungeDownThreshold = 120.0;  // 앞다리가 120도 이하
    const double lungeUpThreshold = 140.0;    // 뒷다리가 140도 이상
    
    final isLeftLunge = leftAngle < lungeDownThreshold && rightAngle > lungeUpThreshold;
    final isRightLunge = rightAngle < lungeDownThreshold && leftAngle > lungeUpThreshold;
    final isLungePosition = isLeftLunge || isRightLunge;
    
    // 양쪽 다리가 모두 서있는 상태
    const double bothStandingThreshold = 150.0;
    final isBothStanding = leftAngle > bothStandingThreshold && rightAngle > bothStandingThreshold;
    
    // 상태 전환 로직
    if (isLungePosition) {
      _consecutiveDownFrames++;
      _consecutiveStandingFrames = 0;
      
      // 충분한 프레임 동안 런지 자세 유지 시 상태 전환
      if (_consecutiveDownFrames >= MIN_DOWN_FRAMES && 
          _currentState == ExerciseState.standing) {
        _currentState = ExerciseState.down;
        logger.d('Lunge: Down detected (L: ${leftAngle.toStringAsFixed(1)}, R: ${rightAngle.toStringAsFixed(1)})');
      }
    } else if (isBothStanding) {
      _consecutiveStandingFrames++;
      _consecutiveDownFrames = 0;
      
      // 충분한 프레임 동안 선 상태 유지 시 카운트 증가
      if (_consecutiveStandingFrames >= MIN_STANDING_FRAMES &&
          _currentState == ExerciseState.down) {
        // 마지막 카운트로부터 최소 시간 경과 확인
        final now = DateTime.now();
        if (_lastCountTime == null ||
            now.difference(_lastCountTime!).inMilliseconds >= MIN_COUNT_INTERVAL_MS) {
          _currentState = ExerciseState.standing;
          _exerciseCount++;
          _lastCountTime = now;
          _countController.add(_exerciseCount);
          logger.i('✅ Lunge count: $_exerciseCount (L: ${leftAngle.toStringAsFixed(1)}, R: ${rightAngle.toStringAsFixed(1)})');
        }
      }
    }
  }

  /// 세 점으로 각도 계산 (degree)
  double _calculateAngle(double x1, double y1, double x2, double y2, double x3, double y3) {
    final radians = atan2(y3 - y2, x3 - x2) - atan2(y1 - y2, x1 - x2);
    var angle = radians * 180.0 / pi;
    if (angle < 0) angle += 360.0;
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  /// CameraImage를 InputImage로 변환
  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageRotation = _rotationIntToImageRotation(camera.sensorOrientation);

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
      if (inputImageFormat == null) return null;

      final planeData = image.planes.map((Plane plane) {
        return InputImageMetadata(
          bytesPerRow: plane.bytesPerRow,
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: inputImageFormat,
        );
      }).toList();

      final inputImageMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );
    } catch (e) {
      logger.e('Error converting camera image: $e');
      return null;
    }
  }

  /// 카메라 회전값을 InputImageRotation으로 변환
  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// 리소스 정리
  void dispose() {
    _poseDetector.close();
    _countController.close();
  }
}

