import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// エラー状態を表示するウィジェット
class ErrorState extends ConsumerWidget {
  /// エラーメッセージ
  final String? message;
  
  /// 再試行するプロバイダー（nullの場合は再試行ボタンを表示しない）
  final ProviderBase<AsyncValue>? retryProvider;

  const ErrorState({
    super.key,
    this.message,
    this.retryProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'エラーが発生しました',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          if (retryProvider != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.refresh(retryProvider!),
              child: const Text('再試行'),
            ),
          ],
        ],
      ),
    );
  }
}
