import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notice_entity.dart';
import '../../../domain/repositories/content_repository.dart';

class EditNoticePage extends StatefulWidget {
  final NoticeEntity? notice;

  const EditNoticePage({super.key, this.notice});

  @override
  State<EditNoticePage> createState() => _EditNoticePageState();
}

class _EditNoticePageState extends State<EditNoticePage> {
  final _formKey = GlobalKey<FormState>();
  late final _titleCtrl =
      TextEditingController(text: widget.notice?.title ?? '');
  late final _categoryCtrl =
      TextEditingController(text: widget.notice?.category ?? 'Notice');
  late final _dateCtrl =
      TextEditingController(text: widget.notice?.date ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.notice?.description ?? '');
  late bool _isPinned = widget.notice?.isPinned ?? false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _dateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateCtrl.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.notice?.id ??
        'n${DateTime.now().millisecondsSinceEpoch}';
    final notice = NoticeEntity(
      id: id,
      title: _titleCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      attachmentUrl: widget.notice?.attachmentUrl ?? '',
      isPinned: _isPinned,
    );
    await sl<ContentRepository>().saveNotice(notice);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.notice != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Notice' : 'Add Notice'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryCtrl.text.isEmpty
                  ? 'Notice'
                  : _categoryCtrl.text,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'Notice', child: Text('Notice')),
                DropdownMenuItem(value: 'Meeting', child: Text('Meeting')),
                DropdownMenuItem(
                    value: 'Important', child: Text('Important')),
                DropdownMenuItem(value: 'Training', child: Text('Training')),
                DropdownMenuItem(value: 'Holiday', child: Text('Holiday')),
              ],
              onChanged: (v) => setState(() => _categoryCtrl.text = v ?? 'Notice'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Date (YYYY-MM-DD) *',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _pickDate,
              readOnly: true,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Date is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Description *',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
              title: const Text('Pin to top'),
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Update Notice' : 'Create Notice'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
