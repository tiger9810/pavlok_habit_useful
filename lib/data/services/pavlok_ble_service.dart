import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// バッテリーレベル更新時のコールバック
typedef BatteryLevelCallback = void Function(int?);

/// PavlokデバイスとのBLE通信を管理するサービス
/// 
/// flutter_blue_plusをラップし、デバイスのスキャン、接続、切断、
/// およびコマンド送信を担当します。
class PavlokBleService {
  static final PavlokBleService _instance = PavlokBleService._internal();
  factory PavlokBleService() => _instance;
  PavlokBleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _batteryCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  BatteryLevelCallback? _onBatteryLevelUpdate;
  VoidCallback? _onDisconnected;
  
  // サービスとキャラクタリスティックのキャッシュ
  List<BluetoothService>? _cachedServices;
  BluetoothCharacteristic? _unlockCharacteristic; // サービス7000...の7001
  BluetoothCharacteristic? _handshakeCharacteristic; // サービス1000...の1005
  BluetoothCharacteristic? _vibrateCharacteristic; // サービス1000...の1001
  BluetoothCharacteristic? _beepCharacteristic; // サービス1000...の1002
  BluetoothCharacteristic? _shockCharacteristic; // サービス1000...の1003

  // PavlokのService UUID（実際のデバイスで確認済み）
  static const String pavlokServiceUuid = '6214b1a3-854c-4b2c-8054-780eb5c448b7';
  
  // 仕様書に基づくサービスUUID（末尾4桁ベース）
  static const String service7000Uuid = '00007000-0000-1000-8000-00805f9b34fb';
  static const String service1000Uuid = '00001000-0000-1000-8000-00805f9b34fb';
  
  // Unlockデータ（共通Step 1）
  static final Uint8List unlockData = Uint8List.fromList([0x12, 0x0d, 0xa0, 0x48, 0xad, 0x69, 0xe4]);
  
  // Handshakeデータ（Shock専用Step 2）
  static final Uint8List handshakeData = Uint8List.fromList([0x18, 0x02, 0x20, 0x17, 0x06, 0x01, 0x26, 0xe0]);

  /// 現在接続されているデバイスを取得します
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// 接続状態を取得します
  bool get isConnected => _connectedDevice != null && _connectedDevice!.isConnected;

  /// Bluetoothが有効かどうかを確認します
  Future<bool> isBluetoothEnabled() async {
    try {
      if (!await FlutterBluePlus.isSupported) {
        print('[PavlokBleService] Bluetoothはこのデバイスでサポートされていません');
        return false;
      }
      
      final adapterState = await FlutterBluePlus.adapterState.first;
      print('[PavlokBleService] Bluetoothアダプター状態: $adapterState');
      
      if (adapterState != BluetoothAdapterState.on) {
        print('[PavlokBleService] ⚠️ Bluetoothがオンになっていません');
        print('[PavlokBleService] 現在の状態: $adapterState');
        print('[PavlokBleService] macOSの「システム設定 > Bluetooth」でBluetoothを有効にしてください');
        return false;
      }
      
      print('[PavlokBleService] ✅ Bluetoothは有効です');
      print('[PavlokBleService] ⚠️ 権限確認: macOSの「システム設定 > プライバシーとセキュリティ > Bluetooth」');
      print('[PavlokBleService] に「Runner」または「useful_pavlok」が表示され、チェックが入っているか確認してください');
      
      return true;
    } catch (e) {
      print('[PavlokBleService] ❌ Bluetooth状態の確認に失敗: $e');
      developer.log('Bluetooth状態の確認に失敗: $e', name: 'PavlokBleService');
      return false;
    }
  }

