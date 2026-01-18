import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:useful_pavlok/data/services/pavlok_ble_service.dart';

part 'pavlok_provider.g.dart';

/// Pavlokデバイスの接続状態と設定を管理するプロバイダー
@riverpod
class PavlokNotifier extends _$PavlokNotifier {
  @override
  Future<PavlokState> build() async {
    // 初期状態を返す（未接続）
    return const PavlokState(
      isConnected: false,
      deviceName: null,
      deviceModel: null,
      batteryLevel: null,
      shockIntensity: 10,
      alarmIntensity: 50,
      vibrateIntensity: 5,
      discoveredDevices: [],
      isScanning: false,
    );
  }

  /// Pavlokデバイスをスキャンします
  /// 
  /// 見つかったデバイスは状態に保存され、UIにリアルタイムで通知されます。
  Future<void> scanForDevices() async {
    final currentState = state.value;
    if (currentState == null) return;

    // スキャン中状態に更新
    state = AsyncValue.data(
      currentState.copyWith(
        isScanning: true,
        discoveredDevices: [],
      ),
    );

    List<BluetoothDevice> devices = [];
    
    try {
      final bleService = PavlokBleService();

      // Bluetoothが有効か確認
      if (!await bleService.isBluetoothEnabled()) {
        throw Exception('Bluetoothが有効になっていません');
      }

      // Pavlokデバイスをスキャン（Service UUIDでフィルタリング）
      final scanResults = await bleService.scanForPavlokDevices(
        timeout: const Duration(seconds: 10),
      );

      // 見つかったデバイスのリストを取得（重複排除）
      final Set<String> seenDeviceIds = {};

      for (final scanResult in scanResults) {
        final deviceId = scanResult.device.remoteId.toString();
        // 重複を避ける（Setで管理）
        if (!seenDeviceIds.contains(deviceId)) {
          seenDeviceIds.add(deviceId);
          devices.add(scanResult.device);
        }
      }

      print('[PavlokProvider] スキャン完了: ${devices.length}台のPavlok 3デバイスを発見（重複排除後）');
      for (int i = 0; i < devices.length; i++) {
        final device = devices[i];
        final deviceId = device.remoteId.toString();
        final deviceIdPrefix = deviceId.length >= 4 
            ? deviceId.substring(0, 4).toUpperCase()
            : deviceId.toUpperCase();
        print('[PavlokProvider]   デバイス #${i + 1}: Pavlok 3 (PAVLOK-3-$deviceIdPrefix)');
      }
    } catch (e) {
      print('[PavlokProvider] スキャンエラー: $e');
      print('[PavlokProvider] エラータイプ: ${e.runtimeType}');
      // エラー時もデバイスリストは空のまま
      devices = [];
    } finally {
      // スキャン完了時（成功・失敗・タイムアウト問わず）に必ずisScanningをfalseに設定
      // これにより、タイムアウト後も確実にローディング画面から設定画面に戻る
      print('[PavlokProvider] [FINALLY] finallyブロックを実行します');
      print('[PavlokProvider] 現在の状態: isScanning=${currentState.isScanning}, discoveredDevices=${devices.length}台');
      
      final updatedState = currentState.copyWith(
        isScanning: false, // 必ずfalseに設定
        discoveredDevices: devices,
      );
      
      print('[PavlokProvider] [FINALLY] 状態を更新: isScanning=false, discoveredDevices=${devices.length}台');
      state = AsyncValue.data(updatedState);
      print('[PavlokProvider] [FINALLY] 状態更新完了 - UIに通知されます');
    }
  }

