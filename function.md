# Pavlok 3 BLE コマンド実装コード

このドキュメントには、Pavlok 3デバイスへのShock、Vibrate、Beepコマンド送信の実装コードを記載しています。

## 定数定義

```dart
// サービスUUID
static const String _controlServiceUuid = '156e1000-a300-4fea-897b-86f698d74461'; // メイン制御サービス
static const String _authServiceUuid = '156e7000-a300-4fea-897b-86f698d74461'; // 認証サービス

// キャラクタリスティックUUID
static const String _vibrateCharUuid = '156e1001-a300-4fea-897b-86f698d74461'; // Vibrate
static const String _beepCharUuid = '156e1002-a300-4fea-897b-86f698d74461'; // Beep
static const String _shockCharUuid = '156e1003-a300-4fea-897b-86f698d74461'; // Shock
static const String _handshakeCharUuid = '156e1005-a300-4fea-897b-86f698d74461'; // Handshake
static const String _unlockCharUuid = '156e7001-a300-4fea-897b-86f698d74461'; // Unlock
```

## ヘルパーメソッド

### UUID正規化とマッチング

```dart
String _normalizeUuid(String uuid) {
  // ハイフンを削除して小文字化
  return uuid.toLowerCase().replaceAll('-', '');
}

bool _uuidMatches(String uuid1, String uuid2) {
  return _normalizeUuid(uuid1) == _normalizeUuid(uuid2);
}

String _extractCharacteristicId(String uuid) {
  final uuidClean = uuid.toLowerCase().replaceAll('-', '');
  if (uuidClean.length >= 4) {
    return uuidClean.substring(uuidClean.length - 4);
  }
  return uuidClean;
}
```

### サービス・キャラクタリスティック検索

```dart
BluetoothService? _findServiceByUuid(
  List<BluetoothService> services,
  String targetUuid,
) {
  print('[Discovery] Searching for service: $targetUuid');
  print('[Discovery] Available services (${services.length} total):');
  for (final service in services) {
    final serviceUuid = service.uuid.toString();
    print('[Discovery] Found Service: $serviceUuid');
    if (_uuidMatches(serviceUuid, targetUuid)) {
      print('[Discovery] ✅ Service matched: $serviceUuid');
      return service;
    }
  }
  print('[Discovery] ❌ Service not found: $targetUuid');
  print('[Discovery] Searched ${services.length} services, but none matched');
  return null;
}

BluetoothCharacteristic? _findCharacteristicByUuid(
  List<BluetoothCharacteristic> characteristics,
  String targetUuid,
) {
  for (final chr in characteristics) {
    if (_uuidMatches(chr.uuid.toString(), targetUuid)) {
      return chr;
    }
  }
  return null;
}
```

## Unlock（認証）

すべてのコマンドの前に実行される認証処理です。

