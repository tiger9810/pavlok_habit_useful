/// 日付関連のユーティリティ関数
class AppDateUtils {
  /// 日付をキーとして使用するための文字列に変換します
  /// 
  /// [date] 変換する日付
  /// Returns "YYYY-MM-DD"形式の文字列
  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 日付キーからDateTimeに変換します
  /// 
  /// [key] "YYYY-MM-DD"形式の文字列
  /// Returns DateTimeオブジェクト
  static DateTime dateFromKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
  
  /// 2つの日付が同じ日かどうかを判定します
  /// 
  /// [date1] 比較する日付1
  /// [date2] 比較する日付2
  /// Returns 同じ日の場合true
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
  
  /// 指定された日付範囲内のすべての日付を生成します
  /// 
  /// [start] 開始日
  /// [end] 終了日
  /// Returns 日付のリスト
  static List<DateTime> daysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (current.isBefore(endDate) || isSameDay(current, endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }
  
  /// 今日の日付を取得します（時刻部分を0にリセット）
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  /// 指定された日数前の日付を取得します
  /// 
  /// [days] 何日前か
  /// Returns 日付
  static DateTime daysAgo(int days) {
    final today = AppDateUtils.today();
    return today.subtract(Duration(days: days));
  }
}
