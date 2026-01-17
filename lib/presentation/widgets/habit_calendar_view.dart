import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:useful_pavlok/core/utils/habit_completion_helper.dart';
import 'package:useful_pavlok/domain/entities/habit.dart';

/// 習慣のカレンダービュー
/// 
/// 画像を参考にした複数月表示のカレンダーです。
/// 達成日はダークピンク、未達成日はライトグレーで表示されます。
class HabitCalendarView extends ConsumerStatefulWidget {
  /// 表示する習慣
  final Habit habit;

  const HabitCalendarView({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<HabitCalendarView> createState() => _HabitCalendarViewState();
}

class _HabitCalendarViewState extends ConsumerState<HabitCalendarView> {
  /// 表示する開始月（デフォルト: 5ヶ月前）
  late DateTime _startMonth;
  
  /// 表示する終了月（デフォルト: 今月）
  late DateTime _endMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endMonth = DateTime(now.year, now.month);
    // 5ヶ月分表示（現在の月を含む）
    _startMonth = DateTime(now.year, now.month - 4);
  }

  /// 表示する月のリストを取得します
  List<DateTime> _getMonths() {
    final months = <DateTime>[];
    var current = DateTime(_startMonth.year, _startMonth.month);
    final end = DateTime(_endMonth.year, _endMonth.month);
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      months.add(current);
      if (current.month == 12) {
        current = DateTime(current.year + 1, 1);
      } else {
        current = DateTime(current.year, current.month + 1);
      }
    }
    
    return months;
  }

  /// 指定された月のカレンダーグリッドを構築します
  Widget _buildMonthCalendar(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDay.weekday % 7; // 0=Sun, 6=Sat
    
    // 月の最初の日曜日を取得
    final startDate = firstDay.subtract(Duration(days: firstWeekday));
    
    // カレンダーの行数（最大6週間）
    final weeks = <List<DateTime>>[];
    var currentDate = startDate;
    
    // 6週間分のデータを生成
    for (int weekIndex = 0; weekIndex < 6; weekIndex++) {
      final week = <DateTime>[];
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        week.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月のヘッダー
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _getMonthLabel(month),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        // カレンダーグリッド
        ...weeks.map((week) => Row(
          children: week.map((date) {
            final isCurrentMonth = date.month == month.month;
            final completionStatus = HabitCompletionHelper.getCompletionStatus(
              widget.habit,
              date,
            );
            
            return Expanded(
              child: _buildDateCell(date, isCurrentMonth, completionStatus),
            );
          }).toList(),
        )),
      ],
    );
  }

  /// 日付セルを構築します
  Widget _buildDateCell(
    DateTime date,
    bool isCurrentMonth,
    bool? completionStatus,
  ) {
    final isCompleted = completionStatus == true;
    
    // 習慣の色を使用（デフォルトはピンク）
    final habitColor = Color(widget.habit.color);
    // ピンク系の色の場合はダークピンクを使用、それ以外は習慣の色を濃くしたもの
    final completedColor = habitColor.value == 0xFFE91E63 
        ? Colors.pink.shade700 
        : habitColor.withOpacity(0.8);
    
    return Container(
      margin: const EdgeInsets.all(1),
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted
            ? completedColor // 達成日はダークピンクまたは習慣の色
            : Colors.grey.shade200, // 未達成日はライトグレー
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isCompleted
                ? Colors.white
                : (isCurrentMonth ? Colors.grey.shade800 : Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  /// 月のラベルを取得します
  String _getMonthLabel(DateTime month) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    
    final monthName = months[month.month - 1];
    final year = month.year;
    final now = DateTime.now();
    
    // 現在の年と同じ場合は年を省略
    if (year == now.year) {
      return monthName;
    } else {
      return '$monthName $year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = _getMonths();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 「Calendar」見出し
          Text(
            'Calendar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade700, // ダークピンク
            ),
          ),
          
          const SizedBox(height: 16),
          
          // カレンダーグリッド
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 月のカレンダー（横スクロール可能）
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: months.map((month) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: SizedBox(
                          width: 180,
                          child: _buildMonthCalendar(month),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 右側の曜日ラベル
              Column(
                mainAxisSize: MainAxisSize.min,
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) {
                  return Container(
                    height: 32,
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // EDITボタン
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: 編集機能を実装
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'EDIT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
