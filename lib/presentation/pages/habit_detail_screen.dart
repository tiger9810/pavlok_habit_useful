import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:useful_pavlok/domain/entities/habit.dart';
import 'package:useful_pavlok/presentation/pages/habit_form_screen.dart';
import 'package:useful_pavlok/presentation/widgets/habit_calendar_view.dart';

/// 習慣詳細画面
/// 
/// 画像を参考にしたカレンダービューを表示します。
class HabitDetailScreen extends ConsumerWidget {
  final Habit habit;

  const HabitDetailScreen({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー（濃いグレー背景、ホーム画面と同じ）
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                habit.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HabitFormScreen(habit: habit),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // TODO: メニュー機能を実装
                  },
                ),
              ],
            ),
            
            // カレンダービュー
            Expanded(
              child: SingleChildScrollView(
                child: HabitCalendarView(habit: habit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