  /// Bluetoothを有効にします
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      developer.log('Bluetoothの有効化に失敗: $e', name: 'PavlokBleService');
      rethrow;
    }
  }

  /// Pavlokデバイスをスキャンします
  /// 
  /// [timeout] スキャンタイムアウト（デフォルト: 10秒）
  /// 
  /// Returns: Service UUID `6214b1a3-854c-4b2c-8054-780eb5c448b7` を持つPavlokデバイスのリスト
  Future<List<ScanResult>> scanForPavlokDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      print('[PavlokBleService] ========================================');
      print('[PavlokBleService] [START] Pavlok 3 デバイスをスキャン開始');
      print('[PavlokBleService] ターゲットService UUID: $pavlokServiceUuid');
      print('[PavlokBleService] タイムアウト: ${timeout.inSeconds}秒');
      print('[PavlokBleService] ========================================');
      
      if (!await isBluetoothEnabled()) {
        throw Exception('Bluetoothが有効になっていません');
      }

      final List<ScanResult> pavlokDevices = [];
      final Set<String> seenDeviceIds = {};
      final targetServiceUuid = Guid(pavlokServiceUuid);

      print('[PavlokBleService] Service UUIDによる汎用フィルタリングを適用します');

      // スキャン開始
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [targetServiceUuid],
      );

      print('[PavlokBleService] スキャン開始: タイムアウト=${timeout.inSeconds}秒');

      // スキャン結果をリッスン（タイムアウトまで）
      // Stream.timeout()を使用して、タイムアウト後に確実にループを終了させる
      try {
        await for (final scanResults in FlutterBluePlus.scanResults.timeout(timeout)) {
          for (final scanResult in scanResults) {
            final deviceId = scanResult.device.remoteId.toString();
            
            // 重複を避ける（Setで管理）
            if (seenDeviceIds.contains(deviceId)) {
              continue;
            }
            seenDeviceIds.add(deviceId);

            // Service UUIDでフィルタリング（決定論的フィルタリング）
            // Pavlok 3共通のService UUIDを持つデバイスのみを抽出
            final hasPavlokService = scanResult.advertisementData.serviceUuids
                .any((uuid) => uuid == targetServiceUuid);
            
            if (hasPavlokService) {
              pavlokDevices.add(scanResult);
              final deviceIdStr = scanResult.device.remoteId.toString();
              final deviceIdPrefix = deviceIdStr.length >= 4 
                  ? deviceIdStr.substring(0, 4).toUpperCase()
                  : deviceIdStr.toUpperCase();
              print('[PavlokBleService] ✅ Pavlok 3 を発見: PAVLOK-3-$deviceIdPrefix');
              developer.log(
                'Pavlok 3 デバイス発見: PAVLOK-3-$deviceIdPrefix (${scanResult.device.remoteId})',
                name: 'PavlokBleService',
              );
            } else {
              // 無関係なデバイス（テレビやイヤホンなど）はログに出力しない
              // これにより、Pavlok 3のみがリストに表示される
            }
          }
        }
      } on TimeoutException {
        // タイムアウト時は既に収集したデバイスリストを返す
        print('[PavlokBleService] ⏱️ スキャンタイムアウト: ${timeout.inSeconds}秒経過');
        print('[PavlokBleService] これまでに発見されたデバイス数: ${pavlokDevices.length}');
        developer.log(
          'スキャンタイムアウト: ${timeout.inSeconds}秒経過、発見されたデバイス数: ${pavlokDevices.length}',
          name: 'PavlokBleService',
        );
      } catch (e) {
        print('[PavlokBleService] ❌ スキャン結果のリッスン中にエラー: $e');
        print('[PavlokBleService] エラータイプ: ${e.runtimeType}');
        developer.log(
          'スキャン結果のリッスン中にエラー: $e (タイプ: ${e.runtimeType})',
          name: 'PavlokBleService',
        );
      } finally {
        // 確実にスキャンを停止
        try {
          await FlutterBluePlus.stopScan();
          print('[PavlokBleService] ✅ スキャンを停止しました');
        } catch (e) {
          print('[PavlokBleService] ⚠️ スキャン停止エラー: $e');
        }
      }

      print('[PavlokBleService] ========================================');
      print('[PavlokBleService] [END] スキャン完了');
      print('[PavlokBleService] 発見されたPavlok 3デバイス数: ${pavlokDevices.length}');
      print('[PavlokBleService] ========================================');

      if (pavlokDevices.isEmpty) {
        print('[PavlokBleService] ⚠️ Pavlok 3デバイス（Service UUID: $pavlokServiceUuid）が見つかりませんでした');
        print('[PavlokBleService] 確認事項:');
        print('[PavlokBleService] 1. Bluetoothが有効になっているか');
        print('[PavlokBleService] 2. Pavlok 3デバイスが電源オンで、ペアリング可能な状態か');
        print('[PavlokBleService] 3. macOSの「システム設定 > プライバシーとセキュリティ > Bluetooth」');
        print('[PavlokBleService]    で「Runner」または「useful_pavlok」に権限が与えられているか');
      } else {
        print('[PavlokBleService] ✅ スキャン成功: ${pavlokDevices.length}台のPavlok 3デバイスを発見');
      }

      return pavlokDevices;
    } catch (e) {
      print('[PavlokBleService] ❌ スキャンエラー: $e');
      developer.log('スキャンエラー: $e', name: 'PavlokBleService');
      await FlutterBluePlus.stopScan();
      rethrow;
    }
  }

  /// デバイスに接続します
  /// 
  /// [device] 接続するBluetoothデバイス
  /// [timeout] 接続タイムアウト（デフォルト: 10秒）
  /// [onBatteryLevelUpdate] バッテリーレベル更新時のコールバック
  /// [onDisconnected] 切断時のコールバック
  Future<void> connect(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 10),
    BatteryLevelCallback? onBatteryLevelUpdate,
    VoidCallback? onDisconnected,
  }) async {
    try {
      if (_connectedDevice != null && _connectedDevice!.isConnected) {
        print('[PavlokBleService] 既存の接続を切断中...');
        await disconnect();
      }

      _connectedDevice = device;
      _onBatteryLevelUpdate = onBatteryLevelUpdate;
      _onDisconnected = onDisconnected;

      final deviceName = device.platformName.isNotEmpty
          ? device.platformName
          : '(名前なし)';
      final deviceId = device.remoteId.toString();

      print('[PavlokBleService] ========================================');
      print('[PavlokBleService] Pavlok 3 接続プロセス開始');
      print('[PavlokBleService] デバイス名: $deviceName');
      print('[PavlokBleService] デバイスID: $deviceId');
      print('[PavlokBleService] タイムアウト: ${timeout.inSeconds}秒');
      print('[PavlokBleService] ========================================');

      // 接続前のクリーンアップ: 中途半端な接続が残っている場合は確実にリセット
      print('[PavlokBleService] [PRE-CONNECT] 既存の接続をクリーンアップ中...');
      try {
        await device.disconnect().catchError((e) {
          print('[PavlokBleService] [PRE-CONNECT] 切断エラー（無視）: $e');
          return null;
        });
        print('[PavlokBleService] [PRE-CONNECT] ✅ クリーンアップ完了');
      } catch (e) {
        print('[PavlokBleService] [PRE-CONNECT] ⚠️ クリーンアップ中にエラー（続行）: $e');
      }

      // 自動再試行ロジック: 最大2回まで自動で接続を再試行
      const maxRetries = 2;
      int attempt = 0;
      Exception? lastException;

      while (attempt <= maxRetries) {
        try {
          if (attempt > 0) {
            print('[PavlokBleService] [RETRY] 再接続試行 $attempt/$maxRetries...');
            // 再試行前に少し待機
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // ステップ1: device.connect() を開始
          // 確実な接続とサービス探索の連鎖: connect() → discoverServices() → isConnected = true
          print('[PavlokBleService] [STEP 1] device.connect() を開始します... (試行 ${attempt + 1}/${maxRetries + 1})');
          print('[PavlokBleService] 対象デバイス: remoteId = $deviceId');
          
          await device.connect(
            timeout: timeout,
            autoConnect: false,
          );
          print('[PavlokBleService] [STEP 1] ✅ device.connect() が完了しました');
          developer.log(
            'device.connect() 完了: $deviceId (試行 ${attempt + 1})',
            name: 'PavlokBleService',
          );
          
          // 接続成功: ループを抜ける
          break;
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          attempt++;
          print('[PavlokBleService] [STEP 1] ❌ device.connect() でエラー: $e');
          print('[PavlokBleService] エラータイプ: ${e.runtimeType}');
          print('[PavlokBleService] 試行回数: $attempt/${maxRetries + 1}');
          developer.log(
            'device.connect() エラー: $e (タイプ: ${e.runtimeType}, 試行: $attempt/${maxRetries + 1})',
            name: 'PavlokBleService',
          );
          
          if (attempt > maxRetries) {
            print('[PavlokBleService] [STEP 1] ❌ 最大再試行回数に達しました');
            throw lastException;
          }
        }
      }

      // MTUリクエスト: 接続成功直後に実行（データのやり取りを安定させるため）
      print('[PavlokBleService] [MTU] MTUリクエストを実行中...');
      try {
        await device.requestMtu(223);
        print('[PavlokBleService] [MTU] ✅ MTUリクエスト完了: 223');
        developer.log(
          'MTUリクエスト完了: 223',
          name: 'PavlokBleService',
        );
      } catch (e) {
        print('[PavlokBleService] [MTU] ⚠️ MTUリクエストでエラー（続行）: $e');
        developer.log(
          'MTUリクエストエラー: $e',
          name: 'PavlokBleService',
        );
        // MTUリクエストの失敗は接続を中断しない
      }

      // ステップ2: device.discoverServices() を開始（結果をキャッシュ）
      print('[PavlokBleService] [STEP 2] device.discoverServices() を開始します...');
      
      List<BluetoothService> services;
      try {
        services = await device.discoverServices();
        // サービスをキャッシュ
        _cachedServices = services;
        print('[PavlokBleService] [STEP 2] ✅ device.discoverServices() が完了しました');
        print('[PavlokBleService] 発見されたサービス数: ${services.length}');
        print('[PavlokBleService] サービスをキャッシュしました');
        developer.log(
          'device.discoverServices() 完了: ${services.length}個のサービス（キャッシュ済み）',
          name: 'PavlokBleService',
        );
      } catch (e) {
        print('[PavlokBleService] [STEP 2] ❌ device.discoverServices() でエラー: $e');
        print('[PavlokBleService] エラータイプ: ${e.runtimeType}');
        developer.log(
          'device.discoverServices() エラー: $e (タイプ: ${e.runtimeType})',
          name: 'PavlokBleService',
        );
        rethrow;
      }

      // ステップ3: ターゲットService UUIDを探す
      print('[PavlokBleService] [STEP 3] ターゲットService UUIDを探索中...');
      print('[PavlokBleService] ターゲットUUID: $pavlokServiceUuid');
      
      final targetServiceUuid = Guid(pavlokServiceUuid);
      BluetoothService? pavlokService;

      for (final service in services) {
        final serviceUuidStr = service.uuid.toString();
        print('[PavlokBleService]   サービスUUID: $serviceUuidStr');
        developer.log(
          'サービスUUID: $serviceUuidStr',
          name: 'PavlokBleService',
        );

        if (service.uuid == targetServiceUuid) {
          pavlokService = service;
          print('[PavlokBleService] ✅ ターゲットService UUIDを発見: $serviceUuidStr');
          developer.log(
            'ターゲットService UUIDを発見: $serviceUuidStr',
            name: 'PavlokBleService',
          );
        }

        // キャラクタリスティックの詳細ログ
        for (final characteristic in service.characteristics) {
          developer.log(
            '  キャラクタリスティックUUID: ${characteristic.uuid}',
            name: 'PavlokBleService',
          );
          developer.log(
            '    プロパティ: ${characteristic.properties}',
            name: 'PavlokBleService',
          );
        }
      }

      if (pavlokService == null) {
        print('[PavlokBleService] [STEP 3] ❌ ターゲットService UUIDが見つかりませんでした');
        print('[PavlokBleService] 見つかったサービス数: ${services.length}');
        print('[PavlokBleService] ターゲットUUID: $pavlokServiceUuid');
        throw Exception('Pavlokサービス（UUID: $pavlokServiceUuid）が見つかりません');
      }

      print('[PavlokBleService] [STEP 3] ✅ ターゲットService UUIDを確認しました');

      // ステップ4: コマンド送信用のキャラクタリスティックを探す
      print('[PavlokBleService] [STEP 4] コマンド送信用キャラクタリスティックを探索中...');
      
      _commandCharacteristic = _findWritableCharacteristicInService(pavlokService);

      if (_commandCharacteristic == null) {
        print('[PavlokBleService] [STEP 4] ❌ 書き込み可能なキャラクタリスティックが見つかりません');
        throw Exception('コマンド送信用の書き込み可能なキャラクタリスティックが見つかりません');
      }

      print('[PavlokBleService] [STEP 4] ✅ コマンド送信用キャラクタリスティックを発見');
      print('[PavlokBleService] キャラクタリスティックUUID: ${_commandCharacteristic!.uuid}');
      developer.log(
        'コマンド送信用キャラクタリスティック発見: ${_commandCharacteristic!.uuid}',
        name: 'PavlokBleService',
      );

      // 「接続の真実」を証明するログ
      // ターゲットService UUIDが確認でき、書き込み可能なCharacteristicが見つかった時点で出力
      print('[PavlokBleService] ========================================');
      print('[PavlokBleService] ✅ 接続先デバイス: $deviceName ($deviceId)');
      print('[PavlokBleService] ✅ 発見されたサービス数: ${services.length}');
      print('[PavlokBleService] ✅ 書き込み可能なCharacteristic: あり');
      print('[PavlokBleService]    UUID: ${_commandCharacteristic!.uuid}');
      print('[PavlokBleService]    プロパティ: write=${_commandCharacteristic!.properties.write}, writeWithoutResponse=${_commandCharacteristic!.properties.writeWithoutResponse}');
      print('[PavlokBleService] ========================================');
      print('[PavlokBleService] ✅ 接続完了 - コマンド送信の準備が整いました');
      developer.log(
        '接続の真実: デバイス=$deviceName, サービス数=${services.length}, 書き込み可能Characteristic=あり',
        name: 'PavlokBleService',
      );

      // ステップ5: バッテリー情報取得用のキャラクタリスティックを探す
      print('[PavlokBleService] [STEP 5] バッテリー情報用キャラクタリスティックを探索中...');
      
      _batteryCharacteristic = _findBatteryCharacteristic(pavlokService);

      if (_batteryCharacteristic != null) {
        print('[PavlokBleService] [STEP 5] ✅ バッテリー情報用キャラクタリスティックを発見');
        print('[PavlokBleService] キャラクタリスティックUUID: ${_batteryCharacteristic!.uuid}');
        
        // バッテリー情報の通知を有効化（可能な場合）
        if (_batteryCharacteristic!.properties.notify) {
          print('[PavlokBleService] バッテリー通知を有効化します...');
          await _batteryCharacteristic!.setNotifyValue(true);
          _batteryCharacteristic!.lastValueStream.listen((value) {
            if (value.isNotEmpty) {
              final batteryLevel = value[0];
              print('[PavlokBleService] バッテリー残量を受信: $batteryLevel%');
              developer.log(
                'バッテリー残量を受信: $batteryLevel%',
                name: 'PavlokBleService',
              );
              _onBatteryLevelUpdate?.call(batteryLevel);
            }
          });
          print('[PavlokBleService] バッテリー通知を有効化しました');
        } else if (_batteryCharacteristic!.properties.read) {
          print('[PavlokBleService] バッテリー通知ができないため、ポーリングを開始します...');
          _startBatteryPolling();
        }
      } else {
        print('[PavlokBleService] [STEP 5] ⚠️ バッテリー情報用キャラクタリスティックが見つかりませんでした');
      }

      // ステップ6: 接続状態を監視
      print('[PavlokBleService] [STEP 6] 接続状態の監視を開始します...');
      _startConnectionMonitoring();
      print('[PavlokBleService] [STEP 6] ✅ 接続状態の監視を開始しました');

      print('[PavlokBleService] ========================================');
      print('[PavlokBleService] ✅ 接続プロセス完了');
      print('[PavlokBleService] デバイス名: $deviceName');
      print('[PavlokBleService] デバイスID: $deviceId');
      print('[PavlokBleService] ========================================');
      
      developer.log(
        'デバイスに接続しました: $deviceName ($deviceId)',
        name: 'PavlokBleService',
      );
    } catch (e, stackTrace) {
      print('[PavlokBleService] ========================================');
      print('[PavlokBleService] ❌ 接続プロセスでエラーが発生しました');
      print('[PavlokBleService] エラー: $e');
      print('[PavlokBleService] エラータイプ: ${e.runtimeType}');
      print('[PavlokBleService] スタックトレース:');
      print(stackTrace);
      print('[PavlokBleService] ========================================');
      
      developer.log(
        '接続エラー: $e (タイプ: ${e.runtimeType})',
        name: 'PavlokBleService',
        error: e,
        stackTrace: stackTrace,
      );
      
      await disconnect();
      rethrow;
    }
  }

  /// デバイスから切断します
  Future<void> disconnect() async {
    try {
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
      _stopBatteryPolling();
      _onBatteryLevelUpdate = null;
      _onDisconnected = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        print('[PavlokBleService] デバイスから切断しました');
        developer.log('デバイスから切断しました', name: 'PavlokBleService');
      }
    } catch (e) {
      print('[PavlokBleService] 切断エラー: $e');
      developer.log('切断エラー: $e', name: 'PavlokBleService');
    } finally {
      _connectedDevice = null;
      _commandCharacteristic = null;
      _batteryCharacteristic = null;
    }
  }

  /// ショックを実行します
  /// 
  /// [intensity] 強度（0-100）
  Future<void> triggerShock(int intensity) async {
    await _sendCommand(_PavlokCommand.shock, intensity);
  }

  /// バイブを実行します（スニッフィングされた真実のパケットを使用）
  /// 
  /// [intensity] 強度（0-100）- 現在は無視され、スニッフィングされた値が使用されます
  Future<void> triggerVibrate(int intensity) async {
    await _sendSniffedData(sniffedVibrateHex);
  }
  
  /// スニッフィングされたデータを直接送信します
  /// 
  /// [hexString] 16進数文字列（例: "120da048ad69e4"）
  Future<void> _sendSniffedData(String hexString) async {
    if (_commandCharacteristic == null) {
      throw Exception('デバイスに接続されていません');
    }

    if (_connectedDevice == null || !_connectedDevice!.isConnected) {
      throw Exception('デバイスが切断されています');
    }

    // 16進数文字列をUint8Listに変換
    final commandData = _hexStringToBytes(hexString);

    try {
      print('[PavlokBleService] Sending Sniffed Data: $hexString to ${_commandCharacteristic!.uuid}');
      print('[PavlokBleService] 送信データ（バイト）: ${commandData.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}');
      
      await _commandCharacteristic!.write(
        commandData,
        withoutResponse: _commandCharacteristic!.properties.writeWithoutResponse,
      );

      developer.log(
        'スニッフィングされたデータ送信成功: $hexString',
        name: 'PavlokBleService',
      );
      print('[PavlokBleService] ✅ スニッフィングされたデータの送信が完了しました');
    } catch (e) {
      print('[PavlokBleService] ❌ スニッフィングされたデータの送信エラー: $e');
      developer.log('スニッフィングされたデータの送信エラー: $e', name: 'PavlokBleService');
      rethrow;
    }
  }
  
  /// スニッフィングされたバイブデータを直接送信します（公開メソッド）
  /// 
  /// UIから直接呼び出し可能なメソッド
  Future<void> sendSniffedVibrateData() async {
    await _sendSniffedData(sniffedVibrateHex);
  }

  /// アラームを実行します
  /// 
  /// [intensity] 強度（0-100）
  Future<void> triggerAlarm(int intensity) async {
    await _sendCommand(_PavlokCommand.alarm, intensity);
  }

  /// バッテリー残量を取得します
  /// 
  /// Returns: バッテリー残量（0-100）、取得できない場合はnull
  Future<int?> getBatteryLevel() async {
    try {
      if (_batteryCharacteristic == null) {
        developer.log(
          'バッテリーキャラクタリスティックが見つかりません',
          name: 'PavlokBleService',
        );
        return null;
      }

      if (_batteryCharacteristic!.properties.read) {
        final value = await _batteryCharacteristic!.read();
        if (value.isNotEmpty) {
          return value[0];
        }
      }

      return null;
    } catch (e) {
      developer.log('バッテリー残量の取得エラー: $e', name: 'PavlokBleService');
      return null;
    }
  }

  /// コマンドを送信します
  /// 
  /// [command] 送信するコマンド
  /// [intensity] 強度（0-100）
  Future<void> _sendCommand(_PavlokCommand command, int intensity) async {
    if (_commandCharacteristic == null) {
      throw Exception('デバイスに接続されていません');
    }

    if (_connectedDevice == null || !_connectedDevice!.isConnected) {
      throw Exception('デバイスが切断されています');
    }

    // 強度を0-100の範囲に制限
    final clampedIntensity = intensity.clamp(0, 100);

    // 強度を0-100から0-255の範囲にマッピング（Pavlokの仕様に基づく）
    final intensityByte = ((clampedIntensity / 100) * 255).round().clamp(0, 255);

    // コマンドデータを構築（16進数のバイトデータ）
    // Pavlokのプロトコル: [コマンドID, 強度(0-255)]
    final commandData = Uint8List.fromList([
      command.value,
      intensityByte,
    ]);

    try {
      print('[PavlokBleService] コマンド送信: ${command.name}, 強度: $clampedIntensity% (バイト値: $intensityByte)');
      print('[PavlokBleService] 送信データ: ${commandData.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}');

      await _commandCharacteristic!.write(
        commandData,
        withoutResponse: _commandCharacteristic!.properties.writeWithoutResponse,
      );

      developer.log(
        'コマンド送信成功: ${command.name}, 強度: $clampedIntensity% (バイト値: $intensityByte)',
        name: 'PavlokBleService',
      );
    } catch (e) {
      print('[PavlokBleService] ❌ コマンド送信エラー: $e');
      developer.log('コマンド送信エラー: $e', name: 'PavlokBleService');
      rethrow;
    }
  }

  /// 16進数文字列をUint8Listに変換します
  /// 
  /// [hexString] 16進数文字列（例: "120da048ad69e4"）
  /// Returns: Uint8List
  Uint8List _hexStringToBytes(String hexString) {
    // 空白やハイフンを削除
    final cleanHex = hexString.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cleanHex.length % 2 != 0) {
      throw ArgumentError('16進数文字列の長さが偶数ではありません: $hexString');
    }
    
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      final hexByte = cleanHex.substring(i, i + 2);
      bytes.add(int.parse(hexByte, radix: 16));
    }
    
    return Uint8List.fromList(bytes);
  }

  /// 指定されたサービス内で書き込み可能なキャラクタリスティックを検索します
  /// 優先順位: 0007 (targetCharacteristicUuid) > その他の書き込み可能なキャラクタリスティック
  BluetoothCharacteristic? _findWritableCharacteristicInService(
    BluetoothService service,
  ) {
    final targetUuid = Guid(targetCharacteristicUuid);
    
    // まず、ターゲットキャラクタリスティック（0007）を探す
    for (final characteristic in service.characteristics) {
      if (characteristic.uuid == targetUuid) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          print('[PavlokBleService] ✅ ターゲットキャラクタリスティック0007を発見');
          return characteristic;
        }
      }
    }
    
    // ターゲットが見つからない場合、その他の書き込み可能なキャラクタリスティックを返す
    for (final characteristic in service.characteristics) {
      if (characteristic.properties.write ||
          characteristic.properties.writeWithoutResponse) {
        return characteristic;
      }
    }
    return null;
  }

  /// バッテリー情報用のキャラクタリスティックを検索します
  BluetoothCharacteristic? _findBatteryCharacteristic(
    BluetoothService service,
  ) {
    for (final characteristic in service.characteristics) {
      if (characteristic.properties.read || characteristic.properties.notify) {
        return characteristic;
      }
    }
    return null;
  }

  /// 接続状態の監視を開始します
  void _startConnectionMonitoring() {
    if (_connectedDevice == null) return;

    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = _connectedDevice!.connectionState.listen(
      (state) {
        print('[PavlokBleService] 接続状態変更: $state');
        developer.log(
          '接続状態変更: $state',
          name: 'PavlokBleService',
        );

        if (state == BluetoothConnectionState.disconnected) {
          print('[PavlokBleService] ⚠️ デバイスが切断されました');
          developer.log(
            'デバイスが切断されました',
            name: 'PavlokBleService',
          );
          // 接続状態をクリア
          _connectedDevice = null;
          _commandCharacteristic = null;
          _batteryCharacteristic = null;
          _stopBatteryPolling();
          // コールバックで切断を通知
          _onDisconnected?.call();
        }
      },
      onError: (error) {
        print('[PavlokBleService] ❌ 接続状態監視エラー: $error');
        developer.log(
          '接続状態監視エラー: $error',
          name: 'PavlokBleService',
        );
      },
    );
  }

  /// バッテリーレベルの定期ポーリングを開始します
  Timer? _batteryPollingTimer;
  void _startBatteryPolling() {
    _batteryPollingTimer?.cancel();
    _batteryPollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (_connectedDevice == null || !_connectedDevice!.isConnected) {
          timer.cancel();
          return;
        }

        try {
          final batteryLevel = await getBatteryLevel();
          if (batteryLevel != null) {
            _onBatteryLevelUpdate?.call(batteryLevel);
          }
        } catch (e) {
          developer.log(
            'バッテリーポーリングエラー: $e',
            name: 'PavlokBleService',
          );
        }
      },
    );
  }

  /// バッテリーポーリングを停止します
  void _stopBatteryPolling() {
    _batteryPollingTimer?.cancel();
    _batteryPollingTimer = null;
  }
}

/// Pavlokコマンドの定義
enum _PavlokCommand {
  shock(0x01),
  vibrate(0x02),
  alarm(0x03);

  final int value;
  const _PavlokCommand(this.value);
}
