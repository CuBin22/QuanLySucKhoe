import 'package:flutter/material.dart';

import '../../ui/editor_page.dart';
import '../../ui/common.dart';
import '../../domain/app_time.dart';
import '../health/health_rules.dart';
import 'profile.dart';
import 'profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.repository,
    this.initial,
    required this.onSaved,
  });
  final ProfileRepository repository;
  final Profile? initial;
  final Future<void> Function() onSaved;
  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _editor = GlobalKey<EditorPageState>();
  late final TextEditingController _name, _height, _target;
  final _nameFocus = FocusNode(),
      _heightFocus = FocusNode(),
      _targetFocus = FocusNode();
  String? _birth;
  Future<bool> confirmLeave() async {
    if (!(_editor.currentState?.isDirty ?? false)) return true;
    if (!await _editor.currentState!.confirmLeave()) return false;
    if (!mounted) return false;
    final p = widget.initial;
    _name.text = p?.fullName ?? '';
    _height.text = p == null ? '' : editNumber(p.heightCm);
    _target.text = p?.targetWeightKg == null
        ? ''
        : editNumber(p!.targetWeightKg!);
    setState(() => _birth = p?.birthDate);
    _editor.currentState?.markClean();
    return true;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.fullName ?? '');
    _height = TextEditingController(
      text: p == null ? '' : editNumber(p.heightCm),
    );
    _target = TextEditingController(
      text: p?.targetWeightKg == null ? '' : editNumber(p!.targetWeightKg!),
    );
    _birth = p?.birthDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _target.dispose();
    _nameFocus.dispose();
    _heightFocus.dispose();
    _targetFocus.dispose();
    super.dispose();
  }

  String? _positive(String? s, {bool optional = false}) {
    if (optional && (s ?? '').trim().isEmpty) return null;
    try {
      parsePositiveDecimal(s ?? '');
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  @override
  Widget build(BuildContext context) => EditorPage(
    key: _editor,
    title: widget.initial == null ? 'Bắt đầu sổ sức khỏe' : 'Hồ sơ cá nhân',
    saveLabel: 'Lưu hồ sơ',
    formKey: _form,
    popOnSuccess: false,
    onSaved: widget.onSaved,
    onSubmit: () async => widget.repository.save(
      Profile(
        fullName: _name.text,
        heightCm: parsePositiveDecimal(_height.text),
        birthDate: _birth,
        targetWeightKg: _target.text.trim().isEmpty
            ? null
            : parsePositiveDecimal(_target.text),
      ),
    ),
    children: [
      const InlineNotice(
        text: 'Ghi lại những thay đổi nhỏ. Theo dõi sức khỏe theo nhịp sống của bạn.',
      ),
      const SizedBox(height: 24),
      TextFormField(
        key: const ValueKey('profile-name'),
        controller: _name,
        focusNode: _nameFocus,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(labelText: 'Họ và tên'),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Nhập họ và tên.' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        key: const ValueKey('profile-height'),
        controller: _height,
        focusNode: _heightFocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Chiều cao',
          suffixText: 'cm',
        ),
        validator: (v) => _positive(v),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _target,
        focusNode: _targetFocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Cân nặng mục tiêu (không bắt buộc)',
          suffixText: 'kg',
        ),
        validator: (v) => _positive(v, optional: true),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month_outlined),
        onPressed: () async {
          final today = vietnamWallTime(DateTime.now());
          final date = await showDatePicker(
            context: context,
            initialDate: _birth == null
                ? DateTime(today.year - 20, today.month, today.day)
                : parseDateKey(_birth!),
            firstDate: DateTime(1900),
            lastDate: DateTime(today.year, today.month, today.day),
            helpText: 'Chọn ngày sinh',
          );
          if (date != null) {
            setState(() => _birth = dateKey(date));
            _editor.currentState?.markDirty();
          }
        },
        label: Text(
          _birth == null
              ? 'Ngày sinh (không bắt buộc)'
              : 'Ngày sinh: ${_birth!.split('-').reversed.join('/')}',
        ),
      ),
      if (_birth != null)
        TextButton(
          onPressed: () {
            setState(() => _birth = null);
            _editor.currentState?.markDirty();
          },
          child: const Text('Xóa ngày sinh'),
        ),
      const SizedBox(height: 24),
      const InlineNotice(
        text: 'Một hồ sơ cho mỗi bản cài. Điện thoại và máy tính lưu dữ liệu riêng, chưa đồng bộ hoặc sao lưu tự động.',
      ),
      const SizedBox(height: 24),
    ],
  );
}
