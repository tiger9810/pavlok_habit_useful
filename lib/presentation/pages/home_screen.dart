import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:useful_pavlok/core/constants/layout_constants.dart';
import 'package:useful_pavlok/core/utils/habit_completion_helper.dart';
import 'package:useful_pavlok/presentation/pages/habit_form_screen.dart';
import 'package:useful_pavlok/presentation/pages/pavlok_settings_screen.dart';
import 'package:useful_pavlok/presentation/providers/habit_provider.dart';
import 'package:useful_pavlok/presentation/widgets/empty_habit_list.dart';
import 'package:useful_pavlok/presentation/widgets/error_state.dart';
import 'package:useful_pavlok/presentation/widgets/habit_list_item.dart';

/// ホーム画面
/// 
/// 習慣のリストと直近5日間の達成状況を表示します。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
                    return const EmptyHabitList();
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
                      return HabitListItem(
                        habit: activeHabits[index],
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => ErrorState(
                  retryProvider: habitNotifierProvider,
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
            icon: Icon(Icons.watch, color: theme.appBarTheme.iconTheme?.color),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PavlokSettingsScreen(),
                ),
              );
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
      height: LayoutConstants.homeStatusCellHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: LayoutConstants.homeLeftPadding),
          // 習慣名のスペース（左端の円形パーツ + タイトル分）
          SizedBox(width: LayoutConstants.homeTitleAreaWidth),
          // 日付列（固定幅）
          ...recentDays.map((date) {
            final weekday = _getWeekdayAbbreviation(date.weekday);
            final day = date.day;
            
            return SizedBox(
              width: LayoutConstants.homeDateColumnWidth,
              height: LayoutConstants.homeStatusCellHeight,
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
          SizedBox(width: LayoutConstants.homeRightPadding),
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
