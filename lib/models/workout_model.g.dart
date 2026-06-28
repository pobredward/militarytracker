// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutModelImpl _$$WorkoutModelImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutModelImpl(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      squatCount: (json['squatCount'] as num?)?.toInt() ?? 0,
      lungeCount: (json['lungeCount'] as num?)?.toInt() ?? 0,
      walkSteps: (json['walkSteps'] as num?)?.toInt() ?? 0,
      runDistance: (json['runDistance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      date: const DateTimeConverter().fromJson(json['date']),
      createdAt: const NullableDateTimeConverter().fromJson(json['createdAt']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updatedAt']),
      squatMode:
          $enumDecodeNullable(_$TrackingModeEnumMap, json['squatMode']) ??
              TrackingMode.automatic,
      lungeMode:
          $enumDecodeNullable(_$TrackingModeEnumMap, json['lungeMode']) ??
              TrackingMode.automatic,
      walkMode: $enumDecodeNullable(_$TrackingModeEnumMap, json['walkMode']) ??
          TrackingMode.automatic,
      runMode: $enumDecodeNullable(_$TrackingModeEnumMap, json['runMode']) ??
          TrackingMode.automatic,
    );

Map<String, dynamic> _$$WorkoutModelImplToJson(_$WorkoutModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'squatCount': instance.squatCount,
      'lungeCount': instance.lungeCount,
      'walkSteps': instance.walkSteps,
      'runDistance': instance.runDistance,
      'duration': instance.duration,
      'notes': instance.notes,
      'date': const DateTimeConverter().toJson(instance.date),
      'createdAt': const NullableDateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const NullableDateTimeConverter().toJson(instance.updatedAt),
      'squatMode': _$TrackingModeEnumMap[instance.squatMode]!,
      'lungeMode': _$TrackingModeEnumMap[instance.lungeMode]!,
      'walkMode': _$TrackingModeEnumMap[instance.walkMode]!,
      'runMode': _$TrackingModeEnumMap[instance.runMode]!,
    };

const _$TrackingModeEnumMap = {
  TrackingMode.automatic: 'automatic',
};
