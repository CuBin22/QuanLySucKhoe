import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../domain/app_time.dart';
import '../../ui/common.dart';
import '../../ui/app_theme.dart';
import '../../ui/editor_page.dart';
import 'care_reminder.dart';

class CareForm extends StatefulWidget {
  const CareForm({super.key, required this.services, this.initial});
  final AppServices services;
  final CareReminder? initial;
  @override
  State<CareForm> createState() => _CareFormState();
}

class _CareFormState extends State<CareForm> {
  final _form = GlobalKey<FormState>();
  final _editor = GlobalKey<EditorPageState>();
  late final TextEditingController _title, _note;
  final _titleFocus = FocusNode();
  late ReminderType _type;
  late RepeatRule _repeat;
  late DateTime _start, _end;
  late TimeOfDay _time;
  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    final wall = vietnamWallTime(
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    _title = TextEditingController(text: p?.title ?? '');
    _note = TextEditingController(text: p?.note ?? '');
    _type = p?.type ?? ReminderType.medication;
    _repeat = p?.repeatRule ?? RepeatRule.none;
    _start = p == null
        ? DateTime(wall.year, wall.month, wall.day)
        : parseDateKey(p.startDate);
    _end = p == null ? _start : parseDateKey(p.endDate);
    final time = p?.localTime.split(':');
    _time = TimeOfDay(
      hour: time == null ? wall.hour : int.parse(time[0]),
      minute: time == null ? wall.minute : int.parse(time[1]),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _dirty() => _editor.currentState?.markDirty();
  Future<void> _date(bool end) async {
    final now = vietnamWallTime(DateTime.now());
    final first = end ? _start : DateTime(1900);
    final selected = await showDatePicker(
      context: context,
      initialDate: end ? _end : _start,
      firstDate: first,
      lastDate: DateTime(now.year + 10, 12, 31),
      helpText: end ? 'Ngày kết thúc' : 'Ngày bắt đầu',
    );
    if (selected != null) {
      setState(() {
        if (end) {
          _end = selected;
        } else {
          _start = selected;
          if (_repeat == RepeatRule.none || _end.isBefore(_start)) {
            _end = _start;
          }
        }
      });
      _dirty();
    }
  }

  @override
  Widget build(BuildContext context) => EditorPage(
    hue: Hue.lime,
    key: _editor,
    title: widget.initial == null ? 'Tạo lịch chăm sóc' : 'Chỉnh sửa lịch',
    saveLabel: 'Lưu lịch',
    formKey: _form,
    onSubmit: () async {
      await widget.services.care.save(
        CareReminder(
          id: widget.initial?.id,
          type: _type,
          title: _title.text,
          note: _note.text,
          repeatRule: _repeat,
          startDate: dateKey(_start),
          endDate: dateKey(_repeat == RepeatRule.none ? _start : _end),
          localTime:
              '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
          isEnabled: widget.initial?.isEnabled ?? true,
        ),
        nowUtc: DateTime.now().toUtc(),
      );
    },
    children: [
      const InlineNotice(
        text: 'Giờ Việt Nam (UTC+7). Lịch lặp tối đa 30 ngày mỗi đợt; ngày kết thúc luôn được lưu rõ ràng.',
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<ReminderType>(
        initialValue: _type,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Loại lịch'),
        items: const [
          DropdownMenuItem(
            value: ReminderType.medication,
            child: Text('Uống thuốc'),
          ),
          DropdownMenuItem(
            value: ReminderType.appointment,
            child: Text('Tái khám'),
          ),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _type = v;
            if (v == ReminderType.appointment) {
              _repeat = RepeatRule.none;
              _end = _start;
            }
          });
          _dirty();
        },
      ),
      const SizedBox(height: 20),
      TextFormField(
        key: const ValueKey('care-title'),
        controller: _title,
        focusNode: _titleFocus,
        decoration: const InputDecoration(labelText: 'Tên lịch chăm sóc'),
        validator: (v) =>
            (v ?? '').trim().isEmpty ? 'Nhập tên lịch chăm sóc.' : null,
      ),
      const SizedBox(height: 20),
      if (_type == ReminderType.medication) ...[
        DropdownButtonFormField<RepeatRule>(
          initialValue: _repeat,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Lặp lại'),
          items: const [
            DropdownMenuItem(value: RepeatRule.none, child: Text('Một lần')),
            DropdownMenuItem(value: RepeatRule.daily, child: Text('Mỗi ngày')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() => _repeat = v);
              _dirty();
            }
          },
        ),
        const SizedBox(height: 20),
      ],
      OutlinedButton.icon(
        onPressed: () => _date(false),
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(
          '${_repeat == RepeatRule.daily ? 'Bắt đầu' : 'Ngày'}: ${dateKey(_start).split('-').reversed.join('/')}',
        ),
      ),
      if (_repeat == RepeatRule.daily) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _date(true),
          icon: const Icon(Icons.event_available_outlined),
          label: Text(
            'Kết thúc: ${dateKey(_end).split('-').reversed.join('/')}',
          ),
        ),
      ],
      const SizedBox(height: 12),
      OutlinedButton.icon(
        icon: const Icon(Icons.schedule_outlined),
        label: Text(
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')} · UTC+7',
        ),
        onPressed: () async {
          final t = await showTimePicker(
            context: context,
            initialTime: _time,
            helpText: 'Giờ nhắc',
          );
          if (t != null) {
            setState(() => _time = t);
            _dirty();
          }
        },
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _note,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Ghi chú (không bắt buộc)',
          helperText: 'Ghi hướng dẫn bạn đã có hoặc địa điểm tái khám.',
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Ứng dụng không đề xuất thuốc hoặc liều dùng. Thông báo có thể trễ theo quyền và cài đặt tiết kiệm pin của thiết bị.',
      ),
      const SizedBox(height: 24),
    ],
  );
}
