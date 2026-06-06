import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/news_entity.dart';
import '../../../domain/repositories/content_repository.dart';

class EditNewsPage extends StatefulWidget {
  final NewsEntity? news;

  const EditNewsPage({super.key, this.news});

  @override
  State<EditNewsPage> createState() => _EditNewsPageState();
}

class _EditNewsPageState extends State<EditNewsPage> {
  final _formKey = GlobalKey<FormState>();
  late final _titleCtrl =
      TextEditingController(text: widget.news?.title ?? '');
  late final _summaryCtrl =
      TextEditingController(text: widget.news?.summary ?? '');
  late final _contentCtrl =
      TextEditingController(text: widget.news?.content ?? '');
  late final _imageCtrl =
      TextEditingController(text: widget.news?.imageUrl ?? '');
  late final _dateCtrl =
      TextEditingController(text: widget.news?.date ?? '');
  late String _category = widget.news?.category ?? 'Association';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    _dateCtrl.dispose();
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
    final id =
        widget.news?.id ?? 'news${DateTime.now().millisecondsSinceEpoch}';
    final news = NewsEntity(
      id: id,
      title: _titleCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      category: _category,
    );
    await sl<ContentRepository>().saveNews(news);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.news != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit News' : 'Add News'),
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
            TextFormField(
              controller: _summaryCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Summary *',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Summary is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Content *',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Content is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                prefixIcon: Icon(Icons.image),
              ),
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
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Association', child: Text('Association')),
                DropdownMenuItem(
                    value: 'Community', child: Text('Community')),
                DropdownMenuItem(value: 'Policy', child: Text('Policy')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'Other'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Update News' : 'Create News'),
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
