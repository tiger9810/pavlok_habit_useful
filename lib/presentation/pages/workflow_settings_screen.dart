import 'package:flutter/material.dart';

/// ワークフロー設定画面
/// 
/// 自動化ワークフローを定義する画面（後で実装予定）
class WorkflowSettingsScreen extends StatelessWidget {
  const WorkflowSettingsScreen({super.key});

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
          'ワークフロー設定',
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
