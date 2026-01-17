import 'package:flutter/material.dart';
import 'package:useful_pavlok/core/constants/app_colors.dart';

/// カラーピッカーウィジェット
/// 
/// サークル状のカラーピッカーを表示します。
class ColorPickerWidget extends StatelessWidget {
  /// 現在選択されている色
  final int selectedColor;
  
  /// 色が選択されたときのコールバック
  final ValueChanged<int> onColorSelected;
  
  /// 利用可能な色のリスト
  final List<int> colors;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colors = AppColors.habitColors,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(color),
              border: Border.all(
                color: isSelected ? Colors.grey.shade800 : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
