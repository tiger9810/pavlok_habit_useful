import 'package:useful_pavlok/core/utils/date_utils.dart' as app_date_utils;
import 'package:useful_pavlok/domain/entities/habit.dart';

/// 習慣の達成状況を管理するヘルパークラス
class HabitCompletionHelper {
  /// 指定された日付の達成状況を取得します
  /// 
  /// [habit] 習慣
  /// [date] 確認する日付
  /// Returns 達成状況（null: 未記録、true: 達成、false: 失敗）
  static bool? getCompletionStatus(Habit habit, DateTime date) {
    if (habit.lastCompletedAt == null) {
      return null;
    }
    
    final lastCompleted = habit.lastCompletedAt!;
    final dateKey = app_date_utils.AppDateUtils.dateKey(date);
    final lastCompletedKey = app_date_utils.AppDateUtils.dateKey(lastCompleted);
    
    // 今日達成済みかどうか
    if (dateKey == lastCompletedKey) {
      return true;
    }
    
    // 連続達成日数から過去の達成日を推測
    if (habit.consecutiveDays > 0) {
      for (int i = 0; i < habit.consecutiveDays; i++) {
        final checkDate = lastCompleted.subtract(Duration(days: i));
        final checkKey = app_date_utils.AppDateUtils.dateKey(checkDate);
        if (checkKey == dateKey) {
          return true;
        }
      }
    }
    
    return null;
  }
  
  /// 指定された日付の数値進捗を取得します
  /// 
  /// [habit] 習慣
  /// [date] 確認する日付
  /// Returns 数値進捗（nullの場合は数値型ではない、または未記録）
  static double? getNumericProgress(Habit habit, DateTime date) {
    if (!habit.isNumeric || habit.unit == null) {
      return null;
    }
    
    // dailyValuesから日付キーで取得
    try {
      final dailyValues = habit.dailyValues;
      if (dailyValues.isEmpty) {
        return null;
      }
      
      final dateKey = app_date_utils.AppDateUtils.dateKey(date);
      return dailyValues[dateKey];
    } catch (e) {
      // dailyValuesがnullの場合やアクセスエラーの場合
      return null;
    }
  }
  
  /// 習慣が数値型かどうかを判定します
  /// 
  /// [habit] 習慣
  /// Returns 数値型の場合true
  static bool isNumericHabit(Habit habit) {
    return habit.isNumeric && habit.unit != null && habit.unit!.isNotEmpty;
  }
  
  /// 直近N日間の日付リストを取得します
  /// 
  /// [days] 日数（デフォルト: 5）
  /// Returns 日付のリスト（最新から古い順）
  static List<DateTime> getRecentDays({int days = 5}) {
    final today = app_date_utils.AppDateUtils.today();
    final dates = <DateTime>[];
    
    for (int i = 0; i < days; i++) {
      dates.add(today.subtract(Duration(days: i)));
    }
    
    return dates;
  }
}
