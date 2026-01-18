import 'package:flutter/material.dart';

/// デバイスボタン設定画面
/// 
/// Pavlok本体のボタン挙動を設定する画面（後で実装予定）
class DeviceButtonSettingsScreen extends StatelessWidget {
  const DeviceButtonSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'デバイスボタン設定',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Text(
          'この機能は後で実装予定です',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.labelLarge?.color,
          ),
        ),
      ),
    );
  }
}
