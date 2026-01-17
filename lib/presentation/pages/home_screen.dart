import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:useful_pavlok/core/utils/habit_completion_helper.dart';
import 'package:useful_pavlok/domain/entities/habit.dart';
import 'package:useful_pavlok/presentation/pages/habit_detail_screen.dart';
import 'package:useful_pavlok/presentation/pages/habit_form_screen.dart';
import 'package:useful_pavlok/presentation/providers/habit_provider.dart';
import 'package:useful_pavlok/presentation/widgets/numeric_input_dialog.dart';
import 'package:useful_pavlok/core/utils/date_utils.dart' as app_date_utils;

/// ホーム画面
/// 
/// 習慣のリストと直近5日間の達成状況を表示します。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // レイアウト定数（ヘッダーと行で共有）
  static const double _leftPadding = 16.0;
  static const double _circleSize = 10.0;
  static const double _circleGap = 10.0;
  static const double _titleAreaWidth = 130.0; // 円形パーツ + タイトル分
  static const double _dateColumnWidth = 50.0; // 各日のカラム幅
  static const double _rightPadding = 8.0;
  static const double _statusCellHeight = 44.0; // ステータスセルの高さ

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(context),
            
            // カレンダーヘッダー
            _buildCalendarHeader(context),
            
            // 習慣リスト
            Expanded(
              child: habitsAsync.when(
                data: (habits) {
                  final activeHabits = habits.where((h) => h.isActive).toList();
                  if (activeHabits.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '習慣がありません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '右上の+ボタンから習慣を追加してください',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: activeHabits.length,
                    separatorBuilder: (context, index) => Divider(
                      height: Theme.of(context).dividerTheme.space,
                      thickness: Theme.of(context).dividerTheme.thickness,
                      color: Theme.of(context).dividerTheme.color,
                    ),
                    itemBuilder: (context, index) {
                      return _HabitListItem(
                        habit: activeHabits[index],
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'エラーが発生しました',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.refresh(habitNotifierProvider),
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ヘッダーを構築します
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Habits',
            style: theme.appBarTheme.titleTextStyle,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.add, color: theme.appBarTheme.iconTheme?.color),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HabitFormScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: theme.appBarTheme.iconTheme?.color),
            onPressed: () {
              // TODO: フィルター機能を実装
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.appBarTheme.iconTheme?.color),
            onPressed: () {
              // TODO: メニュー機能を実装
            },
          ),
        ],
      ),
    );
  }

  /// カレンダーヘッダーを構築します
  Widget _buildCalendarHeader(BuildContext context) {
    final recentDays = HabitCompletionHelper.getRecentDays(days: 5);
    final theme = Theme.of(context);
    
    return Container(
      color: const Color(0xFFF5F5F5), // カレンダーヘッダーの背景色（薄いグレー）
      height: _statusCellHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: _leftPadding),
          // 習慣名のスペース（左端の円形パーツ + タイトル分）
          SizedBox(width: _titleAreaWidth),
          // 日付列（固定幅）
          ...recentDays.map((date) {
            final weekday = _getWeekdayAbbreviation(date.weekday);
            final day = date.day;
            
            return SizedBox(
              width: _dateColumnWidth,
              height: _statusCellHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekday,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$day',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(width: _rightPadding),
        ],
      ),
    );
  }

  /// 曜日の略称を取得します
  String _getWeekdayAbbreviation(int weekday) {
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return weekdays[weekday % 7];
  }
}

/// 習慣リストアイテム
class _HabitListItem extends ConsumerStatefulWidget {
  final Habit habit;

  const _HabitListItem({
    required this.habit,
  });

  @override
  ConsumerState<_HabitListItem> createState() => _HabitListItemState();
}

class _HabitListItemState extends ConsumerState<_HabitListItem> {
  @override
  Widget build(BuildContext context) {
    // 習慣の状態をリアクティブに監視
    final habitAsync = ref.watch(habitByIdProvider(widget.habit.id));
    
    return habitAsync.when(
      data: (habit) {
        if (habit == null) {
          return const SizedBox.shrink();
        }
        
        return _buildHabitRow(habit);
      },
      loading: () => _buildHabitRow(widget.habit),
      error: (error, stack) => _buildHabitRow(widget.habit),
    );
  }
  
  /// 習慣行を構築します
  Widget _buildHabitRow(Habit habit) {
    final recentDays = HabitCompletionHelper.getRecentDays(days: 5);
    final isNumeric = HabitCompletionHelper.isNumericHabit(habit);
    final habitColor = Color(habit.color);
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: HomeScreen._leftPadding, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左端: 習慣の色の円形パーツ
          Container(
            width: HomeScreen._circleSize,
            height: HomeScreen._circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: habitColor,
            ),
          ),
          SizedBox(width: HomeScreen._circleGap),
          
