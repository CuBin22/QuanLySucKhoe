import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'common.dart';
import 'motion.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.title,
    required this.saveLabel,
    required this.formKey,
    required this.children,
    required this.onSubmit,
    this.popOnSuccess = true,
    this.onSaved,
    this.hue = Hue.leaf,
  });
  final String title, saveLabel;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Future<void> Function() onSubmit;
  final Future<void> Function()? onSaved;
  final bool popOnSuccess;
  final Hue hue;
  @override
  State<EditorPage> createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  bool _dirty = false, _busy = false, _allowPop = false;
  String? _error;
  bool get isDirty => _dirty;
  void markClean() {
    if (mounted) setState(() => _dirty = false);
  }

  void markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  void _exit(Object? result) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _discard() async {
    if (_busy || _allowPop) return;
    if (await confirmLeave() && mounted) _exit(null);
  }

  Future<bool> confirmLeave() async {
    if (_busy) return false;
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        content: const Text('Nội dung chưa lưu sẽ bị mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Tiếp tục nhập'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) markClean();
    return discard == true;
  }

  Future<void> _save() async {
    if (_busy) return;
    final invalid = widget.formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      final field = invalid.first;
      await Scrollable.ensureVisible(
        field.context,
        duration: const Duration(milliseconds: 180),
      );
      if (!mounted) return;
      void focusEditable(Element element) {
        if (element.widget is EditableText) {
          (element.widget as EditableText).focusNode.requestFocus();
        } else {
          element.visitChildren(focusEditable);
        }
      }

      (field.context as Element).visitChildren(focusEditable);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      await widget.onSaved?.call();
      if (!mounted) return;
      _dirty = false;
      if (widget.popOnSuccess) {
        _exit(true);
      } else {
        setState(() => _busy = false);
        showFeedback(context, 'Đã lưu hồ sơ.');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error is FormatException
              ? error.message
              : error is StateError
              ? error.message
              : 'Không lưu được dữ liệu. Nội dung vẫn được giữ; hãy thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeWithHue(Theme.of(context), widget.hue),
      child: PopScope<Object?>(
        canPop: _allowPop || (!_dirty && !_busy),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _discard();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: Navigator.of(context).canPop()
                ? BackButton(
                    onPressed: () {
                      if (_dirty) {
                        _discard();
                      } else if (!_busy) {
                        Navigator.of(context).maybePop();
                      }
                    },
                  )
                : null,
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 640,
                child: Form(
                  key: widget.formKey,
                  onChanged: markDirty,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, child) in widget.children.indexed)
                          Reveal(index: i, child: child),
                        if (_error != null) ...[
                          InlineNotice(text: _error!, error: true),
                          const SizedBox(height: 16),
                        ],
                        FilledButton(
                          key: const ValueKey('save-editor'),
                          onPressed: _busy ? null : _save,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: _busy ? 0 : 1,
                                child: Text(
                                  widget.saveLabel,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (_busy)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                    semanticsLabel: 'Đang lưu',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Dữ liệu được lưu trên máy chủ.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
