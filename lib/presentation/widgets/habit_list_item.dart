import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:useful_pavlok/core/constants/layout_constants.dart';
import 'package:useful_pavlok/core/utils/habit_completion_helper.dart';
import 'package:useful_pavlok/core/utils/date_utils.dart' as app_date_utils;
import 'package:useful_pavlok/domain/entities/habit.dart';
import 'package:useful_pavlok/presentation/pages/habit_detail_screen.dart';
import 'package:useful_pavlok/presentation/providers/habit_provider.dart';
import 'package:useful_pavlok/presentation/widgets/numeric_input_dialog.dart';

/// 習慣リストアイテム
class HabitListItem extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitListItem({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<HabitListItem> createState() => _HabitListItemState();
}

class _HabitListItemState extends ConsumerState<HabitListItem> {
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
      padding: const EdgeInsets.symmetric(
        horizontal: LayoutConstants.homeLeftPadding,
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左端: 習慣の色の円形パーツ
          Container(
            width: LayoutConstants.homeCircleSize,
            height: LayoutConstants.homeCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: habitColor,
            ),
          ),
          SizedBox(width: LayoutConstants.homeCircleGap),
          
          // 中央: タイトル（タップ可能）
          SizedBox(
            width: LayoutConstants.homeTitleAreaWidth -
                LayoutConstants.homeCircleSize -
                LayoutConstants.homeCircleGap,
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
              width: LayoutConstants.homeDateColumnWidth,
              child: _buildStatusCell(habit, date, isNumeric, habitColor),
            );
          }),
          SizedBox(width: LayoutConstants.homeRightPadding),
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
        height: LayoutConstants.homeStatusCellHeight,
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
    final habit = habitAsync.value;
    
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
      final displayColor = hasProgress
          ? habitColor
          : theme.textTheme.labelSmall?.color ?? Colors.grey.shade400;
      
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
    // 今日でない場合は何もしない
    final today = app_date_utils.AppDateUtils.today();
    final isToday = app_date_utils.AppDateUtils.isSameDay(date, today);
    
    if (!isToday) {
      return;
    }
    
    // 現在の習慣の状態を取得
    final habitAsync = ref.read(habitByIdProvider(widget.habit.id));
    final habit = habitAsync.value;
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
