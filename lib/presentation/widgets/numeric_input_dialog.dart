import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 数値入力ダイアログ
/// 
/// 数値型習慣の日別進捗を入力するためのモーダルダイアログです。
class NumericInputDialog extends StatefulWidget {
  /// 習慣名
  final String habitName;
  
  /// 単位（例: 分、km）
  final String unit;
  
  /// 現在の値（nullの場合は0）
  final double? currentValue;
  
  /// 保存コールバック
  final Function(double value) onSave;

  const NumericInputDialog({
    super.key,
    required this.habitName,
    required this.unit,
    this.currentValue,
    required this.onSave,
  });

  @override
  State<NumericInputDialog> createState() => _NumericInputDialogState();
}

class _NumericInputDialogState extends State<NumericInputDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue != null && widget.currentValue! > 0
          ? widget.currentValue!.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final value = double.tryParse(_controller.text.trim()) ?? 0.0;
      widget.onSave(value);
      // onSaveコールバック内でpop()が呼ばれるため、ここでは呼ばない
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.habitName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: '数値を入力',
                hintText: '例: 30',
                suffixText: widget.unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '数値を入力してください';
                }
                final numValue = double.tryParse(value.trim());
                if (numValue == null || numValue < 0) {
                  return '0以上の数値を入力してください';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
          child: Text(
            'キャンセル',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        TextButton(
          onPressed: _handleSave,
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
          child: const Text(
            '保存',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
