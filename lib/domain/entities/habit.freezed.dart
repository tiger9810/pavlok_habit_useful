// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'habit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Habit _$HabitFromJson(Map<String, dynamic> json) {
  return _Habit.fromJson(json);
}

/// @nodoc
mixin _$Habit {
  /// 習慣の一意なID
  String get id => throw _privateConstructorUsedError;

  /// 習慣の名前
  String get name => throw _privateConstructorUsedError;

  /// 習慣の説明（オプション）
  String? get description => throw _privateConstructorUsedError;

  /// 習慣の質問（例: 「今日は何km走りましたか?」）
  String? get question => throw _privateConstructorUsedError;

  /// 習慣の色（カラーピッカーで選択）
  int get color => throw _privateConstructorUsedError;

  /// 数値目標を設定するかどうか
  bool get isNumeric => throw _privateConstructorUsedError;

  /// 単位（km, pagesなど）
  String? get unit => throw _privateConstructorUsedError;

  /// 目標値
  double? get target => throw _privateConstructorUsedError;

  /// 目標タイプ（atLeast: 少なくとも, atMost: 以下）
  String? get targetType => throw _privateConstructorUsedError;

  /// 頻度設定（daily: 毎日, weekly: 週次, interval: 間隔）
  String get frequency => throw _privateConstructorUsedError;

  /// 頻度の詳細（weeklyの場合の曜日、intervalの場合の日数など）
  String? get frequencyDetail => throw _privateConstructorUsedError;

  /// リマインダーが有効かどうか
  bool get reminderEnabled => throw _privateConstructorUsedError;

  /// リマインダーの時刻（HH:mm形式）
  String? get reminderTime => throw _privateConstructorUsedError;

  /// 習慣のモード（free or stoic）
  HabitMode get mode => throw _privateConstructorUsedError;

  /// ストイックモード: 開始時刻（HH:mm形式）
  String? get stoicStartTime => throw _privateConstructorUsedError;

  /// ストイックモード: 終了時刻（HH:mm形式）
  String? get stoicEndTime => throw _privateConstructorUsedError;

  /// ストイックモード: 罰のアクション（shock, vibrate, beep）
  String? get stoicAction => throw _privateConstructorUsedError;

  /// ストイックモード: 罰の強度（0-100）
  int get stoicIntensity => throw _privateConstructorUsedError;

  /// ストイックモード: カウントダウン有効
  bool get stoicCountdownEnabled => throw _privateConstructorUsedError;

  /// 現在のポイント
  int get points => throw _privateConstructorUsedError;

  /// 連続達成日数
  int get consecutiveDays => throw _privateConstructorUsedError;

  /// 総達成回数
  int get totalCompletions => throw _privateConstructorUsedError;

  /// 習慣の作成日時
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 習慣の最終更新日時
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// 最後に達成した日時（nullの場合は未達成）
  DateTime? get lastCompletedAt => throw _privateConstructorUsedError;

  /// 習慣が有効かどうか
  bool get isActive => throw _privateConstructorUsedError;

  /// 日ごとの数値進捗（キーは "yyyy-MM-dd" 形式の文字列）
  Map<String, double> get dailyValues => throw _privateConstructorUsedError;

  /// Serializes this Habit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Habit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HabitCopyWith<Habit> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HabitCopyWith<$Res> {
  factory $HabitCopyWith(Habit value, $Res Function(Habit) then) =
      _$HabitCopyWithImpl<$Res, Habit>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? question,
    int color,
    bool isNumeric,
    String? unit,
    double? target,
    String? targetType,
    String frequency,
    String? frequencyDetail,
    bool reminderEnabled,
    String? reminderTime,
    HabitMode mode,
    String? stoicStartTime,
    String? stoicEndTime,
    String? stoicAction,
    int stoicIntensity,
    bool stoicCountdownEnabled,
    int points,
    int consecutiveDays,
    int totalCompletions,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? lastCompletedAt,
    bool isActive,
    Map<String, double> dailyValues,
  });
}