```dart
/// Step 1: Unlock（認証）
Future<void> unlock() async {
  // サービス探索の同期管理
  if (_connectedDevice == null) {
    throw Exception('Device not connected');
  }
  
  if (_cachedServices == null || _cachedServices!.isEmpty) {
    print('[Pavlok] [Unlock] Services not discovered yet, discovering...');
    _cachedServices = await _connectedDevice!.discoverServices(timeout: 5);
    print('[Pavlok] [Unlock] Services discovered: ${_cachedServices!.length} services');
  }
  
  final services = _cachedServices!;
  
  // 完全UUIDで認証サービスを検索
  final authService = _findServiceByUuid(services, _authServiceUuid);
  if (authService == null) {
    print('[Pavlok] [Unlock] ERROR: Service 156e7000 not found!');
    print('[Pavlok] [Unlock] Available services:');
    for (final service in services) {
      print('[Pavlok] [Unlock]   - Service: ${service.uuid}');
    }
    throw Exception('Auth service (156e7000) not found');
  }

  // 認証サービス内のキャラクタリスティック一覧を表示
  print('[Pavlok] [Unlock] Service 156e7000 found. Characteristics:');
  for (final chr in authService.characteristics) {
    final shortId = _extractCharacteristicId(chr.uuid.toString());
    print('[Pavlok] [Unlock]   - ${chr.uuid} (short: $shortId)');
  }

  // 完全UUIDでUnlockキャラクタリスティックを検索
  final unlockChar = _findCharacteristicByUuid(authService.characteristics, _unlockCharUuid);
  if (unlockChar == null) {
    print('[Pavlok] [Unlock] ERROR: Characteristic 156e7001 not found in service 156e7000');
    print('[Pavlok] [Unlock] Available characteristics:');
    for (final chr in authService.characteristics) {
      final shortId = _extractCharacteristicId(chr.uuid.toString());
      print('[Pavlok] [Unlock]   - ${chr.uuid} (short: $shortId)');
    }
    throw Exception('Unlock characteristic (156e7001) not found');
  }

  // 通知を有効化（推奨）
  if (unlockChar.properties.notify) {
    try {
      await unlockChar.setNotifyValue(true);
      print('[Pavlok3Controller] ✓ Notify enabled for unlock');
    } catch (e) {
      print('[Pavlok3Controller] ⚠️ Failed to enable notify (continuing): $e');
    }
  }

  final unlockData = Uint8List.fromList([0x12, 0x0d, 0xa0, 0x48, 0xad, 0x69, 0xe4]);

  if (unlockChar.properties.write) {
    await unlockChar.write(unlockData, withoutResponse: false);
  } else if (unlockChar.properties.writeWithoutResponse) {
    await unlockChar.write(unlockData, withoutResponse: true);
  } else {
    throw Exception('Unlock characteristic does not support write');
  }

  await Future.delayed(const Duration(milliseconds: 500));
  print('[Pavlok3Controller] ✓ Unlocked');
}
```

## Handshake（セッション維持）

Shockコマンドの前に必須で実行される処理です。

```dart
/// Step 2: Handshake（セッション維持）
Future<void> handshake() async {
  // サービス探索の同期管理
  if (_connectedDevice == null) {
    throw Exception('Device not connected');
  }
  
  if (_cachedServices == null || _cachedServices!.isEmpty) {
    print('[Pavlok] [Handshake] Services not discovered yet, discovering...');
    _cachedServices = await _connectedDevice!.discoverServices(timeout: 5);
    print('[Pavlok] [Handshake] Services discovered: ${_cachedServices!.length} services');
  }
  
  final services = _cachedServices!;
  
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

  await Future.delayed(const Duration(milliseconds: 100));
  print('[Pavlok3Controller] ✓ Handshake completed');
}
```

## Vibrate（振動）

```dart
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
      await Future.delayed(const Duration(milliseconds: 100)); // 認証後の待機
    }

    // 3. レベルクランプ
    final clampedLevel = intensity.clamp(0, 100);

    // 4. データ準備
    final bytes = Uint8List.fromList([0x81, 0x0c, clampedLevel, 0x16, 0x16]);
    final bytesHexString = bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');

    // 5. サービス取得（キャッシュ利用）
    if (_cachedServices == null || _cachedServices!.isEmpty) {
      if (_connectedDevice == null) {
        throw Exception('Device not connected');
      }
      print('[Pavlok] [Vibrate] Services not discovered yet, discovering...');
      _cachedServices = await _connectedDevice!.discoverServices(timeout: 5);
      print('[Pavlok] [Vibrate] Services discovered: ${_cachedServices!.length} services');
    }
    final services = _cachedServices!;
    
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

    // 7. デバッグ出力
    final targetUuid = characteristic.uuid.toString();
    print('Attempting write to UUID: $targetUuid with data: [$bytesHexString]');
    print('[Pavlok] [Vibrate] Targeting UUID 1001 (Vibrate)');
    print('[Pavlok] [Vibrate] Target characteristic UUID: $targetUuid');
    print('[Pavlok] [Vibrate] Level: $clampedLevel (0x${clampedLevel.toRadixString(16).padLeft(2, '0')})');

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

    print('[Pavlok] [Vibrate] ✓ Success: VIBRATE $clampedLevel% sent to $targetUuid');
  } catch (e) {
    print('[Pavlok Error] [Vibrate] Vibrate command failed: $e');
    rethrow;
  }
}
```

