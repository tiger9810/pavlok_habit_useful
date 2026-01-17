import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:useful_pavlok/core/utils/date_utils.dart' as app_date_utils;
import 'package:useful_pavlok/domain/entities/habit.dart';

/// 習慣の達成状況をヒートマップ形式で表示するウィジェット
/// 
/// 達成日は黄色、失敗日はグレーで表示されます。
/// モダンで清潔感のあるデザインを採用しています。
class HabitHeatmapView extends ConsumerStatefulWidget {
  /// 表示する習慣
  final Habit habit;
  
  /// 表示する期間の開始日（デフォルト: 6ヶ月前）
  final DateTime? startDate;
  
  /// 表示する期間の終了日（デフォルト: 今日）
  final DateTime? endDate;

  const HabitHeatmapView({
    super.key,
    required this.habit,
    this.startDate,
    this.endDate,
  });

  @override
  ConsumerState<HabitHeatmapView> createState() => _HabitHeatmapViewState();
}

class _HabitHeatmapViewState extends ConsumerState<HabitHeatmapView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _startDate;
  late DateTime _endDate;
  
  /// 達成日のセット（日付キー形式）
  final Set<String> _completedDates = {};
  
  /// 失敗日のセット（日付キー形式）
  final Set<String> _failedDates = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _endDate = widget.endDate ?? app_date_utils.AppDateUtils.today();
    _startDate = widget.startDate ?? app_date_utils.AppDateUtils.daysAgo(180); // 6ヶ月前
    
    _loadCompletionHistory();
  }

  /// 達成履歴を読み込みます
  /// 
  /// 現在の実装では、`lastCompletedAt`と`consecutiveDays`から
  /// 達成日を推測します。将来的には履歴リストから直接取得する予定です。
  void _loadCompletionHistory() {
    if (widget.habit.lastCompletedAt == null) {
      return;
    }
    
    final lastCompleted = widget.habit.lastCompletedAt!;
    final consecutiveDays = widget.habit.consecutiveDays;
    
    // 連続達成日数から過去の達成日を推測
    for (int i = 0; i < consecutiveDays; i++) {
      final date = lastCompleted.subtract(Duration(days: i));
      if (date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(_endDate.add(const Duration(days: 1)))) {
        _completedDates.add(app_date_utils.AppDateUtils.dateKey(date));
      }
    }
    
    // 今日が達成済みの場合
    if (widget.habit.isCompletedToday()) {
      _completedDates.add(app_date_utils.AppDateUtils.dateKey(app_date_utils.AppDateUtils.today()));
    }
    
    // ストイックモードの場合、失敗日も記録
    // 注意: 現在の実装では失敗日を正確に追跡できないため、
    // 将来的に履歴リストを追加する必要があります
  }

  /// 指定された日付の達成状況を取得します
  /// 
  /// [day] 確認する日付
  /// Returns 達成状況（null: 未記録、true: 達成、false: 失敗）
  bool? _getCompletionStatus(DateTime day) {
    final key = app_date_utils.AppDateUtils.dateKey(day);
    
    if (_completedDates.contains(key)) {
      return true;
    }
    
    if (_failedDates.contains(key)) {
      return false;
    }
    
    return null;
  }

  /// 日付セルのスタイルを取得します
  /// 
  /// [day] 日付
  /// [isSelected] 選択されているか
  /// [isToday] 今日かどうか
  /// [isOutsideMonth] 表示月の外かどうか
  /// Returns セルのスタイル
  BoxDecoration _getCellDecoration(
    DateTime day,
    bool isSelected,
    bool isToday,
    bool isOutsideMonth,
  ) {
    final completionStatus = _getCompletionStatus(day);
    
    // 月の外の日は透明
    if (isOutsideMonth) {
      return BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      );
    }
    
    // 達成日は黄色
    if (completionStatus == true) {
      return BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.yellow.shade400,
        border: isSelected
            ? Border.all(color: Colors.blue.shade600, width: 2)
            : null,
      );
    }
    
    // 失敗日はグレー
    if (completionStatus == false) {
      return BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade400,
        border: isSelected
            ? Border.all(color: Colors.blue.shade600, width: 2)
            : null,
      );
    }
    
    // 未記録の日は薄いグレー
    return BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey.shade200,
      border: isToday
          ? Border.all(color: Colors.blue.shade300, width: 1.5)
          : isSelected
              ? Border.all(color: Colors.blue.shade600, width: 2)
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900, // ダークグレーの背景
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトルと統計情報
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade300,
                  ),
                ),
                Row(
                  children: [
                    // 達成日の凡例
                    _buildLegendItem(
                      color: Colors.yellow.shade400,
                      label: '達成',
                    ),
                    const SizedBox(width: 16),
                    // 失敗日の凡例
                    _buildLegendItem(
                      color: Colors.grey.shade400,
                      label: '失敗',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // カレンダー
          TableCalendar<bool>(
            firstDay: _startDate,
            lastDay: _endDate,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => app_date_utils.AppDateUtils.isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            // 複数月表示を有効化
            sixWeekMonthsEnforced: false,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              weekendTextStyle: TextStyle(color: Colors.grey.shade400),
              defaultTextStyle: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 12,
              ),
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade600,
              ),
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade300,
              ),
              markerDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              // カスタムセルビルダーを使用
              cellMargin: const EdgeInsets.all(2),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.pink.shade300, // ピンクのタイトル
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Colors.grey.shade400,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              weekendStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            // カスタムビルダーでセルの色を設定
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) {
                final isSelected = app_date_utils.AppDateUtils.isSameDay(date, _selectedDay);
                final isToday = app_date_utils.AppDateUtils.isSameDay(date, app_date_utils.AppDateUtils.today());
                final isOutsideMonth = date.month != _focusedDay.month;
                
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: _getCellDecoration(
                    date,
                    isSelected,
                    isToday,
                    isOutsideMonth,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getCompletionStatus(date) == true
                            ? Colors.grey.shade800
                            : Colors.grey.shade600,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
              selectedBuilder: (context, date, _) {
                final isToday = app_date_utils.AppDateUtils.isSameDay(date, app_date_utils.AppDateUtils.today());
                final isOutsideMonth = date.month != _focusedDay.month;
                
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: _getCellDecoration(
                    date,
                    true,
                    isToday,
                    isOutsideMonth,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              todayBuilder: (context, date, _) {
                final isSelected = app_date_utils.AppDateUtils.isSameDay(date, _selectedDay);
                final isOutsideMonth = date.month != _focusedDay.month;
                
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: _getCellDecoration(
                    date,
                    isSelected,
                    true,
                    isOutsideMonth,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getCompletionStatus(date) == true
                            ? Colors.grey.shade800
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 統計情報
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: '連続達成',
                  value: '${widget.habit.consecutiveDays}日',
                ),
                _buildStatItem(
                  label: '総達成回数',
                  value: '${widget.habit.totalCompletions}回',
                ),
                _buildStatItem(
                  label: '獲得ポイント',
                  value: '${widget.habit.points}pt',
                ),
              ],
            ),
          ),
          
          // EDITボタン
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // TODO: 編集機能を実装
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.transparent,
                ),
                child: const Text(
                  'EDIT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 凡例アイテムを構築します
  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// 統計アイテムを構築します
  Widget _buildStatItem({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