          // 中央: タイトル（タップ可能）
          SizedBox(
            width: HomeScreen._titleAreaWidth - HomeScreen._circleSize - HomeScreen._circleGap,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => HabitDetailScreen(habit: habit),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  habit.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          
          // 右側: 5日間のステータスグリッド（固定幅）
          ...recentDays.map((date) {
            return SizedBox(
              width: HomeScreen._dateColumnWidth,
              child: _buildStatusCell(habit, date, isNumeric, habitColor),
            );
          }),
          SizedBox(width: HomeScreen._rightPadding),
        ],
      ),
    );
  }

  /// ステータスセルを構築します
  Widget _buildStatusCell(Habit habit, DateTime date, bool isNumeric, Color habitColor) {
    final today = app_date_utils.AppDateUtils.today();
    final isToday = app_date_utils.AppDateUtils.isSameDay(date, today);
    
    final completionStatus = HabitCompletionHelper.getCompletionStatus(
      habit,
      date,
    );
    
    // 今日でない場合は操作不可（視覚的フィードバック用）
    final opacity = isToday ? 1.0 : 0.5;
    
    return GestureDetector(
      // 今日でない場合はタップイベントを無効化
      onTap: isToday
          ? () {
              if (isNumeric) {
                _showNumericInputDialog(date);
              } else {
                _toggleCompletion(date);
              }
            }
          : null,
      child: Container(
        height: HomeScreen._statusCellHeight,
        alignment: Alignment.center,
        child: Opacity(
          opacity: opacity,
          child: _buildStatusContent(habit, date, completionStatus, isNumeric, habitColor),
        ),
      ),
    );
  }
  
  /// 数値入力ダイアログを表示します
  Future<void> _showNumericInputDialog(DateTime date) async {
    // 今日でない場合はダイアログを表示しない
    final today = app_date_utils.AppDateUtils.today();
    final isToday = app_date_utils.AppDateUtils.isSameDay(date, today);
    
    if (!isToday) {
      return;
    }
    
    // 現在の習慣の状態を取得
    final habitAsync = ref.read(habitByIdProvider(widget.habit.id));
    final habit = await habitAsync.value;
    
    if (habit == null) return;
    
    final currentProgress = HabitCompletionHelper.getNumericProgress(
      habit,
      date,
    );
    
    await showDialog<void>(
      context: context,
      builder: (context) => NumericInputDialog(
        habitName: habit.name,
        unit: habit.unit ?? '',
        currentValue: currentProgress,
        onSave: (value) async {
          try {
            await ref.read(habitNotifierProvider.notifier).updateDailyValue(
              habit.id,
              date,
              value,
            );
            // 成功時のみダイアログを閉じる
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('エラーが発生しました: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            // エラー時はダイアログを閉じない（ユーザーが再試行できるように）
          }
        },
      ),
    );
  }

  /// ステータスの内容を構築します
  Widget _buildStatusContent(
    Habit habit,
    DateTime date,
    bool? completionStatus,
    bool isNumeric,
    Color habitColor,
  ) {
    if (isNumeric) {
      // 数値型の場合
      final progress = HabitCompletionHelper.getNumericProgress(
        habit,
        date,
      );
      
      final hasProgress = progress != null && progress > 0;
      final theme = Theme.of(context);
      final displayColor = hasProgress ? habitColor : theme.textTheme.labelSmall?.color ?? Colors.grey.shade400;
      
      if (habit.unit != null) {
        final formattedValue = progress != null && progress > 0
            ? (progress % 1 == 0
                ? progress.toInt().toString()
                : progress.toStringAsFixed(1))
            : '0';
        
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formattedValue,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: displayColor,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            habit.unit!,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: displayColor,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
      } else {
        final theme = Theme.of(context);
        return Text(
          '0',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
          ),
        );
      }
    } else {
      // チェックボックス型の場合
      if (completionStatus == true) {
        return Text(
          '✓',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: habitColor,
          ),
        );
      } else {
        final theme = Theme.of(context);
        return Text(
          '×',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        );
      }
    }
  }

  /// 達成状況を切り替えます
  Future<void> _toggleCompletion(DateTime date) async {
    // 今日でない場合は何もしない（タップイベント自体が無効化されているため、ここに到達することはないが、念のため）
    final today = app_date_utils.AppDateUtils.today();
    final isToday = app_date_utils.AppDateUtils.isSameDay(date, today);
    
    if (!isToday) {
      return;
    }
    
    // 現在の習慣の状態を取得
    final habitAsync = ref.read(habitByIdProvider(widget.habit.id));
    final habit = await habitAsync.value;
    if (habit == null) return;
    
    final completionStatus = HabitCompletionHelper.getCompletionStatus(
      habit,
      date,
    );
    
    try {
      if (completionStatus == true) {
        // 未達成に変更
        await ref.read(habitNotifierProvider.notifier).incompleteHabit(
          habit.id,
          date,
        );
      } else {
        // 達成に変更
        await ref.read(habitNotifierProvider.notifier).completeHabit(
          habit.id,
          date,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
