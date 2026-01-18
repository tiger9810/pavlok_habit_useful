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

  // PavlokのService UUID（仕様書に基づくメイン制御サービス）
  static const String pavlokServiceUuid = '156e1000-a300-4fea-897b-86f698d74461';
  
  // 仕様書に基づくサービスUUID（完全128ビットUUID）
  static const String _authServiceUuid = '156e7000-a300-4fea-897b-86f698d74461';
  static const String _controlServiceUuid = '156e1000-a300-4fea-897b-86f698d74461';
  
  // キャラクタリスティックUUID（完全128ビットUUID）
  static const String _unlockCharUuid = '156e7001-a300-4fea-897b-86f698d74461';
  static const String _handshakeCharUuid = '156e1005-a300-4fea-897b-86f698d74461';
  static const String _vibrateCharUuid = '156e1001-a300-4fea-897b-86f698d74461';
  static const String _beepCharUuid = '156e1002-a300-4fea-897b-86f698d74461';
  static const String _shockCharUuid = '156e1003-a300-4fea-897b-86f698d74461';
  
  // キャラクタリスティックID（末尾4桁）- 後方互換性のため残す
  static const String _unlockCharId = '7001';
  static const String _handshakeCharId = '1005';
  static const String _vibrateCharId = '1001';
  static const String _beepCharId = '1002';
  static const String _shockCharId = '1003';
  
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
  /// Returns: 検出された全てのBluetoothデバイスのリスト（Service UUID `156e1000-a300-4fea-897b-86f698d74461` を持つデバイスを優先）
  Future<List<ScanResult>> scanForPavlokDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      print('[PavlokBleService] ========================================');
      print('[PavlokBleService] [START] Bluetoothデバイスをスキャン開始');
      print('[PavlokBleService] ターゲットService UUID: $pavlokServiceUuid');
      print('[PavlokBleService] タイムアウト: ${timeout.inSeconds}秒');
      print('[PavlokBleService] ========================================');
      
      if (!await isBluetoothEnabled()) {
        throw Exception('Bluetoothが有効になっていません');
      }

      final List<ScanResult> allDevices = [];
      final Set<String> seenDeviceIds = {};
      final targetServiceUuid = Guid(pavlokServiceUuid);

      // スキャン開始前に必ず停止（Mac特有の「消えるデバイス」対策）
      print('[PavlokBleService] 既存のスキャンを停止中...');
      await FlutterBluePlus.stopScan();
      
      // リストをクリア
      seenDeviceIds.clear();
      allDevices.clear();

      // Mac特有の「消えるデバイス」対策: 接続済みデバイスをチェック
      print('[PavlokBleService] 接続済みデバイスをチェック中...');
      try {
        final connectedDevices = await FlutterBluePlus.connectedDevices;
        print('[PavlokBleService] 接続済みデバイス数: ${connectedDevices.length}');
        
        for (final device in connectedDevices) {
          try {
            // サービス探索を実行してPavlokかどうか確認（タイムアウトを短く設定）
            final services = await device.discoverServices(timeout: 2);
            final hasPavlokService = services.any((service) => 
              service.uuid.toString().toLowerCase() == pavlokServiceUuid.toLowerCase()
            );
            
            if (hasPavlokService) {
              final deviceId = device.remoteId.toString();
              if (!seenDeviceIds.contains(deviceId)) {
                // 接続済みデバイスからScanResultを作成
                // 接続済みデバイスの場合、実際のAdvertisementDataは取得できないため、
                // 最小限の情報で構築します（サービス探索で既にPavlokであることが確認済み）
                try {
                  // 接続済みデバイスからScanResultを作成
                  // Note: 実際のAdvertisementDataは取得できないため、最小限の情報で構築
                  final now = DateTime.now();
                  final scanResult = ScanResult(
                    device: device,
                    advertisementData: AdvertisementData(
                      advName: device.platformName.isNotEmpty ? device.platformName : 'Pavlok 3',
                      appearance: 0,
                      serviceUuids: [targetServiceUuid],
                      manufacturerData: {},
                      serviceData: {},
                      txPowerLevel: null,
                      connectable: true,
                    ),
                    rssi: 0,
                    timeStamp: now,
                  );
                  allDevices.add(scanResult);
                  seenDeviceIds.add(deviceId);
                  
                  final deviceName = device.platformName.isNotEmpty
                      ? device.platformName
                      : '名前なし';
                  final deviceIdPrefix = deviceId.length >= 4 
                      ? deviceId.substring(0, 4).toUpperCase()
                      : deviceId.toUpperCase();
                  print('[PavlokBleService] ✅ 接続済みPavlok 3 を発見: $deviceName (PAVLOK-3-$deviceIdPrefix)');
                  print('[PavlokBleService]   判定理由: 接続済みデバイスのService UUID一致');
                } catch (e) {
                  // ScanResult作成エラー時はスキップ（AdvertisementDataのコンストラクタエラー等）
                  print('[PavlokBleService] 接続済みデバイスのScanResult作成エラー（スキップ）: $e');
                }
              }
            }
          } catch (e) {
            // サービス探索エラー時はスキップ（タイムアウト等）
            print('[PavlokBleService] 接続済みデバイスのサービス探索エラー（スキップ）: $e');
          }
        }
      } catch (e) {
        print('[PavlokBleService] 接続済みデバイスの取得エラー（続行）: $e');
      }

      print('[PavlokBleService] Pavlok 3 デバイスをスキャンします（アプリ側フィルタリング）');

      // スキャン開始（すべてのデバイスをスキャンし、アプリ側でフィルタリング）
      // withServicesを削除することで、Service UUIDをアドバタイズしていないデバイスも検出可能
      await FlutterBluePlus.startScan(
        timeout: timeout,
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

            // デバイス情報を取得
            final deviceName = scanResult.device.platformName;
            final deviceIdStr = scanResult.device.remoteId.toString();
            final deviceIdPrefix = deviceIdStr.length >= 4 
                ? deviceIdStr.substring(0, 4).toUpperCase()
                : deviceIdStr.toUpperCase();
            
            // 検出されたBluetoothデバイスの詳細情報をログ出力
            final displayName = deviceName.isNotEmpty ? deviceName : '名前なし';
            final localName = scanResult.advertisementData.localName;
            final serviceUuids = scanResult.advertisementData.serviceUuids.map((u) => u.toString()).toList();
            final rssi = scanResult.rssi;
            final connectable = scanResult.advertisementData.connectable;
            
            print('[PavlokBleService] 📱 検出されたBluetoothデバイス:');
            print('[PavlokBleService]   - デバイス名: $displayName');
            if (localName.isNotEmpty && localName != displayName) {
              print('[PavlokBleService]   - ローカル名: $localName');
            }
            print('[PavlokBleService]   - デバイスID: $deviceId ($deviceIdPrefix)');
            print('[PavlokBleService]   - RSSI: $rssi dBm');
            print('[PavlokBleService]   - 接続可能: $connectable');
            print('[PavlokBleService]   - サービスUUID数: ${serviceUuids.length}');
            if (serviceUuids.isNotEmpty) {
              print('[PavlokBleService]   - サービスUUID一覧:');
              for (final uuid in serviceUuids) {
                print('[PavlokBleService]     * $uuid');
              }
            } else {
              print('[PavlokBleService]   - サービスUUID: なし');
            }
            print('[PavlokBleService]   - 製造者データ: ${scanResult.advertisementData.manufacturerData}');
            print('[PavlokBleService]   - サービスデータ: ${scanResult.advertisementData.serviceData}');
            
            // 厳格なフィルタリング条件: 名前条件またはUUID条件のいずれかを満たす場合のみ追加
            // 名前条件: platformNameに"Pavlok-3"が含まれる
            final hasPavlokInName = deviceName.toLowerCase().contains('pavlok-3');
            
            // UUID条件: serviceUuidsにMain Control Service UUIDが含まれる
            final hasPavlokService = scanResult.advertisementData.serviceUuids
                .any((uuid) => uuid.toString().toLowerCase() == pavlokServiceUuid.toLowerCase());
            
            // 条件に合致する場合のみ追加
            if (hasPavlokInName || hasPavlokService) {
              seenDeviceIds.add(deviceId);
              allDevices.add(scanResult);
              
              // Pavlokとして認定されたデバイスのみ詳細ログを出力
              print('[PavlokBleService] ✅ Pavlok 3 として認定: $displayName (PAVLOK-3-$deviceIdPrefix)');
              if (hasPavlokService) {
                print('[PavlokBleService]   判定理由: Service UUID一致');
              } else if (hasPavlokInName) {
                print('[PavlokBleService]   判定理由: デバイス名に"Pavlok-3"が含まれています');
              }
              developer.log(
                'Pavlok 3 デバイス発見: $displayName (PAVLOK-3-$deviceIdPrefix, ${scanResult.device.remoteId})',
                name: 'PavlokBleService',
              );
            } else {
              print('[PavlokBleService] ❌ Pavlok 3 の条件に合致しません（リストに追加しません）');
            }
            print('[PavlokBleService] ---');
          }
        }
      } on TimeoutException {
        // タイムアウト時は既に収集したデバイスリストを返す
        print('[PavlokBleService] ⏱️ スキャンタイムアウト: ${timeout.inSeconds}秒経過');
        print('[PavlokBleService] これまでに発見されたデバイス数: ${allDevices.length}');
        developer.log(
          'スキャンタイムアウト: ${timeout.inSeconds}秒経過、発見されたデバイス数: ${allDevices.length}',
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
      print('[PavlokBleService] 発見されたBluetoothデバイス数: ${allDevices.length}');
      print('[PavlokBleService] ========================================');

      if (allDevices.isEmpty) {
        print('[PavlokBleService] ⚠️ Bluetoothデバイス（Service UUID: $pavlokServiceUuid）が見つかりませんでした');
        print('[PavlokBleService] 確認事項:');
        print('[PavlokBleService] 1. Bluetoothが有効になっているか');
        print('[PavlokBleService] 2. Pavlok 3デバイスが電源オンで、ペアリング可能な状態か');
        print('[PavlokBleService] 3. macOSの「システム設定 > プライバシーとセキュリティ > Bluetooth」');
        print('[PavlokBleService]    で「Runner」または「useful_pavlok」に権限が与えられているか');
      } else {
        print('[PavlokBleService] ✅ スキャン成功: ${allDevices.length}台のBluetoothデバイスを発見');
      }

      return allDevices;
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

      // ステップ4: 仕様書に基づくキャラクタリスティックを探索（UUID末尾4桁ベース）
      print('[PavlokBleService] [STEP 4] 仕様書に基づくキャラクタリスティックを探索中...');
      
      // 全サービスから必要なキャラクタリスティックを探索
      _unlockCharacteristic = _findCharacteristicByLast4Digits(services, '7001');
      _handshakeCharacteristic = _findCharacteristicByLast4Digits(services, '1005');
      _vibrateCharacteristic = _findCharacteristicByLast4Digits(services, '1001');
      _beepCharacteristic = _findCharacteristicByLast4Digits(services, '1002');
      _shockCharacteristic = _findCharacteristicByLast4Digits(services, '1003');
      
      // 後方互換性のため_commandCharacteristicも設定（vibrateCharacteristicを使用）
      _commandCharacteristic = _vibrateCharacteristic;

      print('[PavlokBleService] [STEP 4] ✅ キャラクタリスティック探索完了');
      print('[PavlokBleService]   Unlock (7001): ${_unlockCharacteristic != null ? "✅" : "❌"}');
      print('[PavlokBleService]   Handshake (1005): ${_handshakeCharacteristic != null ? "✅" : "❌"}');
      print('[PavlokBleService]   Vibrate (1001): ${_vibrateCharacteristic != null ? "✅" : "❌"}');
      print('[PavlokBleService]   Beep (1002): ${_beepCharacteristic != null ? "✅" : "❌"}');
      print('[PavlokBleService]   Shock (1003): ${_shockCharacteristic != null ? "✅" : "❌"}');
      
      if (_unlockCharacteristic == null) {
        throw Exception('Unlockキャラクタリスティック（7001）が見つかりません');
      }
      if (_vibrateCharacteristic == null && _beepCharacteristic == null && _shockCharacteristic == null) {
        throw Exception('コマンド送信用のキャラクタリスティックが見つかりません');
      }
      
      developer.log(
        'キャラクタリスティック探索完了: Unlock=${_unlockCharacteristic != null}, Vibrate=${_vibrateCharacteristic != null}, Beep=${_beepCharacteristic != null}, Shock=${_shockCharacteristic != null}',
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
      // キャッシュをクリア
      _cachedServices = null;
      _unlockCharacteristic = null;
      _handshakeCharacteristic = null;
      _vibrateCharacteristic = null;
      _beepCharacteristic = null;
      _shockCharacteristic = null;
    }
  }

  /// Step 1: Unlock（認証）
  Future<void> unlock() async {
    // サービス探索の同期管理
    if (_connectedDevice == null) {
      throw Exception('Device not connected');
    }
    
    // サービス取得（キャッシュ利用）
    final services = await _getOrDiscoverServices();
    
    // デバッグログ: すべてのサービスとキャラクタリスティックを出力（サービス構造の確認用）
    // 本番環境では無効化してパフォーマンスを向上
    if (kDebugMode) {
      print('[Pavlok] [Unlock] [DEBUG] Service structure discovery:');
      for (final service in services) {
        print('[Pavlok] [Unlock] [DEBUG] Service: ${service.uuid}');
        for (final chr in service.characteristics) {
          final shortId = _extractCharacteristicId(chr.uuid.toString());
          print('[Pavlok] [Unlock] [DEBUG]   - Characteristic: ${chr.uuid} (UUID末尾4桁: $shortId)');
        }
      }
    }
    
    // 認証サービス（156e7000）を検索 - Pavlok ID一致ベースで誤マッチを防ぐ
    print('[Pavlok] [Unlock] Searching for service: ${_authServiceUuid} (target Pavlok ID: 7000)');
    BluetoothService? authService = _findServiceByUuid(services, _authServiceUuid);
    
    // フォールバック: 156e7000が見つからない場合、156e1000内で7001を検索
    if (authService == null) {
      print('[Pavlok] [Unlock] Service 156e7000 (Pavlok ID: 7000) not found, trying fallback to 156e1000...');
      final controlService = _findServiceByUuid(services, _controlServiceUuid);
      if (controlService != null) {
        print('[Pavlok] [Unlock] Service 156e1000 found, searching for 7001 (Pavlok ID) inside...');
        // 156e1000内で7001を検索（Pavlok IDベース）
        final fallbackChar = _findCharacteristicByUuid(controlService.characteristics, _unlockCharUuid);
        if (fallbackChar == null) {
          // 短縮IDでも試行
          final fallbackCharById = _findCharacteristicById(controlService.characteristics, _unlockCharId);
          if (fallbackCharById != null) {
            print('[Pavlok] [Unlock] ✓ Found 7001 in service 156e1000 (fallback, by short ID)');
            authService = controlService;
          }
        } else {
          print('[Pavlok] [Unlock] ✓ Found 7001 in service 156e1000 (fallback, by UUID)');
          authService = controlService;
        }
      }
    }
    
    if (authService == null) {
      print('[Pavlok] [Unlock] ERROR: Service 156e7000 (Pavlok ID: 7000) not found!');
      print('[Pavlok] [Unlock] Available services:');
      for (final service in services) {
        final servicePavlokId = _extractPavlokId(service.uuid.toString());
        print('[Pavlok] [Unlock]   - Service: ${service.uuid} (Pavlok ID: $servicePavlokId)');
      }
      throw Exception('Auth service (156e7000, Pavlok ID: 7000) not found');
    }

    final servicePavlokId = _extractPavlokId(authService.uuid.toString());
    print('[Pavlok] [Unlock] ✓ Service found: ${authService.uuid} (Pavlok ID: $servicePavlokId)');
    
    // 認証サービス内のキャラクタリスティック一覧を表示
    print('[Pavlok] [Unlock] Characteristics in service ${authService.uuid}:');
    for (final chr in authService.characteristics) {
      final chrPavlokId = _extractPavlokId(chr.uuid.toString());
      final shortId = _extractCharacteristicId(chr.uuid.toString());
      print('[Pavlok] [Unlock]   - ${chr.uuid} (Pavlok ID: $chrPavlokId, UUID末尾4桁: $shortId)');
    }

    // キャラクタリスティック検索: 完全UUID → Pavlok ID一致の順で試行
    BluetoothCharacteristic? unlockChar;
    
    // 方法1: 完全UUIDで検索（Pavlok ID一致も含む）
    print('[Pavlok] [Unlock] Searching for characteristic: ${_unlockCharUuid} (target Pavlok ID: 7001)');
    unlockChar = _findCharacteristicByUuid(authService.characteristics, _unlockCharUuid);
    
    // 方法2: 短縮ID（7001）で検索（完全UUIDで見つからない場合）
    if (unlockChar == null) {
      print('[Pavlok] [Unlock] Characteristic not found by UUID, trying by short ID: ${_unlockCharId}');
      unlockChar = _findCharacteristicById(authService.characteristics, _unlockCharId);
    }
    
    if (unlockChar == null) {
      print('[Pavlok] [Unlock] ERROR: Characteristic 156e7001 (Pavlok ID: 7001) not found');
      print('[Pavlok] [Unlock] Available characteristics in service ${authService.uuid}:');
      for (final chr in authService.characteristics) {
        final chrPavlokId = _extractPavlokId(chr.uuid.toString());
        final shortId = _extractCharacteristicId(chr.uuid.toString());
        print('[Pavlok] [Unlock]   - ${chr.uuid} (Pavlok ID: $chrPavlokId, UUID末尾4桁: $shortId)');
      }
      throw Exception('Unlock characteristic (156e7001, Pavlok ID: 7001) not found.');
    }
    
    final foundPavlokId = _extractPavlokId(unlockChar.uuid.toString());
    print('[Pavlok] [Unlock] ✓ Characteristic found: ${unlockChar.uuid} (Pavlok ID: $foundPavlokId)');

    // **必須の準備シーケンス**: 7001への書き込み直前に、必ずsetNotifyValue(true)を実行
    print('[Pavlok] [Unlock] 🔐 Executing required preparation sequence: setNotifyValue(true)');
    try {
      await unlockChar.setNotifyValue(true);
      print('[Pavlok] [Unlock] ✓ Notify enabled for unlock (required preparation)');
    } catch (e) {
      print('[Pavlok] [Unlock] ⚠️ Failed to enable notify, but continuing: $e');
      // エラーが発生しても続行（一部のデバイスではnotifyがサポートされていない場合がある）
    }

    // Unlockデータの準備とログ出力
    final unlockData = Uint8List.fromList([0x12, 0x0d, 0xa0, 0x48, 0xad, 0x69, 0xe4]);
    final unlockDataHex = unlockData.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');
    final targetUuid = unlockChar.uuid.toString();
    
    print('[Pavlok] [Unlock] 📤 Sending Unlock packet:');
    print('[Pavlok] [Unlock]   - Target UUID: $targetUuid');
    print('[Pavlok] [Unlock]   - Data length: ${unlockData.length} bytes');
    print('[Pavlok] [Unlock]   - Data: [$unlockDataHex]');

    // Unlockパケット送信
    if (unlockChar.properties.write) {
      await unlockChar.write(unlockData, withoutResponse: false);
    } else if (unlockChar.properties.writeWithoutResponse) {
      await unlockChar.write(unlockData, withoutResponse: true);
    } else {
      throw Exception('Unlock characteristic does not support write');
    }

    print('[Pavlok] [Unlock] ✓ Unlock packet sent, waiting 200ms for device to be ready...');
    // **必須**: Unlockパケット送信後、メインコマンドを送る前に200ms待機（最適化: 500ms → 200ms）
    await Future.delayed(const Duration(milliseconds: 200));
    print('[Pavlok3Controller] ✓ Unlocked and ready for commands');
  }

  /// 共通Step 1: Unlockを送信します（後方互換性のため残す）
  /// 
  /// サービス7000...の7001へ[0x12, 0x0d, 0xa0, 0x48, 0xad, 0x69, 0xe4]を送信し、500ms待機
  Future<void> _sendUnlock() async {
    await unlock();
  }

  /// Step 2: Handshake（セッション維持）
  Future<void> handshake() async {
    // サービス探索の同期管理
    if (_connectedDevice == null) {
      throw Exception('Device not connected');
    }
    
    // サービス取得（キャッシュ利用）
    final services = await _getOrDiscoverServices();
    
    // 完全UUIDで制御サービスを検索
    final controlService = _findServiceByUuid(services, _controlServiceUuid);
    if (controlService == null) {
      throw Exception('Control service (156e1000) not found');
    }

    // 完全UUIDでHandshakeキャラクタリスティックを検索
    final handshakeChar = _findCharacteristicByUuid(controlService.characteristics, _handshakeCharUuid);
    if (handshakeChar == null) {
      print('[Pavlok] [Handshake] Characteristic 156e1005 not found');
      print('[Pavlok] [Handshake] Available characteristics:');
      for (final chr in controlService.characteristics) {
        print('[Pavlok] [Handshake]   - ${chr.uuid.toString()}');
      }
      throw Exception('Handshake characteristic (156e1005) not found');
    }

    final handshakeData = Uint8List.fromList([0x18, 0x02, 0x20, 0x17, 0x06, 0x01, 0x26, 0xe0]);

    if (handshakeChar.properties.write) {
      await handshakeChar.write(handshakeData, withoutResponse: false);
    } else if (handshakeChar.properties.writeWithoutResponse) {
      await handshakeChar.write(handshakeData, withoutResponse: true);
    } else {
      throw Exception('Handshake characteristic does not support write');
    }

    await Future.delayed(const Duration(milliseconds: 50)); // 最適化: 100ms → 50ms
    print('[Pavlok3Controller] ✓ Handshake completed');
  }

  /// Shock専用Step 2: Handshakeを送信します（後方互換性のため残す）
  /// 
  /// サービス1000...の1005へ[0x18, 0x02, 0x20, 0x17, 0x06, 0x01, 0x26, 0xe0]を送信し、100ms待機
  Future<void> _sendHandshake() async {
    await handshake();
  }

  /// Step 3: Vibrate（振動）
  /// 
  /// [intensity] 0-100 の強度を指定
  /// [autoUnlock] 自動的にUnlockを実行するか（デフォルト: true）
  Future<void> triggerVibrate(int intensity, {bool autoUnlock = true}) async {
    try {
      // 1. 接続状態確認
      if (_connectedDevice == null) {
        throw Exception('Device not connected');
      }

      // 2. 自動認証（オプション）
      if (autoUnlock) {
        print('[Pavlok] [Vibrate] Auto-unlocking device...');
        await unlock();
        await Future.delayed(const Duration(milliseconds: 50)); // 認証後の待機（最適化: 100ms → 50ms）
      }

      // 3. レベルクランプ
      final clampedLevel = intensity.clamp(0, 100);

      // 4. データ準備
      final bytes = Uint8List.fromList([0x81, 0x0c, clampedLevel, 0x16, 0x16]);
      final bytesHexString = bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');

      // 5. サービス取得（キャッシュ利用）
      final services = await _getOrDiscoverServices();
      
      final service = _findServiceByUuid(services, _controlServiceUuid);
      if (service == null) {
        throw Exception('Service 156e1000 not found');
      }

      // 6. キャラクタリスティック検索（完全UUIDベース）
      final characteristic = _findCharacteristicByUuid(service.characteristics, _vibrateCharUuid);
      
      if (characteristic == null) {
        // デバッグ出力: 利用可能なキャラクタリスティックを表示
        print('[Pavlok] [Vibrate] Characteristic 156e1001 not found');
        print('[Pavlok] [Vibrate] Available characteristics:');
        for (final chr in service.characteristics) {
          print('[Pavlok] [Vibrate]   - ${chr.uuid.toString()}');
        }
        throw Exception('Vibrate characteristic (156e1001) not found');
      }

      // 7. デバッグ出力（送信直前の詳細ログ）
      final targetUuid = characteristic.uuid.toString();
      print('[Pavlok] [Vibrate] 📤 Sending Vibrate command:');
      print('[Pavlok] [Vibrate]   - Target UUID: $targetUuid');
      print('[Pavlok] [Vibrate]   - Data length: ${bytes.length} bytes');
      print('[Pavlok] [Vibrate]   - Data: [$bytesHexString]');
      print('[Pavlok] [Vibrate]   - Level: $clampedLevel (0x${clampedLevel.toRadixString(16).padLeft(2, '0')})');
      print('[Pavlok] [Vibrate]   - UUID末尾4桁: 1001');

      // 8. 書き込みプロパティ確認
      if (!characteristic.properties.write && !characteristic.properties.writeWithoutResponse) {
        throw Exception('Vibrate characteristic is not writable');
      }

      // 9. 書き込み実行（writeWithoutResponseが優先）
      if (characteristic.properties.writeWithoutResponse) {
        await characteristic.write(bytes, withoutResponse: true);
      } else {
        await characteristic.write(bytes, withoutResponse: false);
      }

      print('[Pavlok] [Vibrate] ✓ Success: VIBRATE $clampedLevel% sent to $targetUuid (${bytes.length} bytes)');
    } catch (e) {
      print('[Pavlok Error] [Vibrate] Vibrate command failed: $e');
      rethrow;
    }
  }

  /// Step 3: Beep（ビープ音）
  /// 
  /// [intensity] 0-100 の強度を指定
  /// [autoUnlock] 自動的にUnlockを実行するか（デフォルト: true）
  Future<void> triggerAlarm(int intensity, {bool autoUnlock = true}) async {
    try {
      // 1. 接続状態確認
      if (_connectedDevice == null) {
        throw Exception('Device not connected');
      }

      // 2. 自動認証（オプション）
      if (autoUnlock) {
        print('[Pavlok] [Beep] Auto-unlocking device...');
        await unlock();
        await Future.delayed(const Duration(milliseconds: 50)); // 認証後の待機（最適化: 100ms → 50ms）
      }

      // 3. レベルクランプ
      final clampedLevel = intensity.clamp(0, 100);

      // 4. データ準備（Vibrateと同じ形式）
      final bytes = Uint8List.fromList([0x81, 0x0c, clampedLevel, 0x16, 0x16]);
      final bytesHexString = bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');

      // 5. サービス取得（キャッシュ利用）
      final services = await _getOrDiscoverServices();
      
      final service = _findServiceByUuid(services, _controlServiceUuid);
      if (service == null) {
        throw Exception('Service 156e1000 not found');
      }

      // 6. キャラクタリスティック検索（完全UUIDベース：156e1002）
      final characteristic = _findCharacteristicByUuid(service.characteristics, _beepCharUuid);
      
      if (characteristic == null) {
        // デバッグ出力: 利用可能なキャラクタリスティックを表示
        print('[Pavlok] [Beep] Characteristic 156e1002 not found');
        print('[Pavlok] [Beep] Available characteristics:');
        for (final chr in service.characteristics) {
          print('[Pavlok] [Beep]   - ${chr.uuid.toString()}');
        }
        throw Exception('Beep characteristic (156e1002) not found');
      }

      // 7. デバッグ出力（送信直前の詳細ログ）
      final targetUuid = characteristic.uuid.toString();
      print('[Pavlok] [Beep] 📤 Sending Beep command:');
      print('[Pavlok] [Beep]   - Target UUID: $targetUuid');
      print('[Pavlok] [Beep]   - Data length: ${bytes.length} bytes');
      print('[Pavlok] [Beep]   - Data: [$bytesHexString]');
      print('[Pavlok] [Beep]   - Level: $clampedLevel (0x${clampedLevel.toRadixString(16).padLeft(2, '0')})');
      print('[Pavlok] [Beep]   - UUID末尾4桁: 1002');

      // 8. 書き込みプロパティ確認
      if (!characteristic.properties.write && !characteristic.properties.writeWithoutResponse) {
        throw Exception('Beep characteristic is not writable');
      }

      // 9. 書き込み実行（writeWithoutResponseが優先）
      if (characteristic.properties.writeWithoutResponse) {
        await characteristic.write(bytes, withoutResponse: true);
      } else {
        await characteristic.write(bytes, withoutResponse: false);
      }

      print('[Pavlok] [Beep] ✓ Success: BEEP $clampedLevel% sent to $targetUuid (${bytes.length} bytes)');
    } catch (e) {
      print('[Pavlok Error] [Beep] Beep command failed: $e');
      rethrow;
    }
  }

  /// Step 3: Shock（電気ショック）
  /// 
  /// [intensity] 0-100 の強度を指定
  /// [autoUnlock] 自動的にUnlockを実行するか（デフォルト: true）
  /// 注意: Handshake が必須です
  Future<void> triggerShock(int intensity, {bool autoUnlock = true}) async {
    try {
      // 1. 接続状態確認
      if (_connectedDevice == null) {
        throw Exception('Device not connected');
      }

      // 2. Step 1: Unlock（認証）
      if (autoUnlock) {
        print('[Pavlok] [Shock] Step 1: Unlocking device...');
        await unlock();
        await Future.delayed(const Duration(milliseconds: 50)); // 認証後の待機（最適化: 100ms → 50ms）
      }

      // 3. Step 2: Handshake（セッション維持） - **必須**
      print('[Pavlok] [Shock] Step 2: Sending handshake to Status (1005)...');
      await handshake();
      await Future.delayed(const Duration(milliseconds: 50)); // ハンドシェイク後の待機（最適化: 100ms → 50ms）

      // 4. Step 3: Shock送信準備
      print('[Pavlok] [Shock] Step 3: Sending shock command to 1003...');
      
      // レベルクランプ
      final clampedLevel = intensity.clamp(0, 100);

      // **重要**: 2バイトのみ送信（パディング禁止）- 厳格に2バイトのみ
      final bytes = Uint8List.fromList([0x81, clampedLevel]);
      final bytesHexString = bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');
      
      // データ長の厳格な確認（2バイトのみであることを保証）
      assert(bytes.length == 2, 'Shock data must be exactly 2 bytes, got ${bytes.length}');
      if (bytes.length != 2) {
        throw Exception('Shock data must be exactly 2 bytes, got ${bytes.length}. Padding is forbidden.');
      }

      // 5. サービス取得（キャッシュ利用）
      final services = await _getOrDiscoverServices();
      
      final service1000 = _findServiceByUuid(services, _controlServiceUuid);
      if (service1000 == null) {
        throw Exception('Service 156e1000 not found');
      }

      // 6. キャラクタリスティック検索（完全UUIDベース：156e1003）
      final shockCharacteristic = _findCharacteristicByUuid(service1000.characteristics, _shockCharUuid);

      if (shockCharacteristic == null) {
        print('[Pavlok] [Shock] Characteristic 156e1003 not found');
        print('[Pavlok] [Shock] Available characteristics:');
        for (final chr in service1000.characteristics) {
          print('[Pavlok] [Shock]   - ${chr.uuid.toString()}');
        }
        throw Exception('Shock characteristic (156e1003) not found');
      }

      // 7. デバッグ出力（送信直前の詳細ログ - 2バイト厳守を証明）
      final targetUuid = shockCharacteristic.uuid.toString();
      print('[Pavlok] [Shock] 📤 Sending Shock command:');
      print('[Pavlok] [Shock]   - Target UUID: $targetUuid');
      print('[Pavlok] [Shock]   - Data length: ${bytes.length} bytes (MUST be 2 bytes, no padding)');
      print('[Pavlok] [Shock]   - Data: [$bytesHexString]');
      print('[Pavlok] [Shock]   - Level: $clampedLevel (0x${clampedLevel.toRadixString(16).padLeft(2, '0')})');
      print('[Pavlok] [Shock]   - UUID末尾4桁: 1003');
      print('[Pavlok] [Shock] ✅ Data length verified: ${bytes.length} bytes (correct)');

      // 8. 書き込みプロパティ確認
      if (!shockCharacteristic.properties.write && !shockCharacteristic.properties.writeWithoutResponse) {
        throw Exception('Shock characteristic is not writable');
      }

      // 9. 書き込み実行（**2バイトのみ**、writeを優先）
      if (shockCharacteristic.properties.write) {
        await shockCharacteristic.write(bytes, withoutResponse: false);
      } else {
        await shockCharacteristic.write(bytes, withoutResponse: true);
      }

      print('[Pavlok] [Shock] ✓ Success: SHOCK $clampedLevel% sent to $targetUuid (${bytes.length} bytes, verified)');
    } catch (e) {
      print('[Pavlok Error] [Shock] Shock command failed: $e');
      rethrow;
    }
  }
  
  /// スニッフィングされたバイブデータを直接送信します（後方互換性のため残す）
  Future<void> sendSniffedVibrateData() async {
    // 新しい仕様に基づくtriggerVibrateを使用
    await triggerVibrate(50); // デフォルト強度50%
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

  /// サービスとキャラクタリスティックを取得（キャッシュ利用）
  /// 
  /// キャッシュがあればそれを使用し、なければ探索してキャッシュします。
  /// これにより、discoverServices()の繰り返し呼び出しを削減します。
  Future<List<BluetoothService>> _getOrDiscoverServices() async {
    if (_connectedDevice == null) {
      throw Exception('Device not connected');
    }

    // キャッシュがあればそれを使用
    if (_cachedServices != null && _cachedServices!.isNotEmpty) {
      return _cachedServices!;
    }

    // キャッシュがない場合、探索してキャッシュ
    _cachedServices = await _connectedDevice!.discoverServices(timeout: 5);
    return _cachedServices!;
  }

  /// UUIDを正規化（ハイフンの有無に左右されない比較のため）
  String _normalizeUuid(String uuid) {
    // ハイフンを削除して小文字化
    return uuid.toLowerCase().replaceAll('-', '');
  }

  /// 2つのUUIDが一致するか確認（正規化後）
  bool _uuidMatches(String uuid1, String uuid2) {
    return _normalizeUuid(uuid1) == _normalizeUuid(uuid2);
  }

  /// UUID末尾4桁を抽出（後方互換性のため残す）
  String _extractCharacteristicId(String uuid) {
    final uuidClean = uuid.toLowerCase().replaceAll('-', '');
    if (uuidClean.length >= 4) {
      return uuidClean.substring(uuidClean.length - 4);
    }
    return uuidClean;
  }

  /// Pavlok用のID抽出: 156eXXXX形式からXXXXを抽出、または短縮表記をそのまま返す
  /// 
  /// 例:
  /// - "156e7001-a300-4fea-897b-86f698d74461" → "7001"
  /// - "7001" → "7001"
  /// - "1001" → "1001"
  String _extractPavlokId(String uuidString) {
    final normalized = uuidString.toLowerCase().replaceAll('-', '');
    
    // 短縮表記（4桁の16進数）の場合はそのまま返す
    if (normalized.length == 4 && RegExp(r'^[0-9a-f]{4}$').hasMatch(normalized)) {
      return normalized;
    }
    
    // 156eXXXX形式の場合、156e直後の4桁（位置4-8）を抽出
    if (normalized.startsWith('156e') && normalized.length >= 8) {
      return normalized.substring(4, 8);
    }
    
    // それ以外は従来の末尾4桁を返す（デバッグ用、誤マッチには使わない）
    if (normalized.length >= 4) {
      return normalized.substring(normalized.length - 4);
    }
    
    return normalized;
  }

  /// サービスを完全UUIDで検索（Pavlok ID一致ベースのフォールバック）
  BluetoothService? _findServiceByUuid(
    List<BluetoothService> services,
    String targetUuid,
  ) {
    print('[Discovery] Searching for service: $targetUuid');
    final targetPavlokId = _extractPavlokId(targetUuid);
    print('[Discovery] Target Pavlok ID: $targetPavlokId');
    print('[Discovery] Available services (${services.length} total):');
    
    for (final service in services) {
      final serviceUuid = service.uuid.toString();
      final servicePavlokId = _extractPavlokId(serviceUuid);
      print('[Discovery] Found Service: $serviceUuid (Pavlok ID: $servicePavlokId)');
      
      // 方法1: 完全UUIDマッチング（優先）
      if (_uuidMatches(serviceUuid, targetUuid)) {
        print('[Discovery] ✅ Service matched (exact UUID): $serviceUuid');
        return service;
      }
      
      // 方法2: Pavlok ID一致（フォールバック）- 誤マッチを防ぐためcontains()は使わない
      if (servicePavlokId == targetPavlokId) {
        print('[Discovery] ✅ Service matched (Pavlok ID match): $serviceUuid (ID: $servicePavlokId)');
        return service;
      }
    }
    
    print('[Discovery] ❌ Service not found: $targetUuid (target Pavlok ID: $targetPavlokId)');
    print('[Discovery] Searched ${services.length} services, but none matched');
    return null;
  }

  /// キャラクタリスティックを完全UUIDで検索（Pavlok ID一致ベースのフォールバック）
  BluetoothCharacteristic? _findCharacteristicByUuid(
    List<BluetoothCharacteristic> characteristics,
    String targetUuid,
  ) {
    final targetPavlokId = _extractPavlokId(targetUuid);
    
    for (final chr in characteristics) {
      final chrUuid = chr.uuid.toString();
      final chrPavlokId = _extractPavlokId(chrUuid);
      
      // 方法1: 完全UUIDマッチング（優先）
      if (_uuidMatches(chrUuid, targetUuid)) {
        print('[Discovery] ✅ Characteristic matched (exact UUID): $chrUuid (Pavlok ID: $chrPavlokId)');
        return chr;
      }
      
      // 方法2: Pavlok ID一致（フォールバック）- 誤マッチを防ぐためcontains()は使わない
      if (chrPavlokId == targetPavlokId) {
        print('[Discovery] ✅ Characteristic matched (Pavlok ID match): $chrUuid (ID: $chrPavlokId)');
        return chr;
      }
    }
    return null;
  }

  /// キャラクタリスティックを検索（UUID末尾4桁ベース）- 後方互換性のため残す
  BluetoothCharacteristic? _findCharacteristicById(
    List<BluetoothCharacteristic> characteristics,
    String targetId,
  ) {
    for (final chr in characteristics) {
      final shortId = _extractCharacteristicId(chr.uuid.toString());
      if (shortId == targetId.toLowerCase()) {
        return chr;
      }
    }
    return null;
  }

  /// UUIDの末尾4桁を取得します（後方互換性のため残す）
  /// 
  /// [uuid] Guidまたは文字列
  /// Returns: 末尾4桁（例: "7001"）
  String _getLast4Digits(dynamic uuid) {
    final uuidStr = uuid.toString().toUpperCase();
    // UUID形式から末尾4桁を抽出（例: "00007001-0000-1000-8000-00805f9b34fb" → "7001"）
    final parts = uuidStr.split('-');
    if (parts.isNotEmpty) {
      final firstPart = parts[0];
      if (firstPart.length >= 4) {
        return firstPart.substring(firstPart.length - 4);
      }
    }
    return '';
  }

  /// 末尾4桁ベースでキャラクタリスティックを検索します
  /// 
  /// [services] サービスリスト
  /// [last4Digits] 末尾4桁（例: "7001"）
  /// Returns: 見つかったキャラクタリスティック、見つからない場合はnull
  BluetoothCharacteristic? _findCharacteristicByLast4Digits(
    List<BluetoothService> services,
    String last4Digits,
  ) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final charLast4 = _getLast4Digits(characteristic.uuid);
        if (charLast4 == last4Digits) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            print('[PavlokBleService] ✅ キャラクタリスティック${last4Digits}を発見: ${characteristic.uuid}');
            return characteristic;
          }
        }
      }
    }
    print('[PavlokBleService] ⚠️ キャラクタリスティック${last4Digits}が見つかりませんでした');
    return null;
  }

  /// 指定されたサービス内で書き込み可能なキャラクタリスティックを検索します（後方互換性のため残す）
  BluetoothCharacteristic? _findWritableCharacteristicInService(
    BluetoothService service,
  ) {
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
