import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:useful_pavlok/core/utils/habit_completion_helper.dart';
import 'package:useful_pavlok/core/utils/date_utils.dart' as app_date_utils;
import 'package:useful_pavlok/domain/entities/habit.dart';
import 'package:useful_pavlok/presentation/pages/habit_form_screen.dart';

/// 習慣のカレンダービュー
/// 
/// GitHubのコントリビューショングラフのようなシームレスなヒートマップです。
/// 縦軸：曜日（Sun-Sat）、横軸：週（Weeks）
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
  /// 横スクロール用のScrollController
  late ScrollController _scrollController;
  
  /// 表示する週数（デフォルト: 約6ヶ月分 = 26週）
  static const int _weeksToShow = 26;
  
  /// セルのサイズ
  static const double _cellSize = 32.0;
  
  /// セル間のスペース
  static const double _cellSpacing = 3.0;
  
  /// 月ラベルの高さ
  static const double _monthLabelHeight = 20.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // スクロール位置が利用可能になったら自動スクロール
    _scrollController.addListener(() {
      // リスナーはスクロール位置の変更を監視するため、ここでは何もしない
    });
    
    // ウィジェットが構築された後にスクロール位置を設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 少し遅延を入れてレイアウトが完全に完了してからスクロール
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollToCurrentWeek();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  /// 最新の週（今日を含む週）までスクロールします
  /// 画面の右端に最新の週が表示されるようにします
  void _scrollToCurrentWeek() {
    if (!_scrollController.hasClients) return;
    
    // スクロール可能な範囲の最大値までスクロール（右端）
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    
    // 右端までスクロール（最新の週が表示される）
    if (maxScrollExtent > 0) {
      _scrollController.jumpTo(maxScrollExtent);
    }
  }

  /// 表示する日付のリストを取得します（週ごとに整理）
  /// 返り値: [週0の日曜, 週0の月曜, ..., 週0の土曜, 週1の日曜, ...]
  /// 必ず今日を含む最新の週の土曜日まで表示します
  List<DateTime> _getDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 今日を含む週の日曜日を取得
    final todaySunday = _getSundayOfWeek(today);
    
    // 最初の週の日曜日を取得（_weeksToShow週前）
    final firstSunday = _getSundayOfWeek(today.subtract(Duration(days: _weeksToShow * 7)));
    
    // 今日を含む週の土曜日まで含める必要がある
    final lastSaturday = todaySunday.add(const Duration(days: 6));
    
    final dates = <DateTime>[];
    var currentDate = firstSunday;
    
    // 今日を含む週の土曜日まで含めて生成
    while (currentDate.isBefore(lastSaturday) || app_date_utils.AppDateUtils.isSameDay(currentDate, lastSaturday)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return dates;
  }
  
  /// 指定された日付が含まれる週の日曜日を取得します
  DateTime _getSundayOfWeek(DateTime date) {
    final weekday = date.weekday % 7; // 0=Sun, 6=Sat
    return date.subtract(Duration(days: weekday));
  }
  
  /// 月のラベルを取得します
  String _getMonthLabel(DateTime date) {
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
    
    final monthName = months[date.month - 1];
    final year = date.year;
    final now = DateTime.now();
    
    // 現在の年と同じ場合は年を省略、それ以外は年を表示
    if (year == now.year) {
      return monthName;
    } else {
      return '$monthName $year';
    }
  }
  
  /// 月ラベルの位置情報を取得します
  /// 返り値: Map<週のインデックス, 月のラベル>
  Map<int, String> _getMonthLabels() {
    final dates = _getDates();
    final monthLabels = <int, String>{};
    int? lastMonth;
    
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final currentMonth = date.month;
      final weekIndex = i ~/ 7;
      
      // 月が変わった最初の日（1日）が含まれる週を検出
      if (date.day == 1) {
        // その週のインデックスを取得（まだ登録されていない場合のみ）
        if (!monthLabels.containsKey(weekIndex)) {
          monthLabels[weekIndex] = _getMonthLabel(date);
        }
        lastMonth = currentMonth;
      } else if (lastMonth != null && currentMonth != lastMonth) {
        // 月が変わった最初の日が含まれる週
        if (!monthLabels.containsKey(weekIndex)) {
          monthLabels[weekIndex] = _getMonthLabel(date);
        }
        lastMonth = currentMonth;
      } else if (lastMonth == null) {
        // 最初の月
        lastMonth = currentMonth;
        // 最初の日が含まれる週にラベルを追加
        if (date.day == 1) {
          monthLabels[weekIndex] = _getMonthLabel(date);
        }
      }
    }
    
    return monthLabels;
  }
  
  /// 日付セルの色を取得します
  Color _getCellColor(DateTime date) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final cellDate = DateTime(date.year, date.month, date.day);
    
    // 未来の日付
    if (cellDate.isAfter(todayDate)) {
      return Colors.grey.shade100; // 非常に薄いグレー
    }
    
    // 達成状況を取得
    final completionStatus = HabitCompletionHelper.getCompletionStatus(
      widget.habit,
      date,
    );
    
    if (completionStatus == true) {
      // 達成した日：習慣のメインカラー
      return Color(widget.habit.color);
    } else {
      // 未達成の日：非常に薄いグレー
      return Colors.grey.shade200;
    }
  }
  
  /// 日付セルのテキスト色を取得します
  Color _getCellTextColor(DateTime date) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final cellDate = DateTime(date.year, date.month, date.day);
    
    // 未来の日付
    if (cellDate.isAfter(todayDate)) {
      return Colors.grey.shade300;
    }
    
    // 達成状況を取得
    final completionStatus = HabitCompletionHelper.getCompletionStatus(
      widget.habit,
      date,
    );
    
    if (completionStatus == true) {
      // 達成した日：白文字
      return Colors.white;
    } else {
      // 未達成の日：グレーの文字
      return Colors.grey.shade700;
    }
  }
  
  /// 日付セルを構築します
  Widget _buildDateCell(DateTime date, int index) {
    final cellColor = _getCellColor(date);
    final textColor = _getCellTextColor(date);
    
    // 今日かどうかを判定
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cellDate = DateTime(date.year, date.month, date.day);
    final isToday = app_date_utils.AppDateUtils.isSameDay(cellDate, today);
    
    // 達成状況を取得（枠線の色を決定するため）
    final completionStatus = HabitCompletionHelper.getCompletionStatus(
      widget.habit,
      date,
    );
    
    // 今日のセルの枠線の色を決定
    // 達成済み（習慣のメインカラーで塗りつぶされている）場合は白い枠線
    // 未達成の場合は習慣のメインカラーの枠線
    final borderColor = isToday
        ? (completionStatus == true ? Colors.white : Color(widget.habit.color))
        : null;
    
    return Container(
      width: _cellSize,
      height: _cellSize,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(4),
        // 今日のセルには枠線を追加
        border: isToday
            ? Border.all(
                color: borderColor!,
                width: 2.0,
              )
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 日付の数字
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          // 今日のセルには習慣のメインカラーでドットを追加（数字の下）
          // 達成済みの場合は白いドット、未達成の場合は習慣のメインカラーのドット
          if (isToday)
            Positioned(
              bottom: 4,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: completionStatus == true
                      ? Colors.white
                      : Color(widget.habit.color),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getDates();
    final monthLabels = _getMonthLabels();
    final theme = Theme.of(context);
    // 実際の日付数に基づいて週数を計算（7で割って切り上げ）
    final weeksCount = (dates.length / 7).ceil();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 「Calendar」見出し
          Text(
            'Calendar',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // ヒートマップグリッド
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヒートマップ（横スクロール可能）
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 月ラベルのヘッダー
                      SizedBox(
                        height: _monthLabelHeight,
                        width: weeksCount * (_cellSize + _cellSpacing),
                        child: Stack(
                          children: monthLabels.entries.map((entry) {
                            final weekIndex = entry.key;
                            final monthLabel = entry.value;
                            
                            return Positioned(
                              left: weekIndex * (_cellSize + _cellSpacing),
                              child: Text(
                                monthLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // ヒートマップグリッド
                      SizedBox(
                        height: _cellSize * 7 + _cellSpacing * 6,
                        width: weeksCount * (_cellSize + _cellSpacing),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(weeksCount, (weekIndex) {
                            return SizedBox(
                              width: _cellSize + _cellSpacing,
                              height: _cellSize * 7 + _cellSpacing * 6,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(7, (dayIndex) {
                                  final dateIndex = weekIndex * 7 + dayIndex;
                                  if (dateIndex >= dates.length) {
                                    return SizedBox(
                                      width: _cellSize,
                                      height: _cellSize,
                                    );
                                  }
                                  final date = dates[dateIndex];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: dayIndex < 6 ? _cellSpacing : 0,
                                    ),
                                    child: _buildDateCell(date, dateIndex),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 右側の曜日ラベル
              Column(
                mainAxisSize: MainAxisSize.min,
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .asMap()
                    .entries
                    .map((entry) {
                  final dayIndex = entry.key;
                  final day = entry.value;
                  
                  return Container(
                    height: _cellSize,
                    width: 40,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    margin: EdgeInsets.only(
                      bottom: dayIndex < 6 ? _cellSpacing : 0,
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => HabitFormScreen(habit: widget.habit),
                  ),
                );
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
