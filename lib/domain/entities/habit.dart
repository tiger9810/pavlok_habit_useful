import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit.freezed.dart';
part 'habit.g.dart';

/// 習慣のモードを定義するEnum
enum HabitMode {
  /// フリーモード: 達成時にポイントが加算される
  @JsonValue('free')
  free,
  
  /// ストイックモード: 達成しなかった場合にペナルティが発生する
  @JsonValue('stoic')
  stoic,
}

/// 習慣エンティティ
/// 
/// ユーザーが設定した習慣を表すエンティティです。
/// 連続達成日数に応じたポイント計算ロジックを含みます。
@freezed
class Habit with _$Habit {
  const Habit._();
  
  const factory Habit({
    /// 習慣の一意なID
    required String id,
    
    /// 習慣の名前
    required String name,
    
    /// 習慣の説明（オプション）
    String? description,
    
    /// 習慣の質問（例: 「今日は何km走りましたか?」）
    String? question,
    
    /// 習慣の色（カラーピッカーで選択）
    @Default(0xFF2196F3) int color,
    
    /// 数値目標を設定するかどうか
    @Default(false) bool isNumeric,
    
    /// 単位（km, pagesなど）
    String? unit,
    
    /// 目標値
    double? target,
    
    /// 目標タイプ（atLeast: 少なくとも, atMost: 以下）
    String? targetType,
    
    /// 頻度設定（daily: 毎日, weekly: 週次, interval: 間隔）
    @Default('daily') String frequency,
    
    /// 頻度の詳細（weeklyの場合の曜日、intervalの場合の日数など）
    String? frequencyDetail,
    
    /// リマインダーが有効かどうか
    @Default(false) bool reminderEnabled,
    
    /// リマインダーの時刻（HH:mm形式）
    String? reminderTime,
    
    /// 習慣のモード（free or stoic）
    @Default(HabitMode.free) HabitMode mode,
    
    /// ストイックモード: 開始時刻（HH:mm形式）
    String? stoicStartTime,
    
    /// ストイックモード: 終了時刻（HH:mm形式）
    String? stoicEndTime,
    
    /// ストイックモード: 罰のアクション（shock, vibrate, beep）
    String? stoicAction,
    
    /// ストイックモード: 罰の強度（0-100）
    @Default(50) int stoicIntensity,
    
    /// ストイックモード: カウントダウン有効
    @Default(false) bool stoicCountdownEnabled,
    
    /// 現在のポイント
    @Default(0) int points,
    
    /// 連続達成日数
    @Default(0) int consecutiveDays,
    
    /// 総達成回数
    @Default(0) int totalCompletions,
    
    /// 習慣の作成日時
    required DateTime createdAt,
    
    /// 習慣の最終更新日時
    required DateTime updatedAt,
    
    /// 最後に達成した日時（nullの場合は未達成）
    DateTime? lastCompletedAt,
    
    /// 習慣が有効かどうか
    @Default(true) bool isActive,
    
    /// 日ごとの数値進捗（キーは "yyyy-MM-dd" 形式の文字列）
    @Default({}) Map<String, double> dailyValues,
  }) = _Habit;
  
  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);
  
  /// 習慣を達成した際のポイントを計算します
  /// 
  /// 連続達成日数に応じてボーナスポイントが加算されます：
  /// - 1-6日: 基本ポイント（10ポイント）
  /// - 7-13日: 1.5倍ボーナス（15ポイント）
  /// - 14-20日: 2倍ボーナス（20ポイント）
  /// - 21-27日: 2.5倍ボーナス（25ポイント）
  /// - 28日以上: 3倍ボーナス（30ポイント）
  /// 
  /// [basePoints] 基本ポイント（デフォルト: 10）
  /// Returns 達成時に獲得できるポイント
  int calculateCompletionPoints({int basePoints = 10}) {
    if (consecutiveDays == 0) {
      // 初回達成時は基本ポイント
      return basePoints;
    }
    
    // 連続達成日数に応じたボーナス計算
    if (consecutiveDays >= 28) {
      return (basePoints * 3).round();
    } else if (consecutiveDays >= 21) {
      return (basePoints * 2.5).round();
    } else if (consecutiveDays >= 14) {
      return (basePoints * 2).round();
    } else if (consecutiveDays >= 7) {
      return (basePoints * 1.5).round();
    } else {
      return basePoints;
    }
  }
  
  /// ストイックモードでのペナルティポイントを計算します
  /// 
  /// ストイックモードで達成しなかった場合のペナルティ：
  /// - 連続達成日数が0の場合: ペナルティなし
  /// - 連続達成日数が1-6日: -5ポイント
  /// - 連続達成日数が7-13日: -10ポイント
  /// - 連続達成日数が14-20日: -15ポイント
  /// - 連続達成日数が21-27日: -20ポイント
  /// - 連続達成日数が28日以上: -25ポイント
  /// 
  /// Returns ペナルティポイント（負の値）
  int calculatePenaltyPoints() {
    if (mode != HabitMode.stoic) {
      return 0;
    }
    
    if (consecutiveDays == 0) {
      return 0;
    }
    
    // 連続達成日数に応じたペナルティ計算
    if (consecutiveDays >= 28) {
      return -25;
    } else if (consecutiveDays >= 21) {
      return -20;
    } else if (consecutiveDays >= 14) {
      return -15;
    } else if (consecutiveDays >= 7) {
      return -10;
    } else {
      return -5;
    }
  }
  
  /// 今日達成したかどうかを判定します
  /// 
  /// [today] 今日の日時（デフォルト: DateTime.now()）
  /// Returns 今日達成済みの場合true
  bool isCompletedToday([DateTime? today]) {
    final now = today ?? DateTime.now();
    if (lastCompletedAt == null) {
      return false;
    }
    
    final lastCompleted = lastCompletedAt!;
    return lastCompleted.year == now.year &&
        lastCompleted.month == now.month &&
        lastCompleted.day == now.day;
  }
  
  /// 習慣を達成した新しいHabitインスタンスを返します
  /// 
  /// [completedAt] 達成日時（デフォルト: DateTime.now()）
  /// Returns 更新されたHabitインスタンス
  Habit markAsCompleted([DateTime? completedAt]) {
    final now = completedAt ?? DateTime.now();
    final wasCompletedToday = isCompletedToday(now);
    
    if (wasCompletedToday) {
      // 既に今日達成済みの場合は変更なし
      return this;
    }
    
    // 連続達成日数の更新
    final newConsecutiveDays = _calculateNewConsecutiveDays(now);
    final completionPoints = calculateCompletionPoints();
    
    return copyWith(
      consecutiveDays: newConsecutiveDays,
      totalCompletions: totalCompletions + 1,
      points: points + completionPoints,
      lastCompletedAt: now,
      updatedAt: now,
      dailyValues: dailyValues, // dailyValuesを保持
    );
  }
  
  /// 習慣を未達成としてマークします（ストイックモード用）
  /// 
  /// ストイックモードで達成しなかった場合、ペナルティが適用されます。
  /// [checkedAt] チェック日時（デフォルト: DateTime.now()）
  /// Returns 更新されたHabitインスタンス
  Habit markAsIncomplete([DateTime? checkedAt]) {
    if (mode != HabitMode.stoic) {
      return this;
    }
    
    final now = checkedAt ?? DateTime.now();
    
    // 既に今日チェック済みの場合は変更なし
    if (updatedAt.year == now.year &&
        updatedAt.month == now.month &&
        updatedAt.day == now.day &&
        consecutiveDays == 0) {
      return this;
    }
    
    final penaltyPoints = calculatePenaltyPoints();
    
    return copyWith(
      consecutiveDays: 0,
      points: points + penaltyPoints,
      updatedAt: now,
      dailyValues: dailyValues, // dailyValuesを保持
    );
  }
  
  /// 新しい連続達成日数を計算します
  /// 
  /// 最後に達成した日が昨日の場合、連続達成日数を1増やします。
  /// それ以外の場合は1にリセットします。
  int _calculateNewConsecutiveDays(DateTime now) {
    if (lastCompletedAt == null) {
      return 1;
    }
    
    final lastCompleted = lastCompletedAt!;
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final lastCompletedDate = DateTime(
      lastCompleted.year,
      lastCompleted.month,
      lastCompleted.day,
    );
    
    if (lastCompletedDate == yesterday) {
      // 昨日達成していた場合は連続達成日数を増やす
      return consecutiveDays + 1;
    } else {
      // それ以外の場合は1にリセット
      return 1;
    }
  }
  
  /// 習慣を無効化します
  Habit deactivate() {
    return copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
      dailyValues: dailyValues, // dailyValuesを保持
    );
  }
  
  /// 習慣を再有効化します
  Habit activate() {
    return copyWith(
      isActive: true,
      updatedAt: DateTime.now(),
      dailyValues: dailyValues, // dailyValuesを保持
    );
  }
}
