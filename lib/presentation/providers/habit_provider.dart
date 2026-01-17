import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:useful_pavlok/core/utils/date_utils.dart' as app_date_utils;
import 'package:useful_pavlok/domain/entities/habit.dart';

part 'habit_provider.g.dart';

/// 習慣リストを管理するプロバイダー
/// 
/// すべての習慣の状態を管理し、CRUD操作を提供します。
@riverpod
class HabitNotifier extends _$HabitNotifier {
  @override
  Future<List<Habit>> build() async {
    // TODO: リポジトリから習慣リストを取得
    // return ref.read(habitRepositoryProvider).getAllHabits();
    return [];
  }
  
  /// 新しい習慣を追加します
  /// 
  /// [habit] 追加する習慣
  Future<void> addHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentHabits = state.value ?? <Habit>[];
      // TODO: リポジトリに保存
      // await ref.read(habitRepositoryProvider).saveHabit(habit);
      return [...currentHabits, habit];
    });
  }
  
  /// 習慣を更新します
  /// 
  /// [habit] 更新する習慣
  Future<void> updateHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentHabits = state.value ?? [];
      // TODO: リポジトリに保存
      // await ref.read(habitRepositoryProvider).updateHabit(habit);
      return currentHabits.map((h) => h.id == habit.id ? habit : h).toList();
    });
  }
  
  /// 習慣を削除します
  /// 
  /// [habitId] 削除する習慣のID
  Future<void> deleteHabit(String habitId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentHabits = state.value ?? [];
      // TODO: リポジトリから削除
      // await ref.read(habitRepositoryProvider).deleteHabit(habitId);
      return currentHabits.where((h) => h.id != habitId).toList();
    });
  }
  
  /// 習慣を達成としてマークします
  /// 
  /// [habitId] 達成する習慣のID
  /// [completedAt] 達成日時（デフォルト: DateTime.now()）
  Future<void> completeHabit(String habitId, [DateTime? completedAt]) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentHabits = state.value ?? [];
      final habit = currentHabits.firstWhere((h) => h.id == habitId);
      final updatedHabit = habit.markAsCompleted(completedAt);
      // TODO: リポジトリに保存
      // await ref.read(habitRepositoryProvider).updateHabit(updatedHabit);
      return currentHabits.map((h) => h.id == habitId ? updatedHabit : h).toList();
    });
  }
  
  /// 習慣を未達成としてマークします（ストイックモード用）
  /// 
  /// [habitId] 未達成とする習慣のID
  /// [checkedAt] チェック日時（デフォルト: DateTime.now()）
  Future<void> incompleteHabit(String habitId, [DateTime? checkedAt]) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentHabits = state.value ?? [];
      final habit = currentHabits.firstWhere((h) => h.id == habitId);
      final updatedHabit = habit.markAsIncomplete(checkedAt);
      // TODO: リポジトリに保存
      // await ref.read(habitRepositoryProvider).updateHabit(updatedHabit);
      return currentHabits.map((h) => h.id == habitId ? updatedHabit : h).toList();
    });
  }
  
  /// 習慣を無効化します
  /// 
  /// [habitId] 無効化する習慣のID
  Future<void> deactivateHabit(String habitId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentHabits = state.value ?? [];
      final habit = currentHabits.firstWhere((h) => h.id == habitId);
      final updatedHabit = habit.deactivate();
      // TODO: リポジトリに保存
      // await ref.read(habitRepositoryProvider).updateHabit(updatedHabit);
      return currentHabits.map((h) => h.id == habitId ? updatedHabit : h).toList();
    });
  }
  
  /// 習慣を再有効化します
  /// 
  /// [habitId] 再有効化する習慣のID
  Future<void> activateHabit(String habitId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentHabits = state.value ?? [];
      final habit = currentHabits.firstWhere((h) => h.id == habitId);
      final updatedHabit = habit.activate();
      // TODO: リポジトリに保存
      // await ref.read(habitRepositoryProvider).updateHabit(updatedHabit);
      return currentHabits.map((h) => h.id == habitId ? updatedHabit : h).toList();
    });
  }
  
  /// 習慣リストをリフレッシュします
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // TODO: リポジトリから再取得
      // return ref.read(habitRepositoryProvider).getAllHabits();
      return state.value ?? [];
    });
  }
  
  /// 数値型習慣の日別進捗を更新します
  /// 
  /// [habitId] 習慣のID
  /// [date] 更新する日付
  /// [value] 進捗値
  Future<void> updateDailyValue(String habitId, DateTime date, double value) async {
    state = await AsyncValue.guard(() async {
      final currentHabits = state.value ?? [];
      final habit = currentHabits.firstWhere((h) => h.id == habitId);
      
      // 日付キーを取得
      final dateKey = app_date_utils.AppDateUtils.dateKey(date);
      
      // dailyValuesを更新（nullチェック）
      final currentDailyValues = habit.dailyValues;
      final updatedDailyValues = Map<String, double>.from(currentDailyValues);
      if (value > 0) {
        updatedDailyValues[dateKey] = value;
      } else {
        updatedDailyValues.remove(dateKey);
      }
      
      // まずdailyValuesを更新したHabitを作成
      final habitWithUpdatedValues = habit.copyWith(
        dailyValues: updatedDailyValues,
      );
      
      // 進捗が目標値以上の場合、達成としてマーク
      Habit updatedHabit;
      if (habit.target != null && value >= habit.target!) {
        updatedHabit = habitWithUpdatedValues.markAsCompleted(date);
      } else if (value > 0) {
        // 進捗があるが目標未達の場合は、達成としてマーク（部分達成）
        updatedHabit = habitWithUpdatedValues.markAsCompleted(date);
      } else {
        // 進捗が0の場合は未達成としてマーク
        updatedHabit = habitWithUpdatedValues.markAsIncomplete(date);
      }
      
      // TODO: リポジトリに保存
      // await ref.read(habitRepositoryProvider).updateHabit(updatedHabit);
      
      // 新しいリストを作成してstateを更新（リアクティブな更新）
      return currentHabits.map((h) => h.id == habitId ? updatedHabit : h).toList();
    });
  }
}

/// 有効な習慣のみを取得するプロバイダー
@riverpod
Future<List<Habit>> activeHabits(ActiveHabitsRef ref) async {
  final allHabits = await ref.watch(habitNotifierProvider.future);
  return allHabits.where((habit) => habit.isActive).toList();
}

/// 特定のIDの習慣を取得するプロバイダー
@riverpod
Future<Habit?> habitById(HabitByIdRef ref, String habitId) async {
  final allHabits = await ref.watch(habitNotifierProvider.future);
  try {
    return allHabits.firstWhere((habit) => habit.id == habitId);
  } catch (e) {
    return null;
  }
}

/// 総ポイントを取得するプロバイダー
@riverpod
Future<int> totalPoints(TotalPointsRef ref) async {
  final allHabits = await ref.watch(habitNotifierProvider.future);
  return allHabits.fold<int>(0, (int sum, Habit habit) => sum + habit.points);
}
