import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/repositories/content_repository.dart';

class EditEventPage extends StatefulWidget {
  final EventEntity? event;

  const EditEventPage({super.key, this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late final _titleCtrl =
      TextEditingController(text: widget.event?.title ?? '');
  late final _dateCtrl =
      TextEditingController(text: widget.event?.date ?? '');
  late final _timeCtrl =
      TextEditingController(text: widget.event?.time ?? '');
  late final _venueCtrl =
      TextEditingController(text: widget.event?.venue ?? '');
  late final _imageCtrl =
      TextEditingController(text: widget.event?.imageUrl ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.event?.description ?? '');
  late bool _isUpcoming = widget.event?.isUpcoming ?? true;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _venueCtrl.dispose();
    _imageCtrl.dispose();
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
    final id =
        widget.event?.id ?? 'e${DateTime.now().millisecondsSinceEpoch}';
    final event = EventEntity(
      id: id,
      title: _titleCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      time: _timeCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isUpcoming: _isUpcoming,
    );
    await sl<ContentRepository>().saveEvent(event);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Event' : 'Add Event'),
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
              controller: _timeCtrl,
              decoration: const InputDecoration(
                labelText: 'Time (e.g. 10:00 - 16:00)',
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _venueCtrl,
              decoration: const InputDecoration(
                labelText: 'Venue *',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Venue is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                prefixIcon: Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 6,
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
              value: _isUpcoming,
              onChanged: (v) => setState(() => _isUpcoming = v),
              title: const Text('Upcoming Event'),
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Update Event' : 'Create Event'),
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