### Vibrateの実装ポイント

- **データ形式**: `[0x81, 0x0c, level, 0x16, 0x16]` (5バイト)
- **レベル範囲**: 0-100（`clampedLevel`で自動クランプ）
- **UUID**: `156e1001-a300-4fea-897b-86f698d74461`
- **書き込みタイプ**: `writeWithoutResponse`が優先、なければ`write`を使用
- **シーケンス**: Unlock → 100ms待機 → Vibrate送信

## Beep（ビープ音）

```dart
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
      await Future.delayed(const Duration(milliseconds: 100)); // 認証後の待機
    }

    // 3. レベルクランプ
    final clampedLevel = intensity.clamp(0, 100);

    // 4. データ準備（Vibrateと同じ形式）
    final bytes = Uint8List.fromList([0x81, 0x0c, clampedLevel, 0x16, 0x16]);
    final bytesHexString = bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');

    // 5. サービス取得（キャッシュ利用）
    if (_cachedServices == null || _cachedServices!.isEmpty) {
      if (_connectedDevice == null) {
        throw Exception('Device not connected');
      }
      print('[Pavlok] [Beep] Services not discovered yet, discovering...');
      _cachedServices = await _connectedDevice!.discoverServices(timeout: 5);
      print('[Pavlok] [Beep] Services discovered: ${_cachedServices!.length} services');
    }
    final services = _cachedServices!;
    
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

    // 7. デバッグ出力
    final targetUuid = characteristic.uuid.toString();
    print('Attempting write to UUID: $targetUuid with data: [$bytesHexString]');
    print('[Pavlok] [Beep] Targeting UUID 1002 (Beep)');
    print('[Pavlok] [Beep] Target characteristic UUID: $targetUuid');
    print('[Pavlok] [Beep] Level: $clampedLevel (0x${clampedLevel.toRadixString(16).padLeft(2, '0')})');

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

    print('[Pavlok] [Beep] ✓ Success: BEEP $clampedLevel% sent to $targetUuid');
  } catch (e) {
    print('[Pavlok Error] [Beep] Beep command failed: $e');
    rethrow;
  }
}
```

### Beepの実装ポイント

- **データ形式**: `[0x81, 0x0c, level, 0x16, 0x16]` (5バイト) - Vibrateと同じ
- **レベル範囲**: 0-100（`clampedLevel`で自動クランプ）
- **UUID**: `156e1002-a300-4fea-897b-86f698d74461`
- **書き込みタイプ**: `writeWithoutResponse`が優先、なければ`write`を使用
- **シーケンス**: Unlock → 100ms待機 → Beep送信

## Shock（電気ショック）

