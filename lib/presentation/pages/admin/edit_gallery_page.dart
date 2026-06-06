import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/drive_url_helper.dart';
import '../../../data/datasources/imgbb_service.dart';
import '../../../domain/entities/gallery_entity.dart';
import '../../../domain/repositories/content_repository.dart';

class EditGalleryPage extends StatefulWidget {
  final GalleryEntity? item;

  const EditGalleryPage({super.key, this.item});

  @override
  State<EditGalleryPage> createState() => _EditGalleryPageState();
}

class _EditGalleryPageState extends State<EditGalleryPage> {
  final _formKey = GlobalKey<FormState>();
  late final _titleCtrl =
      TextEditingController(text: widget.item?.title ?? '');
  late final _imageCtrl =
      TextEditingController(text: widget.item?.imageUrl ?? '');
  late final _dateCtrl =
      TextEditingController(text: widget.item?.date ?? '');
  late String _type = widget.item?.type ?? 'photo';
  bool _uploading = false;
  String? _uploadedUrl;

  @override
  void dispose() {
    _titleCtrl.dispose();
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

  Future<void> _pickAndUpload() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final apiKey = await sl<ImgbbService>().getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      _showApiKeyMissingDialog();
      return;
    }
    setState(() => _uploading = true);
    try {
      final url = await sl<ImgbbService>().pickAndUpload();
      if (url != null && mounted) {
        setState(() {
          _imageCtrl.text = url;
          _uploadedUrl = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded! Hit Save to add to gallery.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showApiKeyMissingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Imgbb API Key Not Set'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('To upload photos, you need a free Imgbb API key.'),
              SizedBox(height: 8),
              Text('1. Go to https://api.imgbb.com'),
              Text('2. Sign up free (no credit card)'),
              Text('3. Copy your API key'),
              SizedBox(height: 4),
              Text('4. Go to Admin Panel > Settings > Imgbb API Key'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.item?.id ?? 'g${DateTime.now().millisecondsSinceEpoch}';
    final rawUrl = _imageCtrl.text.trim();
    print('DEBUG save() - rawUrl: $rawUrl');
    final directUrl = DriveUrlHelper.convertToDirectImageUrl(rawUrl) ?? rawUrl;
    print('DEBUG save() - directUrl: $directUrl');
    final item = GalleryEntity(
      id: id,
      title: _titleCtrl.text.trim(),
      type: _type,
      imageUrl: directUrl,
      date: _dateCtrl.text.trim(),
    );
    print('DEBUG save() - saving item: ${item.toJson()}');
    try {
      await sl<ContentRepository>().saveGallery(item);
      print('DEBUG save() - saved successfully');
    } catch (e) {
      print('DEBUG save() - FAILED: $e');
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final previewUrl = _uploadedUrl ?? _imageCtrl.text;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Gallery Item' : 'Add Gallery Item'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_upload, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Upload Photo',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick a photo from your device. It uploads to Imgbb (free, no signup needed by users).',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _pickAndUpload,
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.image, size: 18),
                      label: Text(_uploading
                          ? 'Uploading...'
                          : 'Pick from Device & Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'OR paste an image URL below',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
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
              controller: _imageCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL *',
                prefixIcon: Icon(Icons.link),
                hintText: 'Auto-filled if you used Upload button above',
              ),
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Image URL is required'
                  : null,
            ),
            if (previewUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    previewUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ],
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
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.photo_library),
              ),
              items: const [
                DropdownMenuItem(value: 'photo', child: Text('Photo')),
                DropdownMenuItem(value: 'video', child: Text('Video')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'photo'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _uploading ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Update Item' : 'Create Item'),
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