/// @nodoc
class _$HabitCopyWithImpl<$Res, $Val extends Habit>
    implements $HabitCopyWith<$Res> {
  _$HabitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Habit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? question = freezed,
    Object? color = null,
    Object? isNumeric = null,
    Object? unit = freezed,
    Object? target = freezed,
    Object? targetType = freezed,
    Object? frequency = null,
    Object? frequencyDetail = freezed,
    Object? reminderEnabled = null,
    Object? reminderTime = freezed,
    Object? mode = null,
    Object? stoicStartTime = freezed,
    Object? stoicEndTime = freezed,
    Object? stoicAction = freezed,
    Object? stoicIntensity = null,
    Object? stoicCountdownEnabled = null,
    Object? points = null,
    Object? consecutiveDays = null,
    Object? totalCompletions = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? lastCompletedAt = freezed,
    Object? isActive = null,
    Object? dailyValues = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            question: freezed == question
                ? _value.question
                : question // ignore: cast_nullable_to_non_nullable
                      as String?,
            color: null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as int,
            isNumeric: null == isNumeric
                ? _value.isNumeric
                : isNumeric // ignore: cast_nullable_to_non_nullable
                      as bool,
            unit: freezed == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String?,
            target: freezed == target
                ? _value.target
                : target // ignore: cast_nullable_to_non_nullable
                      as double?,
            targetType: freezed == targetType
                ? _value.targetType
                : targetType // ignore: cast_nullable_to_non_nullable
                      as String?,
            frequency: null == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as String,
            frequencyDetail: freezed == frequencyDetail
                ? _value.frequencyDetail
                : frequencyDetail // ignore: cast_nullable_to_non_nullable
                      as String?,
            reminderEnabled: null == reminderEnabled
                ? _value.reminderEnabled
                : reminderEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            reminderTime: freezed == reminderTime
                ? _value.reminderTime
                : reminderTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as HabitMode,
            stoicStartTime: freezed == stoicStartTime
                ? _value.stoicStartTime
                : stoicStartTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            stoicEndTime: freezed == stoicEndTime
                ? _value.stoicEndTime
                : stoicEndTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            stoicAction: freezed == stoicAction
                ? _value.stoicAction
                : stoicAction // ignore: cast_nullable_to_non_nullable
                      as String?,
            stoicIntensity: null == stoicIntensity
                ? _value.stoicIntensity
                : stoicIntensity // ignore: cast_nullable_to_non_nullable
                      as int,
            stoicCountdownEnabled: null == stoicCountdownEnabled
                ? _value.stoicCountdownEnabled
                : stoicCountdownEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as int,
            consecutiveDays: null == consecutiveDays
                ? _value.consecutiveDays
                : consecutiveDays // ignore: cast_nullable_to_non_nullable
                      as int,
            totalCompletions: null == totalCompletions
                ? _value.totalCompletions
                : totalCompletions // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            lastCompletedAt: freezed == lastCompletedAt
                ? _value.lastCompletedAt
                : lastCompletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            dailyValues: null == dailyValues
                ? _value.dailyValues
                : dailyValues // ignore: cast_nullable_to_non_nullable
                      as Map<String, double>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HabitImplCopyWith<$Res> implements $HabitCopyWith<$Res> {
  factory _$$HabitImplCopyWith(
    _$HabitImpl value,
    $Res Function(_$HabitImpl) then,
  ) = __$$HabitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? question,
    int color,
    bool isNumeric,
    String? unit,
    double? target,
    String? targetType,
    String frequency,
    String? frequencyDetail,
    bool reminderEnabled,
    String? reminderTime,
    HabitMode mode,
    String? stoicStartTime,
    String? stoicEndTime,
    String? stoicAction,
    int stoicIntensity,
    bool stoicCountdownEnabled,
    int points,
    int consecutiveDays,
    int totalCompletions,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? lastCompletedAt,
    bool isActive,
    Map<String, double> dailyValues,
  });
}

