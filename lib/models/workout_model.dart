import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_model.freezed.dart';
part 'workout_model.g.dart';

// 수동 입력 기능 제거 - 자동 추적만 사용
enum TrackingMode {
  automatic, // 자동 인식 (카메라/센서)
}

class DateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const DateTimeConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json == null) return DateTime.now();
    
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    } else if (json is String) {
      return DateTime.parse(json);
    } else {
      return DateTime.now();
    }
  }

  @override
  dynamic toJson(DateTime dateTime) => dateTime.millisecondsSinceEpoch;
}

class NullableDateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    } else if (json is String) {
      return DateTime.parse(json);
    } else {
      return null;
    }
  }

  @override
  dynamic toJson(DateTime? dateTime) => dateTime?.millisecondsSinceEpoch;
}

@freezed
class WorkoutModel with _$WorkoutModel {
  const factory WorkoutModel({
    @Default('') String id,
    @Default('') String userId,
    @Default(0) int squatCount,
    @Default(0) int lungeCount,
    @Default(0) int walkSteps,
    @Default(0.0) double runDistance, // km
    @Default(0) int duration, // seconds
    String? notes,
    @DateTimeConverter() required DateTime date,
    @NullableDateTimeConverter() DateTime? createdAt,
    @NullableDateTimeConverter() DateTime? updatedAt,
    // 추적 모드 (각 운동별) - 기본값 automatic
    @Default(TrackingMode.automatic) TrackingMode squatMode,
    @Default(TrackingMode.automatic) TrackingMode lungeMode,
    @Default(TrackingMode.automatic) TrackingMode walkMode,
    @Default(TrackingMode.automatic) TrackingMode runMode,
  }) = _WorkoutModel;

  factory WorkoutModel.fromJson(Map<String, dynamic> json) =>
      _$WorkoutModelFromJson(json);
}