```dart
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
      await Future.delayed(const Duration(milliseconds: 100)); // 認証後の待機
    }

    // 3. Step 2: Handshake（セッション維持） - **必須**
    print('[Pavlok] [Shock] Step 2: Sending handshake to Status (1005)...');
    await handshake();
    await Future.delayed(const Duration(milliseconds: 100)); // ハンドシェイク後の待機

    // 4. Step 3: Shock送信準備
    print('[Pavlok] [Shock] Step 3: Sending shock command to 1003...');
    
    // レベルクランプ
    final clampedLevel = intensity.clamp(0, 100);

    // **重要**: 2バイトのみ送信（パディング禁止）
    final bytes = Uint8List.fromList([0x81, clampedLevel]);
    final bytesHexString = bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');

    // 5. サービス取得（キャッシュ利用）
    if (_cachedServices == null || _cachedServices!.isEmpty) {
      if (_connectedDevice == null) {
        throw Exception('Device not connected');
      }
      print('[Pavlok] [Shock] Services not discovered yet, discovering...');
      _cachedServices = await _connectedDevice!.discoverServices(timeout: 5);
      print('[Pavlok] [Shock] Services discovered: ${_cachedServices!.length} services');
    }
    final services = _cachedServices!;
    
    final service1000 = _findServiceByUuid(services, _controlServiceUuid);
    if (service1000 == null) {
      throw Exception('Service 156e1000 not found');
    }

    // 6. キャラクタリスティック検索（完全UUIDベース：156e1003）
    final shockCharacteristic = _findCharacteristicByUuid(service1000.characteristics, _shockCharUuid);
    
    // デバッグ出力: 送信直前のデータ長確認とUUID表示
    if (shockCharacteristic != null) {
      final targetUuid = shockCharacteristic.uuid.toString();
      print('Attempting write to UUID: $targetUuid with data: [$bytesHexString]');
      print('[Pavlok] [Shock] Targeting UUID 1003 (Shock)');
      print('[Pavlok] [Shock] Target characteristic UUID: $targetUuid');
      print('[Pavlok] [Shock] Level: $clampedLevel (0x${clampedLevel.toRadixString(16).padLeft(2, '0')})');
    }

    if (shockCharacteristic == null) {
      print('[Pavlok] [Shock] Characteristic 156e1003 not found');
      print('[Pavlok] [Shock] Available characteristics:');
      for (final chr in service1000.characteristics) {
        print('[Pavlok] [Shock]   - ${chr.uuid.toString()}');
      }
      throw Exception('Shock characteristic (156e1003) not found');
    }

    // 7. 書き込みプロパティ確認
    if (!shockCharacteristic.properties.write && !shockCharacteristic.properties.writeWithoutResponse) {
      throw Exception('Shock characteristic is not writable');
    }

    // 8. 書き込み実行（**2バイトのみ**、writeを優先）
    if (shockCharacteristic.properties.write) {
      await shockCharacteristic.write(bytes, withoutResponse: false);
    } else {
      await shockCharacteristic.write(bytes, withoutResponse: true);
    }

    print('[Pavlok] [Shock] ✓ Success: SHOCK $clampedLevel% sent to ${shockCharacteristic.uuid}');
  } catch (e) {
    print('[Pavlok Error] [Shock] Shock command failed: $e');
    rethrow;
  }
}
```

### Shockの実装ポイント

- **データ形式**: `[0x81, level]` (**2バイトのみ**) - パディング禁止
- **レベル範囲**: 0-100（`clampedLevel`で自動クランプ）
- **UUID**: `156e1003-a300-4fea-897b-86f698d74461`
- **書き込みタイプ**: `write`が優先（`withoutResponse: false`）、なければ`writeWithoutResponse`を使用
- **シーケンス**: Unlock → 100ms待機 → Handshake → 100ms待機 → Shock送信
- **重要**: Handshakeは必須です。Shock送信前に必ず実行してください。

## コマンド比較表

| コマンド | UUID末尾4桁 | データ形式 | データ長 | シーケンス |
|---------|------------|-----------|---------|-----------|
| Vibrate | 1001 | `[0x81, 0x0c, level, 0x16, 0x16]` | 5バイト | Unlock → Vibrate |
| Beep | 1002 | `[0x81, 0x0c, level, 0x16, 0x16]` | 5バイト | Unlock → Beep |
| Shock | 1003 | `[0x81, level]` | 2バイト | Unlock → Handshake → Shock |

## 共通の実装パターン

1. **サービス探索のタイムアウト**: すべての`discoverServices()`呼び出しに`timeout: 5`（5秒）を設定
2. **サービスキャッシュ**: `_cachedServices`を利用してパフォーマンス向上
3. **UUID検索**: 完全128ビットUUIDを使用した堅牢な検索
4. **エラーハンドリング**: サービス/キャラクタリスティックが見つからない場合、利用可能な一覧をデバッグ出力
5. **レベルクランプ**: 入力レベルを0-100の範囲に自動制限

## 注意事項

- **Shockコマンド**: Handshakeが必須です。Handshakeを実行せずにShockを送信すると、デバイスが反応しない可能性があります。
- **データ長**: Shockは2バイトのみです。パディングを追加すると`Invalid Length`エラーが発生します。
- **タイムアウト**: サービス探索は5秒でタイムアウトします。タイムアウトが発生した場合は、接続状態を確認してください。
- **書き込みタイプ**: プロパティに応じて最適な書き込み方法を自動選択しますが、Shockでは`write`（応答あり）を優先します。
