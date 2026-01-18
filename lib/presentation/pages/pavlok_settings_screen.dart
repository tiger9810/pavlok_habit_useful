import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:useful_pavlok/presentation/pages/device_button_settings_screen.dart';
import 'package:useful_pavlok/presentation/pages/workflow_settings_screen.dart';
import 'package:useful_pavlok/presentation/providers/pavlok_provider.dart';
import 'package:useful_pavlok/presentation/theme/theme_data.dart';

/// Pavlok設定画面
/// 
/// Pavlokデバイスの設定とクイックトライ機能を提供します。
class PavlokSettingsScreen extends ConsumerWidget {
  const PavlokSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pavlokAsync = ref.watch(pavlokNotifierProvider);

    // デバッグ: 状態変化をログ出力
    pavlokAsync.whenData((pavlokState) {
      print('[PavlokSettingsScreen] 状態更新を検知: isConnected=${pavlokState.isConnected}');
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: pavlokAsync.when(
        data: (pavlokState) => AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'デバイスのステータス',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          actions: [
            if (pavlokState.isConnected && pavlokState.batteryLevel != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${pavlokState.batteryLevel}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      pavlokState.deviceName ?? 'Pavlok',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '未接続',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
          ],
        ),
        loading: () => AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'デバイスのステータス',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        error: (error, stack) => AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'デバイスのステータス',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: pavlokAsync.when(
          data: (pavlokState) {
            // デバッグ: 現在の状態をログ出力
            print('[PavlokSettingsScreen] ビルド: isConnected=${pavlokState.isConnected}');
            print('[PavlokSettingsScreen] 表示する画面: ${pavlokState.isConnected ? "クイックリモート" : "デバイス選択"}');
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 未接続時: デバイス選択UI
                if (!pavlokState.isConnected) ...[
                  _buildDeviceSelectionView(context, theme, pavlokState, ref),
                ] else ...[
                  // 接続済み時: クイックリモート・カードと設定メニュー
                  _buildQuickRemoteCard(context, theme, pavlokState, ref),
                  const SizedBox(height: 24),
                  _buildSettingsMenuList(context, theme),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _buildErrorView(context, theme, error, ref),
        ),
      ),
    );
  }

  /// デバイス選択ビューを構築します
  Widget _buildDeviceSelectionView(
    BuildContext context,
    ThemeData theme,
    PavlokState pavlokState,
    WidgetRef ref,
  ) {
    final isScanning = pavlokState.isScanning;
    final discoveredDevices = pavlokState.discoveredDevices;
    
    // デバッグ: 現在の状態をログ出力
    print('[PavlokSettingsScreen] デバイス選択ビュー: isScanning=$isScanning, discoveredDevices=${discoveredDevices.length}台');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // スキャン中メッセージ（デバイスが見つかっていない場合のみ）
        if (isScanning && discoveredDevices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'デバイスをスキャン中...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),

        // デバイスリスト（スキャン中でも、デバイスが見つかれば表示）
        // 「空でなければ出す」ロジック: discoveredDevices.isNotEmpty の場合に即座に表示
        if (discoveredDevices.isNotEmpty) ...[
          Text(
            '見つかったBluetoothデバイス',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // ListViewでデバイスリストを表示
          ...discoveredDevices.map(
            (device) => _buildDeviceListItem(context, theme, device, ref),
          ),
          const SizedBox(height: 16),
          // 再スキャンボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(pavlokNotifierProvider.notifier).scanForDevices();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('再スキャン'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
            ),
          ),
        ],

        // 初回表示時またはスキャン完了後デバイスが見つからない場合
        if (!isScanning && discoveredDevices.isEmpty) ...[
          // スキャン開始ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(pavlokNotifierProvider.notifier).scanForDevices();
              },
              icon: const Icon(Icons.search),
              label: const Text('デバイスをスキャンする'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // ヘルプメッセージカード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pavlokが見つかりません',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '以下の点を確認してください：',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildHelpItem(theme, '1. Pavlokデバイスが電源オンになっているか'),
                  _buildHelpItem(theme, '2. デバイスがペアリングモードになっているか'),
                  _buildHelpItem(theme, '3. Bluetoothが有効になっているか'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// デバイスリストアイテムを構築します
  Widget _buildDeviceListItem(
    BuildContext context,
    ThemeData theme,
    BluetoothDevice device,
    WidgetRef ref,
  ) {
    // デバイス名を取得（名前が取得できない場合は「名前なし」）
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : '名前なし';
    
    // デバイスIDの冒頭4文字を抽出
    final deviceId = device.remoteId.toString();
    final deviceIdPrefix = deviceId.length >= 4 
        ? deviceId.substring(0, 4).toUpperCase()
        : deviceId.toUpperCase();
    
    // 表示名とエイリアスを決定
    // Service UUIDによる判定は接続時に実施されるため、ここでは全てのデバイスを表示
    final deviceDisplayName = deviceName;
    final deviceAlias = deviceIdPrefix;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2, // 影を追加
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 左側: Pavlokアイコン
            Icon(
              Icons.watch,
              color: AppTheme.primaryColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            // 中央: デバイス情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceDisplayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceAlias,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // 右側: 接続ボタン
            ElevatedButton(
              onPressed: () async {
                try {
                  // 接続処理を実行（connect() → discoverServices() → isConnected = true）
                  await ref.read(pavlokNotifierProvider.notifier).connectToDevice(device);
                  
                  // 接続成功時はSnackBarで通知（接続完了後、自動的にクイックリモート画面に遷移）
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$deviceDisplayName に接続しました'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // 接続エラー時は分かりやすいメッセージを表示
                  if (context.mounted) {
                    final errorMessage = e.toString().contains('Timeout') ||
                            e.toString().contains('timeout')
                        ? '接続に失敗しました。デバイスを近づけて再度お試しください'
                        : '接続に失敗しました。デバイスを近づけて再度お試しください';
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: '再試行',
                          textColor: Colors.white,
                          onPressed: () {
                            ref.read(pavlokNotifierProvider.notifier).connectToDevice(device);
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              child: const Text('接続'),
            ),
          ],
        ),
      ),
    );
  }

  /// ヘルプアイテムを構築します
  Widget _buildHelpItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: theme.textTheme.bodyMedium,
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }


  /// クイックリモート・カードを構築します
  Widget _buildQuickRemoteCard(
    BuildContext context,
    ThemeData theme,
    PavlokState state,
    WidgetRef ref,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー（アイコン、タイトル、展開/格納アイコン）
            Row(
              children: [
                Icon(
                  Icons.watch,
                  color: theme.textTheme.titleMedium?.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'クイックリモート',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    state.isQuickRemoteExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.textTheme.labelLarge?.color,
                  ),
                  onPressed: () {
                    ref.read(pavlokNotifierProvider.notifier).toggleQuickRemoteExpansion();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 展開/格納コンテンツ（アニメーション付き）
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: state.isQuickRemoteExpanded
                  ? _buildExpandedContent(context, theme, state, ref)
                  : _buildCollapsedContent(context, theme, state, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// 格納時のコンテンツを構築します
  Widget _buildCollapsedContent(
    BuildContext context,
    ThemeData theme,
    PavlokState state,
    WidgetRef ref,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCollapsedActionButton(
          context,
          theme,
          'ザップ',
          Icons.bolt,
          state.shockIntensity,
          const Color(0xFFFF6B35),
          () => ref.read(pavlokNotifierProvider.notifier).triggerShock(),
        ),
        _buildCollapsedActionButton(
          context,
          theme,
          'アラーム音',
          Icons.volume_up,
          state.alarmIntensity,
          const Color(0xFFFFD700),
          () => ref.read(pavlokNotifierProvider.notifier).triggerAlarm(),
        ),
        _buildCollapsedActionButton(
          context,
          theme,
          'バイブ',
          Icons.vibration,
          state.vibrateIntensity,
          const Color(0xFFE91E63),
          () => ref.read(pavlokNotifierProvider.notifier).triggerVibrate(),
        ),
      ],
    );
  }

  /// 展開時のコンテンツを構築します
  Widget _buildExpandedContent(
    BuildContext context,
    ThemeData theme,
    PavlokState state,
    WidgetRef ref,
  ) {
    final notifier = ref.read(pavlokNotifierProvider.notifier);
    return Column(
      children: [
        _buildExpandedActionRow(
          context,
          theme,
          'ザップ',
          Icons.bolt,
          state.shockIntensity,
          const Color(0xFFFF6B35), // オレンジ（通常時と同じ）
          (value) => notifier.updateShockIntensity(value),
          ref,
        ),
        _buildExpandedActionRow(
          context,
          theme,
          'アラーム音',
          Icons.volume_up,
          state.alarmIntensity,
          const Color(0xFFFFD700), // 黄色（通常時と同じ）
          (value) => notifier.updateAlarmIntensity(value),
          ref,
        ),
        _buildExpandedActionRow(
          context,
          theme,
          'バイブ',
          Icons.vibration,
          state.vibrateIntensity,
          const Color(0xFFE91E63), // ピンク（通常時と同じ）
          (value) => notifier.updateVibrateIntensity(value),
          ref,
        ),
      ],
    );
  }

  /// 格納時のアクションボタンを構築します（グラデーションなしの単色）
  Widget _buildCollapsedActionButton(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    int intensity,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color, // グラデーションではなく単色
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$intensity%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 展開時のアクション行を構築します（スライダー付き）
  Widget _buildExpandedActionRow(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    int intensity,
    Color iconColor,
    ValueChanged<int> onChanged,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // アイコンをボタン化してタップ可能にする
          IconButton(
            icon: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            onPressed: () {
              // 現在の強度で即座にコマンドを実行
              // スライダーで調整した強度は既に状態に反映されているため、
              // 引数なしで呼び出すと現在の状態の強度が使用される
              final notifier = ref.read(pavlokNotifierProvider.notifier);
              switch (label) {
                case 'ザップ':
                  notifier.triggerShock();
                  break;
                case 'アラーム音':
                  notifier.triggerAlarm();
                  break;
                case 'バイブ':
                  notifier.triggerVibrate();
                  break;
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
                Slider(
                  value: intensity.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 10,
                  onChanged: (value) => onChanged(value.round()),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '$intensity%',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// エラービューを構築します
  Widget _buildErrorView(
    BuildContext context,
    ThemeData theme,
    Object error,
    WidgetRef ref,
  ) {
    final errorMessage = error.toString();
    final isBluetoothError = errorMessage.contains('Bluetooth') ||
        errorMessage.contains('bluetooth') ||
        errorMessage.contains('有効になっていません');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (isBluetoothError) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '対処方法',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      theme,
                      '1. macOSの「システム設定 > Bluetooth」でBluetoothが有効になっているか確認',
                    ),
                    const SizedBox(height: 8),
                    _buildChecklistItem(
                      theme,
                      '2. macOSの「システム設定 > プライバシーとセキュリティ > Bluetooth」で「Runner」または「useful_pavlok」に権限が与えられているか確認',
                    ),
                    const SizedBox(height: 8),
                    _buildChecklistItem(
                      theme,
                      '3. アプリを完全に終了して再起動してください（Hot Restartではなく、一度停止して再実行）',
                    ),
                    const SizedBox(height: 8),
                    _buildChecklistItem(
                      theme,
                      '4. ターミナルのログを確認し、Bluetoothアダプター状態を確認してください',
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // プロバイダーをリフレッシュして再試行
              ref.invalidate(pavlokNotifierProvider);
            },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  /// チェックリスト項目を構築します
  Widget _buildChecklistItem(ThemeData theme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 20,
          color: theme.textTheme.labelLarge?.color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  /// 設定メニュー・リストを構築します
  Widget _buildSettingsMenuList(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          leading: Icon(
            Icons.settings,
            color: theme.textTheme.titleSmall?.color,
          ),
          title: Text(
            'デバイスボタンを設定する',
            style: theme.textTheme.titleSmall,
          ),
          subtitle: Text(
            'Pavlok本体のボタン挙動を設定',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.textTheme.labelLarge?.color,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DeviceButtonSettingsScreen(),
              ),
            );
          },
        ),
        Divider(
          height: theme.dividerTheme.space,
          thickness: theme.dividerTheme.thickness,
          color: theme.dividerTheme.color,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          leading: Icon(
            Icons.work_outline,
            color: theme.textTheme.titleSmall?.color,
          ),
          title: Text(
            'ワークフロー設定',
            style: theme.textTheme.titleSmall,
          ),
          subtitle: Text(
            '自動化ワークフローを定義',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.textTheme.labelLarge?.color,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const WorkflowSettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
