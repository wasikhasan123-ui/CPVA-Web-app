import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/executive_local_datasource.dart';
import '../../../data/datasources/photo_service.dart';
import '../../../domain/entities/executive_member_entity.dart';

class EditExecutivePage extends StatefulWidget {
  final ExecutiveMemberEntity? executive;

  const EditExecutivePage({super.key, this.executive});

  @override
  State<EditExecutivePage> createState() => _EditExecutivePageState();
}

class _EditExecutivePageState extends State<EditExecutivePage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final e = widget.executive;
    if (e != null) {
      _idCtrl.text = e.id;
      _nameCtrl.text = e.name;
      _designationCtrl.text = e.designation;
      _mobileCtrl.text = e.mobile;
      _photoUrlCtrl.text = e.photoUrl;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _designationCtrl.dispose();
    _mobileCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _idCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final designation = _designationCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    final photoUrl = _photoUrlCtrl.text.trim();

    final entity = ExecutiveMemberEntity(
      id: id,
      name: name,
      designation: designation,
      mobile: mobile,
      photoUrl: photoUrl,
    );

    final ds = sl<ExecutiveLocalDataSource>();
    final original = widget.executive;
    final idChanged = original != null && original.id != id;

    if (original != null && idChanged) {
      final conflict = await ds.findById(id);
      if (conflict != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ID "$id" is already used by another executive.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      await ds.delete(original.id);
      await ds.save(entity);
      await sl<PhotoService>(instanceName: 'executive')
          .renamePhoto(original.id, id);
    } else if (original != null) {
      await ds.save(entity);
    } else {
      final existing = await ds.findById(id);
      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ID "$id" already exists.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      await ds.save(entity);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.executive != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(isEdit ? 'Edit Executive' : 'Add Executive'),
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ID * (e.g. Cpva-2026-12)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'ID is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _designationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Designation *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Designation is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mobileCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mobile *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Mobile is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _photoUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Photo URL (optional)',
                      hintText: 'https://... (use upload to add a local photo)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(isEdit ? 'Save Changes' : 'Add Executive'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