  /// 指定されたデバイスに接続します
  /// 
  /// [device] 接続するBluetoothデバイス
  Future<void> connectToDevice(BluetoothDevice device) async {
    print('[PavlokProvider] ========================================');
    print('[PavlokProvider] 接続処理を開始します');
    print('[PavlokProvider] ========================================');
    
    state = const AsyncValue.loading();
    
    try {
      final bleService = PavlokBleService();

      // Bluetoothが有効か確認
      print('[PavlokProvider] Bluetooth状態を確認中...');
      if (!await bleService.isBluetoothEnabled()) {
        print('[PavlokProvider] ❌ Bluetoothが有効になっていません');
        state = AsyncValue.error(
          Exception('Bluetoothが有効になっていません'),
          StackTrace.current,
        );
        return;
      }
      print('[PavlokProvider] ✅ Bluetoothは有効です');
      
      // 公式アプリ風の表示名を使用
      const deviceDisplayName = 'Pavlok 3';
      final deviceId = device.remoteId.toString();
      final deviceIdPrefix = deviceId.length >= 4 
          ? deviceId.substring(0, 4).toUpperCase()
          : deviceId.toUpperCase();
      final deviceAlias = 'PAVLOK-3-$deviceIdPrefix';
      
      print('[PavlokProvider] 接続対象デバイス: $deviceDisplayName ($deviceAlias)');
      
      // バッテリーレベル更新と切断監視のコールバックを設定
      print('[PavlokProvider] BLEサービスに接続を要求します...');
      
      await bleService.connect(
        device,
        timeout: const Duration(seconds: 10),
        onBatteryLevelUpdate: (batteryLevel) {
          print('[PavlokProvider] バッテリーレベル更新を受信: $batteryLevel%');
          // バッテリーレベルが更新されたら状態を更新
          final currentState = state.value;
          if (currentState != null && batteryLevel != null) {
            state = AsyncValue.data(
              currentState.copyWith(batteryLevel: batteryLevel),
            );
          }
        },
        onDisconnected: () {
          print('[PavlokProvider] ⚠️ デバイスが切断されました');
          // 切断が検出されたら状態を更新
          final currentState = state.value;
          if (currentState != null && currentState.isConnected) {
            state = AsyncValue.data(
              currentState.copyWith(
                isConnected: false,
                deviceName: null,
                deviceModel: null,
                batteryLevel: null,
              ),
            );
          }
        },
      );

      print('[PavlokProvider] ✅ BLEサービスへの接続が完了しました');
      print('[PavlokProvider] connect() → discoverServices() → ターゲットService UUID確認 → 完了');

      // バッテリー残量を取得（可能な場合）
      print('[PavlokProvider] バッテリー残量を取得中...');
      final batteryLevel = await bleService.getBatteryLevel();
      if (batteryLevel != null) {
        print('[PavlokProvider] バッテリー残量: $batteryLevel%');
      } else {
        print('[PavlokProvider] ⚠️ バッテリー残量を取得できませんでした');
      }

      // 状態を更新（接続完了）
      // connect() → discoverServices() → ターゲットService UUID確認 → isConnected = true
      print('[PavlokProvider] ========================================');
      print('[PavlokProvider] 状態を更新します（接続完了）');
      print('[PavlokProvider] 現在の状態: isConnected=${state.value?.isConnected ?? false}');
      
      final newState = PavlokState(
        isConnected: true, // サービス探索完了後に設定
        deviceName: deviceDisplayName,
        deviceModel: deviceAlias,
        batteryLevel: batteryLevel,
        shockIntensity: state.value?.shockIntensity ?? 10,
        alarmIntensity: state.value?.alarmIntensity ?? 50,
        vibrateIntensity: state.value?.vibrateIntensity ?? 5,
        isQuickRemoteExpanded: state.value?.isQuickRemoteExpanded ?? false,
        discoveredDevices: [], // 接続後はデバイスリストをクリア
        isScanning: false,
      );

      print('[PavlokProvider] 新しい状態:');
      print('[PavlokProvider]   isConnected: ${newState.isConnected}');
      print('[PavlokProvider]   デバイス名: $deviceDisplayName');
      print('[PavlokProvider]   デバイスエイリアス: $deviceAlias');
      print('[PavlokProvider]   バッテリー残量: ${batteryLevel ?? "不明"}%');
      print('[PavlokProvider] 状態を更新します - UIに通知されます');
      print('[PavlokProvider] ========================================');

      state = AsyncValue.data(newState);
      print('[PavlokProvider] ✅ 状態更新完了 - UIが再ビルドされます');
      print('[PavlokProvider] ref.watch()が状態変化を検知し、画面が切り替わります');
    } catch (e, stackTrace) {
      print('[PavlokProvider] ========================================');
      print('[PavlokProvider] ❌ 接続処理でエラーが発生しました');
      print('[PavlokProvider] エラー: $e');
      print('[PavlokProvider] エラータイプ: ${e.runtimeType}');
      print('[PavlokProvider] スタックトレース:');
      print(stackTrace);
      print('[PavlokProvider] ========================================');
      
      // エラー状態を設定（ローディング状態を解除）
      // 再度スキャン可能な状態に戻す
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.copyWith(
            isConnected: false,
            isScanning: false,
          ),
        );
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// デバイスから切断します
  Future<void> disconnect() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final bleService = PavlokBleService();
      await bleService.disconnect();

      return PavlokState(
        isConnected: false,
        deviceName: null,
        deviceModel: null,
        batteryLevel: null,
        shockIntensity: state.value?.shockIntensity ?? 10,
        alarmIntensity: state.value?.alarmIntensity ?? 50,
        vibrateIntensity: state.value?.vibrateIntensity ?? 5,
        isQuickRemoteExpanded: state.value?.isQuickRemoteExpanded ?? false,
        discoveredDevices: state.value?.discoveredDevices ?? [],
        isScanning: false,
      );
    });
  }

  /// ショックの強度を更新します
  void updateShockIntensity(int intensity) {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(
        currentState.copyWith(shockIntensity: intensity),
      );
    }
  }

  /// アラームの強度を更新します
  void updateAlarmIntensity(int intensity) {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(
        currentState.copyWith(alarmIntensity: intensity),
      );
    }
  }

  /// バイブの強度を更新します
  void updateVibrateIntensity(int intensity) {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(
        currentState.copyWith(vibrateIntensity: intensity),
      );
    }
  }

  /// ショックを実行します
  Future<void> triggerShock() async {
    final currentState = state.value;
    if (currentState == null || !currentState.isConnected) {
      throw Exception('デバイスに接続されていません');
    }

    final bleService = PavlokBleService();
    await bleService.triggerShock(currentState.shockIntensity);
  }

  /// アラームを実行します
  Future<void> triggerAlarm() async {
    final currentState = state.value;
    if (currentState == null || !currentState.isConnected) {
      throw Exception('デバイスに接続されていません');
    }

    final bleService = PavlokBleService();
    await bleService.triggerAlarm(currentState.alarmIntensity);
  }

  /// バイブを実行します
  Future<void> triggerVibrate() async {
    final currentState = state.value;
    if (currentState == null || !currentState.isConnected) {
      throw Exception('デバイスに接続されていません');
    }

    final bleService = PavlokBleService();
    await bleService.triggerVibrate(currentState.vibrateIntensity);
  }

  /// クイックリモートの展開状態を切り替えます
  void toggleQuickRemoteExpansion() {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(
        currentState.copyWith(
          isQuickRemoteExpanded: !currentState.isQuickRemoteExpanded,
        ),
      );
    }
  }

  /// デバイスに設定を保存します
  Future<void> saveToDevice() async {
    final currentState = state.value;
    if (currentState == null) {
      return;
    }
    // TODO: 実際のデバイス保存処理を実装
    // await pavlokService.saveSettings(currentState);
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 保存後、展開状態を閉じる
    state = AsyncValue.data(
      currentState.copyWith(isQuickRemoteExpanded: false),
    );
  }
}

