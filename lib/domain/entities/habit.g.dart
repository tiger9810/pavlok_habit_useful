// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HabitImpl _$$HabitImplFromJson(Map<String, dynamic> json) => _$HabitImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  question: json['question'] as String?,
  color: (json['color'] as num?)?.toInt() ?? 0xFF2196F3,
  isNumeric: json['isNumeric'] as bool? ?? false,
  unit: json['unit'] as String?,
  target: (json['target'] as num?)?.toDouble(),
  targetType: json['targetType'] as String?,
  frequency: json['frequency'] as String? ?? 'daily',
  frequencyDetail: json['frequencyDetail'] as String?,
  reminderEnabled: json['reminderEnabled'] as bool? ?? false,
  reminderTime: json['reminderTime'] as String?,
  mode: $enumDecodeNullable(_$HabitModeEnumMap, json['mode']) ?? HabitMode.free,
  stoicStartTime: json['stoicStartTime'] as String?,
  stoicEndTime: json['stoicEndTime'] as String?,
  stoicAction: json['stoicAction'] as String?,
  stoicIntensity: (json['stoicIntensity'] as num?)?.toInt() ?? 50,
  stoicCountdownEnabled: json['stoicCountdownEnabled'] as bool? ?? false,
  points: (json['points'] as num?)?.toInt() ?? 0,
  consecutiveDays: (json['consecutiveDays'] as num?)?.toInt() ?? 0,
  totalCompletions: (json['totalCompletions'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  lastCompletedAt: json['lastCompletedAt'] == null
      ? null
      : DateTime.parse(json['lastCompletedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  dailyValues:
      (json['dailyValues'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const {},
);

Map<String, dynamic> _$$HabitImplToJson(_$HabitImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'question': instance.question,
      'color': instance.color,
      'isNumeric': instance.isNumeric,
      'unit': instance.unit,
      'target': instance.target,
      'targetType': instance.targetType,
      'frequency': instance.frequency,
      'frequencyDetail': instance.frequencyDetail,
      'reminderEnabled': instance.reminderEnabled,
      'reminderTime': instance.reminderTime,
      'mode': _$HabitModeEnumMap[instance.mode]!,
      'stoicStartTime': instance.stoicStartTime,
      'stoicEndTime': instance.stoicEndTime,
      'stoicAction': instance.stoicAction,
      'stoicIntensity': instance.stoicIntensity,
      'stoicCountdownEnabled': instance.stoicCountdownEnabled,
      'points': instance.points,
      'consecutiveDays': instance.consecutiveDays,
      'totalCompletions': instance.totalCompletions,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lastCompletedAt': instance.lastCompletedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'dailyValues': instance.dailyValues,
    };

const _$HabitModeEnumMap = {HabitMode.free: 'free', HabitMode.stoic: 'stoic'};