/// @nodoc
class __$$HabitImplCopyWithImpl<$Res>
    extends _$HabitCopyWithImpl<$Res, _$HabitImpl>
    implements _$$HabitImplCopyWith<$Res> {
  __$$HabitImplCopyWithImpl(
    _$HabitImpl _value,
    $Res Function(_$HabitImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Habit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? question = freezed,
    Object? color = null,
    Object? isNumeric = null,
    Object? unit = freezed,
    Object? target = freezed,
    Object? targetType = freezed,
    Object? frequency = null,
    Object? frequencyDetail = freezed,
    Object? reminderEnabled = null,
    Object? reminderTime = freezed,
    Object? mode = null,
    Object? stoicStartTime = freezed,
    Object? stoicEndTime = freezed,
    Object? stoicAction = freezed,
    Object? stoicIntensity = null,
    Object? stoicCountdownEnabled = null,
    Object? points = null,
    Object? consecutiveDays = null,
    Object? totalCompletions = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? lastCompletedAt = freezed,
    Object? isActive = null,
    Object? dailyValues = null,
  }) {
    return _then(
      _$HabitImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        question: freezed == question
            ? _value.question
            : question // ignore: cast_nullable_to_non_nullable
                  as String?,
        color: null == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as int,
        isNumeric: null == isNumeric
            ? _value.isNumeric
            : isNumeric // ignore: cast_nullable_to_non_nullable
                  as bool,
        unit: freezed == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String?,
        target: freezed == target
            ? _value.target
            : target // ignore: cast_nullable_to_non_nullable
                  as double?,
        targetType: freezed == targetType
            ? _value.targetType
            : targetType // ignore: cast_nullable_to_non_nullable
                  as String?,
        frequency: null == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as String,
        frequencyDetail: freezed == frequencyDetail
            ? _value.frequencyDetail
            : frequencyDetail // ignore: cast_nullable_to_non_nullable
                  as String?,
        reminderEnabled: null == reminderEnabled
            ? _value.reminderEnabled
            : reminderEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        reminderTime: freezed == reminderTime
            ? _value.reminderTime
            : reminderTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as HabitMode,
        stoicStartTime: freezed == stoicStartTime
            ? _value.stoicStartTime
            : stoicStartTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        stoicEndTime: freezed == stoicEndTime
            ? _value.stoicEndTime
            : stoicEndTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        stoicAction: freezed == stoicAction
            ? _value.stoicAction
            : stoicAction // ignore: cast_nullable_to_non_nullable
                  as String?,
        stoicIntensity: null == stoicIntensity
            ? _value.stoicIntensity
            : stoicIntensity // ignore: cast_nullable_to_non_nullable
                  as int,
        stoicCountdownEnabled: null == stoicCountdownEnabled
            ? _value.stoicCountdownEnabled
            : stoicCountdownEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        points: null == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as int,
        consecutiveDays: null == consecutiveDays
            ? _value.consecutiveDays
            : consecutiveDays // ignore: cast_nullable_to_non_nullable
                  as int,
        totalCompletions: null == totalCompletions
            ? _value.totalCompletions
            : totalCompletions // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        lastCompletedAt: freezed == lastCompletedAt
            ? _value.lastCompletedAt
            : lastCompletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        dailyValues: null == dailyValues
            ? _value._dailyValues
            : dailyValues // ignore: cast_nullable_to_non_nullable
                  as Map<String, double>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HabitImpl extends _Habit {
  const _$HabitImpl({
    required this.id,
    required this.name,
    this.description,
    this.question,
    this.color = 0xFF2196F3,
    this.isNumeric = false,
    this.unit,
    this.target,
    this.targetType,
    this.frequency = 'daily',
    this.frequencyDetail,
    this.reminderEnabled = false,
    this.reminderTime,
    this.mode = HabitMode.free,
    this.stoicStartTime,
    this.stoicEndTime,
    this.stoicAction,
    this.stoicIntensity = 50,
    this.stoicCountdownEnabled = false,
    this.points = 0,
    this.consecutiveDays = 0,
    this.totalCompletions = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastCompletedAt,
    this.isActive = true,
    final Map<String, double> dailyValues = const {},
  }) : _dailyValues = dailyValues,
       super._();

  factory _$HabitImpl.fromJson(Map<String, dynamic> json) =>
      _$$HabitImplFromJson(json);

  /// 習慣の一意なID
  @override
  final String id;

  /// 習慣の名前
  @override
  final String name;

  /// 習慣の説明（オプション）
  @override
  final String? description;

  /// 習慣の質問（例: 「今日は何km走りましたか?」）
  @override
  final String? question;

  /// 習慣の色（カラーピッカーで選択）
  @override
  @JsonKey()
  final int color;

  /// 数値目標を設定するかどうか
  @override
  @JsonKey()
  final bool isNumeric;

  /// 単位（km, pagesなど）
  @override
  final String? unit;

  /// 目標値
  @override
  final double? target;

  /// 目標タイプ（atLeast: 少なくとも, atMost: 以下）
  @override
  final String? targetType;

  /// 頻度設定（daily: 毎日, weekly: 週次, interval: 間隔）
  @override
  @JsonKey()
  final String frequency;

  /// 頻度の詳細（weeklyの場合の曜日、intervalの場合の日数など）
  @override
  final String? frequencyDetail;

  /// リマインダーが有効かどうか
  @override
  @JsonKey()
  final bool reminderEnabled;

  /// リマインダーの時刻（HH:mm形式）
  @override
  final String? reminderTime;

  /// 習慣のモード（free or stoic）
  @override
  @JsonKey()
  final HabitMode mode;

  /// ストイックモード: 開始時刻（HH:mm形式）
  @override
  final String? stoicStartTime;

  /// ストイックモード: 終了時刻（HH:mm形式）
  @override
  final String? stoicEndTime;

  /// ストイックモード: 罰のアクション（shock, vibrate, beep）
  @override
  final String? stoicAction;

  /// ストイックモード: 罰の強度（0-100）
  @override
  @JsonKey()
  final int stoicIntensity;

  /// ストイックモード: カウントダウン有効
  @override
  @JsonKey()
  final bool stoicCountdownEnabled;

  /// 現在のポイント
  @override
  @JsonKey()
  final int points;

  /// 連続達成日数
  @override
  @JsonKey()
  final int consecutiveDays;

  /// 総達成回数
  @override
  @JsonKey()
  final int totalCompletions;

  /// 習慣の作成日時
  @override
  final DateTime createdAt;

  /// 習慣の最終更新日時
  @override
  final DateTime updatedAt;

  /// 最後に達成した日時（nullの場合は未達成）
  @override
  final DateTime? lastCompletedAt;

  /// 習慣が有効かどうか
  @override
  @JsonKey()
  final bool isActive;

  /// 日ごとの数値進捗（キーは "yyyy-MM-dd" 形式の文字列）
  final Map<String, double> _dailyValues;

  /// 日ごとの数値進捗（キーは "yyyy-MM-dd" 形式の文字列）
  @override
  @JsonKey()
  Map<String, double> get dailyValues {
    if (_dailyValues is EqualUnmodifiableMapView) return _dailyValues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_dailyValues);
  }

  @override
  String toString() {
    return 'Habit(id: $id, name: $name, description: $description, question: $question, color: $color, isNumeric: $isNumeric, unit: $unit, target: $target, targetType: $targetType, frequency: $frequency, frequencyDetail: $frequencyDetail, reminderEnabled: $reminderEnabled, reminderTime: $reminderTime, mode: $mode, stoicStartTime: $stoicStartTime, stoicEndTime: $stoicEndTime, stoicAction: $stoicAction, stoicIntensity: $stoicIntensity, stoicCountdownEnabled: $stoicCountdownEnabled, points: $points, consecutiveDays: $consecutiveDays, totalCompletions: $totalCompletions, createdAt: $createdAt, updatedAt: $updatedAt, lastCompletedAt: $lastCompletedAt, isActive: $isActive, dailyValues: $dailyValues)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HabitImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isNumeric, isNumeric) ||
                other.isNumeric == isNumeric) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.targetType, targetType) ||
                other.targetType == targetType) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.frequencyDetail, frequencyDetail) ||
                other.frequencyDetail == frequencyDetail) &&
            (identical(other.reminderEnabled, reminderEnabled) ||
                other.reminderEnabled == reminderEnabled) &&
            (identical(other.reminderTime, reminderTime) ||
                other.reminderTime == reminderTime) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.stoicStartTime, stoicStartTime) ||
                other.stoicStartTime == stoicStartTime) &&
            (identical(other.stoicEndTime, stoicEndTime) ||
                other.stoicEndTime == stoicEndTime) &&
            (identical(other.stoicAction, stoicAction) ||
                other.stoicAction == stoicAction) &&
            (identical(other.stoicIntensity, stoicIntensity) ||
                other.stoicIntensity == stoicIntensity) &&
            (identical(other.stoicCountdownEnabled, stoicCountdownEnabled) ||
                other.stoicCountdownEnabled == stoicCountdownEnabled) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.consecutiveDays, consecutiveDays) ||
                other.consecutiveDays == consecutiveDays) &&
            (identical(other.totalCompletions, totalCompletions) ||
                other.totalCompletions == totalCompletions) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.lastCompletedAt, lastCompletedAt) ||
                other.lastCompletedAt == lastCompletedAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality().equals(
              other._dailyValues,
              _dailyValues,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    description,
    question,
    color,
    isNumeric,
    unit,
    target,
    targetType,
    frequency,
    frequencyDetail,
    reminderEnabled,
    reminderTime,
    mode,
    stoicStartTime,
    stoicEndTime,
    stoicAction,
    stoicIntensity,
    stoicCountdownEnabled,
    points,
    consecutiveDays,
    totalCompletions,
    createdAt,
    updatedAt,
    lastCompletedAt,
    isActive,
    const DeepCollectionEquality().hash(_dailyValues),
  ]);

  /// Create a copy of Habit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HabitImplCopyWith<_$HabitImpl> get copyWith =>
      __$$HabitImplCopyWithImpl<_$HabitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HabitImplToJson(this);
  }
}