/// Pavlokデバイスの状態
class PavlokState {
  final bool isConnected;
  final String? deviceName;
  final String? deviceModel;
  final int? batteryLevel;
  final int shockIntensity;
  final int alarmIntensity;
  final int vibrateIntensity;
  final bool isQuickRemoteExpanded;
  final List<BluetoothDevice> discoveredDevices;
  final bool isScanning;

  const PavlokState({
    required this.isConnected,
    this.deviceName,
    this.deviceModel,
    this.batteryLevel,
    required this.shockIntensity,
    required this.alarmIntensity,
    required this.vibrateIntensity,
    this.isQuickRemoteExpanded = false,
    this.discoveredDevices = const [],
    this.isScanning = false,
  });

  PavlokState copyWith({
    bool? isConnected,
    String? deviceName,
    String? deviceModel,
    int? batteryLevel,
    int? shockIntensity,
    int? alarmIntensity,
    int? vibrateIntensity,
    bool? isQuickRemoteExpanded,
    List<BluetoothDevice>? discoveredDevices,
    bool? isScanning,
  }) {
    return PavlokState(
      isConnected: isConnected ?? this.isConnected,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      shockIntensity: shockIntensity ?? this.shockIntensity,
      alarmIntensity: alarmIntensity ?? this.alarmIntensity,
      vibrateIntensity: vibrateIntensity ?? this.vibrateIntensity,
      isQuickRemoteExpanded: isQuickRemoteExpanded ?? this.isQuickRemoteExpanded,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}
