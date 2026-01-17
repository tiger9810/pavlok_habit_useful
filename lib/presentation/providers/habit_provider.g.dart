// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeHabitsHash() => r'76cc6912964a85e676664448b3974207fda4d610';

/// 有効な習慣のみを取得するプロバイダー
///
/// Copied from [activeHabits].
@ProviderFor(activeHabits)
final activeHabitsProvider = AutoDisposeFutureProvider<List<Habit>>.internal(
  activeHabits,
  name: r'activeHabitsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeHabitsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveHabitsRef = AutoDisposeFutureProviderRef<List<Habit>>;
String _$habitByIdHash() => r'e20476863a347e28965436bbd831eaef2f2334f7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 特定のIDの習慣を取得するプロバイダー
///
/// Copied from [habitById].
@ProviderFor(habitById)
const habitByIdProvider = HabitByIdFamily();

/// 特定のIDの習慣を取得するプロバイダー
///
/// Copied from [habitById].
class HabitByIdFamily extends Family<AsyncValue<Habit?>> {
  /// 特定のIDの習慣を取得するプロバイダー
  ///
  /// Copied from [habitById].
  const HabitByIdFamily();

  /// 特定のIDの習慣を取得するプロバイダー
  ///
  /// Copied from [habitById].
  HabitByIdProvider call(String habitId) {
    return HabitByIdProvider(habitId);
  }

  @override
  HabitByIdProvider getProviderOverride(covariant HabitByIdProvider provider) {
    return call(provider.habitId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'habitByIdProvider';
}

/// 特定のIDの習慣を取得するプロバイダー
///
/// Copied from [habitById].
class HabitByIdProvider extends AutoDisposeFutureProvider<Habit?> {
  /// 特定のIDの習慣を取得するプロバイダー
  ///
  /// Copied from [habitById].
  HabitByIdProvider(String habitId)
    : this._internal(
        (ref) => habitById(ref as HabitByIdRef, habitId),
        from: habitByIdProvider,
        name: r'habitByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$habitByIdHash,
        dependencies: HabitByIdFamily._dependencies,
        allTransitiveDependencies: HabitByIdFamily._allTransitiveDependencies,
        habitId: habitId,
      );

  HabitByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.habitId,
  }) : super.internal();

  final String habitId;

  @override
  Override overrideWith(
    FutureOr<Habit?> Function(HabitByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HabitByIdProvider._internal(
        (ref) => create(ref as HabitByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        habitId: habitId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Habit?> createElement() {
    return _HabitByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HabitByIdProvider && other.habitId == habitId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, habitId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HabitByIdRef on AutoDisposeFutureProviderRef<Habit?> {
  /// The parameter `habitId` of this provider.
  String get habitId;
}

class _HabitByIdProviderElement extends AutoDisposeFutureProviderElement<Habit?>
    with HabitByIdRef {
  _HabitByIdProviderElement(super.provider);

  @override
  String get habitId => (origin as HabitByIdProvider).habitId;
}

String _$totalPointsHash() => r'01b2b65acb82dafea2e59185760385e7ddd3f624';

/// 総ポイントを取得するプロバイダー
///
/// Copied from [totalPoints].
@ProviderFor(totalPoints)
final totalPointsProvider = AutoDisposeFutureProvider<int>.internal(
  totalPoints,
  name: r'totalPointsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalPointsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalPointsRef = AutoDisposeFutureProviderRef<int>;
String _$habitNotifierHash() => r'e15281803bbb4dc43c02c23fefafc23090dbddda';

/// 習慣リストを管理するプロバイダー
///
/// すべての習慣の状態を管理し、CRUD操作を提供します。
///
/// Copied from [HabitNotifier].
@ProviderFor(HabitNotifier)
final habitNotifierProvider =
    AutoDisposeAsyncNotifierProvider<HabitNotifier, List<Habit>>.internal(
      HabitNotifier.new,
      name: r'habitNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$habitNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HabitNotifier = AutoDisposeAsyncNotifier<List<Habit>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