abstract class _Habit extends Habit {
  const factory _Habit({
    required final String id,
    required final String name,
    final String? description,
    final String? question,
    final int color,
    final bool isNumeric,
    final String? unit,
    final double? target,
    final String? targetType,
    final String frequency,
    final String? frequencyDetail,
    final bool reminderEnabled,
    final String? reminderTime,
    final HabitMode mode,
    final String? stoicStartTime,
    final String? stoicEndTime,
    final String? stoicAction,
    final int stoicIntensity,
    final bool stoicCountdownEnabled,
    final int points,
    final int consecutiveDays,
    final int totalCompletions,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final DateTime? lastCompletedAt,
    final bool isActive,
    final Map<String, double> dailyValues,
  }) = _$HabitImpl;
  const _Habit._() : super._();

  factory _Habit.fromJson(Map<String, dynamic> json) = _$HabitImpl.fromJson;

  /// 習慣の一意なID
  @override
  String get id;

  /// 習慣の名前
  @override
  String get name;

  /// 習慣の説明（オプション）
  @override
  String? get description;

  /// 習慣の質問（例: 「今日は何km走りましたか?」）
  @override
  String? get question;

  /// 習慣の色（カラーピッカーで選択）
  @override
  int get color;

  /// 数値目標を設定するかどうか
  @override
  bool get isNumeric;

