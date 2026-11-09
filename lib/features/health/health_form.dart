import 'package:flutter/material.dart';

import 'health_repository.dart';
import 'health_record.dart';
import 'health_rules.dart';
import '../../ui/app_theme.dart';
import '../../ui/editor_page.dart';
import '../../ui/common.dart';
import '../../domain/app_time.dart';

class HealthForm extends StatefulWidget {
  const HealthForm({super.key, required this.repository, this.initial});
  final HealthRepository repository;
  final HealthRecord? initial;
  @override
  State<HealthForm> createState() => _HealthFormState();
}

class _HealthFormState extends State<HealthForm> {
  final _form = GlobalKey<FormState>();
  final _editor = GlobalKey<EditorPageState>();
  final _controllers = <String, TextEditingController>{};
  final _focus = <String, FocusNode>{};
  late DateTime _wall;
  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _wall = vietnamWallTime(r?.measuredAtUtc ?? DateTime.now().toUtc());
    final values = {
      'weight': r?.weightKg == null ? '' : editNumber(r!.weightKg!),
      'systolic': r?.systolic?.toString() ?? '',
      'diastolic': r?.diastolic?.toString() ?? '',
      'heart': r?.heartRate?.toString() ?? '',
      'note': r?.note ?? '',
    };
    for (final e in values.entries) {
      _controllers[e.key] = TextEditingController(text: e.value);
      _focus[e.key] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  String _value(String key) => _controllers[key]!.text.trim();
  String? _validate(String name, String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) {
      if ((name == 'systolic' && _value('diastolic').isNotEmpty) ||
          (name == 'diastolic' && _value('systolic').isNotEmpty)) {
        return 'Nhập đủ cặp huyết áp.';
      }
      return null;
    }
    try {
      parsePositiveDecimal(v);
    } on FormatException catch (e) {
      return e.message;
    }
    if (name != 'weight' && !RegExp(r'^\d+$').hasMatch(v)) {
      return 'Nhập số nguyên lớn hơn 0.';
    }
    if (name == 'systolic' &&
        int.tryParse(_value('diastolic')) != null &&
        int.parse(v) <= int.parse(_value('diastolic'))) {
      return 'Tâm thu phải lớn hơn tâm trương.';
    }
    return null;
  }

  Widget _field(String key, String label, String unit) => TextFormField(
    key: ValueKey('health-$key'),
    controller: _controllers[key],
    focusNode: _focus[key],
    keyboardType: TextInputType.numberWithOptions(decimal: key == 'weight'),
    decoration: InputDecoration(labelText: label, suffixText: unit),
    validator: (v) => _validate(key, v),
  );
  @override
  Widget build(BuildContext context) => EditorPage(
    hue: Hue.dragon,
    key: _editor,
    title: widget.initial == null ? 'Thêm chỉ số' : 'Chỉnh sửa chỉ số',
    saveLabel: 'Lưu chỉ số',
    formKey: _form,
    onSubmit: () async {
      await widget.repository.save(
        HealthRecord(
          id: widget.initial?.id,
          measuredAtUtc: vietnamWallToUtc(_wall),
          weightKg: _value('weight').isEmpty
              ? null
              : parsePositiveDecimal(_value('weight')),
          systolic: int.tryParse(_value('systolic')),
          diastolic: int.tryParse(_value('diastolic')),
          heartRate: int.tryParse(_value('heart')),
          note: _value('note'),
        ),
      );
    },
    children: [
      const Text(
        'Nhập ít nhất một nhóm chỉ số. Các giá trị chỉ dùng để ghi nhận và theo dõi.',
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('${_wall.day}/${_wall.month}/${_wall.year}'),
            onPressed: () async {
              final today = vietnamWallTime(DateTime.now());
              final date = await showDatePicker(
                context: context,
                initialDate: _wall,
                firstDate: DateTime(1900),
                lastDate: DateTime(today.year, today.month, today.day),
                helpText: 'Ngày đo',
              );
              if (date != null) {
                setState(
                  () => _wall = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    _wall.hour,
                    _wall.minute,
                  ),
                );
                _editor.currentState?.markDirty();
              }
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule_outlined),
            label: Text(
              '${_wall.hour.toString().padLeft(2, '0')}:${_wall.minute.toString().padLeft(2, '0')} · UTC+7',
            ),
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: _wall.hour, minute: _wall.minute),
                helpText: 'Giờ đo',
              );
              if (time != null) {
                setState(
                  () => _wall = DateTime(
                    _wall.year,
                    _wall.month,
                    _wall.day,
                    time.hour,
                    time.minute,
                  ),
                );
                _editor.currentState?.markDirty();
              }
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      _field('weight', 'Cân nặng', 'kg'),
      const SizedBox(height: 20),
      _field('systolic', 'Huyết áp tâm thu', 'mmHg'),
      const SizedBox(height: 16),
      _field('diastolic', 'Huyết áp tâm trương', 'mmHg'),
      const SizedBox(height: 20),
      _field('heart', 'Nhịp tim', 'nhịp/phút'),
      const SizedBox(height: 20),
      TextFormField(
        controller: _controllers['note'],
        focusNode: _focus['note'],
        decoration: const InputDecoration(
          labelText: 'Ghi chú (không bắt buộc)',
        ),
        maxLines: 3,
      ),
      const SizedBox(height: 24),
    ],
  );
}
