import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:useful_pavlok/core/constants/app_colors.dart';
import 'package:useful_pavlok/domain/entities/habit.dart';
import 'package:useful_pavlok/presentation/providers/habit_provider.dart';
import 'package:useful_pavlok/presentation/theme/theme_data.dart';
import 'package:useful_pavlok/presentation/widgets/color_picker_widget.dart';

/// 習慣作成・編集画面
/// 
/// uHabitsのUIを参考にした清潔感のあるデザインのフォーム画面です。
class HabitFormScreen extends ConsumerStatefulWidget {
  /// 編集する習慣（nullの場合は新規作成）
  final Habit? habit;

  const HabitFormScreen({
    super.key,
    this.habit,
  });

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  final _unitController = TextEditingController();
  final _targetController = TextEditingController();
  final _memoController = TextEditingController();

  int _selectedColor = AppColors.defaultHabitColor;
  bool _isNumericEnabled = false;
  String _targetType = 'atLeast';
  String _frequency = 'daily';
  bool _stoicModeEnabled = false;
  String? _stoicStartTime;
  String? _stoicEndTime;
  String _stoicAction = 'shock';
  int _stoicIntensity = 50;
  bool _stoicCountdownEnabled = false;
  bool _reminderEnabled = false;
  String? _reminderTime;

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _loadHabitData(widget.habit!);
    }
    
    // 質問フィールドの変更を監視
    _questionController.addListener(() {
      setState(() {});
    });
    _targetController.addListener(() {
      setState(() {});
    });
  }

  void _loadHabitData(Habit habit) {
    _titleController.text = habit.name;
    _questionController.text = habit.question ?? '';
    _unitController.text = habit.unit ?? '';
    _targetController.text = habit.target?.toString() ?? '';
    _memoController.text = habit.description ?? '';
    _selectedColor = habit.color;
    _isNumericEnabled = habit.isNumeric;
    _targetType = habit.targetType ?? 'atLeast';
    _frequency = habit.frequency;
    _stoicModeEnabled = habit.mode == HabitMode.stoic;
    _stoicStartTime = habit.stoicStartTime;
    _stoicEndTime = habit.stoicEndTime;
    _stoicAction = habit.stoicAction ?? 'shock';
    _stoicIntensity = habit.stoicIntensity;
    _stoicCountdownEnabled = habit.stoicCountdownEnabled;
    _reminderEnabled = habit.reminderEnabled;
    _reminderTime = habit.reminderTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
    _unitController.dispose();
    _targetController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectTime({
    required String? initialTime,
    required Function(String) onTimeSelected,
  }) async {
    TimeOfDay? selectedTime;
    if (initialTime != null) {
      final parts = initialTime.split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      onTimeSelected(timeString);
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final habit = Habit(
      id: widget.habit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _titleController.text.trim(),
      description: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      question: _questionController.text.trim().isEmpty
          ? null
          : _questionController.text.trim(),
      color: _selectedColor,
      isNumeric: _isNumericEnabled,
      unit: _isNumericEnabled && _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : null,
      target: _isNumericEnabled && _targetController.text.trim().isNotEmpty
          ? double.tryParse(_targetController.text.trim())
          : null,
      targetType: _isNumericEnabled && _targetController.text.trim().isNotEmpty
          ? _targetType
          : null,
      frequency: _frequency,
      reminderEnabled: _reminderEnabled,
      reminderTime: _reminderEnabled ? (_reminderTime ?? '09:00') : null,
      mode: _stoicModeEnabled ? HabitMode.stoic : HabitMode.free,
      stoicStartTime: _stoicModeEnabled ? _stoicStartTime : null,
      stoicEndTime: _stoicModeEnabled ? _stoicEndTime : null,
      stoicAction: _stoicModeEnabled ? _stoicAction : null,
      stoicIntensity: _stoicModeEnabled ? _stoicIntensity : 50,
      stoicCountdownEnabled: _stoicModeEnabled ? _stoicCountdownEnabled : false,
      createdAt: widget.habit?.createdAt ?? now,
      updatedAt: now,
      dailyValues: widget.habit?.dailyValues ?? const {},
    );

    try {
      if (widget.habit == null) {
        await ref.read(habitNotifierProvider.notifier).addHabit(habit);
      } else {
        await ref.read(habitNotifierProvider.notifier).updateHabit(habit);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
          widget.habit == null ? '習慣を作成' : '習慣を編集',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveHabit,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              '保存',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトルと色選択
              _buildSection(
                label: 'タイトル',
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: '例: ランニング',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'タイトルを入力してください';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('色を選択'),
                            content: ColorPickerWidget(
                              selectedColor: _selectedColor,
                              onColorSelected: (color) {
                                setState(() {
                                  _selectedColor = color;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(_selectedColor),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 質問
              _buildSection(
                label: '質問',
                  child: TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    hintText: '例: 今日は何km走りましたか?',
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 数値目標トグル
              _buildSection(
                label: '数値で目標を設定する',
                child: Switch(
                  value: _isNumericEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isNumericEnabled = value;
                      // トグルをオフにした場合、関連フィールドをクリア
                      if (!value) {
                        _unitController.clear();
                        _targetController.clear();
                        _targetType = 'atLeast';
                      }
                    });
                  },
                ),
              ),

              // 数値目標の詳細（条件付き表示）
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isNumericEnabled
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // 単位と目標値
                          Row(
                            children: [
                              Expanded(
                                  child: _buildSection(
                                  label: '単位',
                                  child: TextFormField(
                                    controller: _unitController,
                                    decoration: const InputDecoration(
                                      hintText: '例: km',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSection(
                                  label: '目標',
                                  child: TextFormField(
                                    controller: _targetController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '例: 15',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 目標タイプ
                          _buildSection(
                            label: '目標タイプ',
                            child: DropdownButtonFormField<String>(
                              initialValue: _targetType,
                              decoration: const InputDecoration(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'atLeast',
                                  child: Text('少なくとも'),
                                ),
                                DropdownMenuItem(
                                  value: 'atMost',
                                  child: Text('以下'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _targetType = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // 頻度
              _buildSection(
                label: '頻度',
                child: DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text('毎日'),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('週次'),
                    ),
                    DropdownMenuItem(
                      value: 'interval',
                      child: Text('間隔'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequency = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ストイックモード
              _buildSection(
                label: 'ストイックモード（Pavlok連携）',
                child: Switch(
                  value: _stoicModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _stoicModeEnabled = value;
                    });
                  },
                ),
              ),

              // ストイックモード詳細（展開時のみ表示）
              if (_stoicModeEnabled) ...[
                const SizedBox(height: 16),
                _buildSection(
                  label: '開始時刻',
                  child: InkWell(
                    onTap: () => _selectTime(
                      initialTime: _stoicStartTime,
                      onTimeSelected: (time) {
                        setState(() {
                          _stoicStartTime = time;
                        });
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _stoicStartTime ?? '時刻を選択',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _stoicStartTime == null
                                  ? Theme.of(context).textTheme.labelLarge?.color
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).textTheme.labelLarge?.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  label: '終了時刻',
                  child: InkWell(
                    onTap: () => _selectTime(
                      initialTime: _stoicEndTime,
                      onTimeSelected: (time) {
                        setState(() {
                          _stoicEndTime = time;
                        });
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _stoicEndTime ?? '時刻を選択',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _stoicEndTime == null
                                  ? Theme.of(context).textTheme.labelLarge?.color
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).textTheme.labelLarge?.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  label: '罰のアクション',
                  child: DropdownButtonFormField<String>(
                    initialValue: _stoicAction,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(
                        value: 'shock',
                        child: Text('ショック'),
                      ),
                      DropdownMenuItem(
                        value: 'vibrate',
                        child: Text('バイブ'),
                      ),
                      DropdownMenuItem(
                        value: 'beep',
                        child: Text('ビープ音'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _stoicAction = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  label: '罰の強度: $_stoicIntensity%',
                  child: Slider(
                    value: _stoicIntensity.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '$_stoicIntensity%',
                    onChanged: (value) {
                      setState(() {
                        _stoicIntensity = value.round();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  label: 'カウントダウン',
                  child: Switch(
                    value: _stoicCountdownEnabled,
                    onChanged: (value) {
                      setState(() {
                        _stoicCountdownEnabled = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // リマインダー
              _buildSection(
                label: 'リマインダー',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _reminderEnabled ? 'オン' : 'オフ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Switch(
                          value: _reminderEnabled,
                          onChanged: (value) {
                            setState(() {
                              _reminderEnabled = value;
                              if (value && _reminderTime == null) {
                                _reminderTime = '09:00';
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (_reminderEnabled) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectTime(
                          initialTime: _reminderTime,
                          onTimeSelected: (time) {
                            setState(() {
                              _reminderTime = time;
                            });
                          },
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _reminderTime ?? '時刻を選択',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _reminderTime == null
                                      ? Theme.of(context).textTheme.labelLarge?.color
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).textTheme.labelLarge?.color,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // メモ
              _buildSection(
                label: 'メモ',
                child: TextFormField(
                  controller: _memoController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '(省略可)',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