  /// 単位（km, pagesなど）
  @override
  String? get unit;

  /// 目標値
  @override
  double? get target;

  /// 目標タイプ（atLeast: 少なくとも, atMost: 以下）
  @override
  String? get targetType;

  /// 頻度設定（daily: 毎日, weekly: 週次, interval: 間隔）
  @override
  String get frequency;

  /// 頻度の詳細（weeklyの場合の曜日、intervalの場合の日数など）
  @override
  String? get frequencyDetail;

  /// リマインダーが有効かどうか
  @override
  bool get reminderEnabled;

  /// リマインダーの時刻（HH:mm形式）
  @override
  String? get reminderTime;

  /// 習慣のモード（free or stoic）
  @override
  HabitMode get mode;

  /// ストイックモード: 開始時刻（HH:mm形式）
  @override
  String? get stoicStartTime;

  /// ストイックモード: 終了時刻（HH:mm形式）
  @override
  String? get stoicEndTime;

  /// ストイックモード: 罰のアクション（shock, vibrate, beep）
  @override
  String? get stoicAction;

  /// ストイックモード: 罰の強度（0-100）
  @override
  int get stoicIntensity;

  /// ストイックモード: カウントダウン有効
  @override
  bool get stoicCountdownEnabled;

  /// 現在のポイント
  @override
  int get points;

  /// 連続達成日数
  @override
  int get consecutiveDays;

  /// 総達成回数
  @override
  int get totalCompletions;

  /// 習慣の作成日時
  @override
  DateTime get createdAt;

  /// 習慣の最終更新日時
  @override
  DateTime get updatedAt;

  /// 最後に達成した日時（nullの場合は未達成）
  @override
  DateTime? get lastCompletedAt;

  /// 習慣が有効かどうか
  @override
  bool get isActive;

  /// 日ごとの数値進捗（キーは "yyyy-MM-dd" 形式の文字列）
  @override
  Map<String, double> get dailyValues;

  /// Create a copy of Habit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HabitImplCopyWith<_$HabitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
