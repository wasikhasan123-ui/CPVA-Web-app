import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoService {
  final String namespace;
  static const _maxBytes = 800 * 1024;

  PhotoService(this.namespace);

  String get _kPrefix => 'cpva_${namespace}_photo_v1_';
  String get _filePrefix => '${namespace}_';

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromGallery({required String ownerId}) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;
    return _savePhoto(ownerId: ownerId, file: file);
  }

  Future<String?> takePhoto({required String ownerId}) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;
    return _savePhoto(ownerId: ownerId, file: file);
  }

  Future<String> _savePhoto({
    required String ownerId,
    required XFile file,
  }) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxBytes) {
        throw Exception(
          'Image too large (${(bytes.length / 1024).toStringAsFixed(0)}KB). '
          'Please pick an image under 800KB.',
        );
      }
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_kPrefix$ownerId', dataUrl);
      return dataUrl;
    } else {
      final docs = await getApplicationDocumentsDirectory();
      final ext = file.name.contains('.png') ? '.png' : '.jpg';
      final dest = File('${docs.path}/$_filePrefix$ownerId$ext');
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception(
          'Image too large (${(bytes.length / 1024 / 1024).toStringAsFixed(1)}MB). '
          'Please pick a smaller image.',
        );
      }
      await dest.writeAsBytes(bytes, flush: true);
      final prefs = await SharedPreferences.getInstance();
      final path = dest.path;
      await prefs.setString('$_kPrefix$ownerId', path);
      return path;
    }
  }

  Future<String?> getCustomPhoto(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kPrefix$ownerId');
  }

  Future<bool> hasCustomPhoto(String ownerId) async {
    final v = await getCustomPhoto(ownerId);
    return v != null && v.isNotEmpty;
  }

  Future<void> removeCustomPhoto(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('$_kPrefix$ownerId');
    if (v != null && !v.startsWith('data:') && !kIsWeb) {
      final f = File(v);
      if (await f.exists()) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
    await prefs.remove('$_kPrefix$ownerId');
  }

  Future<void> renamePhoto(String oldId, String newId) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('$_kPrefix$oldId');
    if (v == null) return;
    await prefs.setString('$_kPrefix$newId', v);
    if (!v.startsWith('data:') && !kIsWeb) {
      final oldFile = File(v);
      if (await oldFile.exists()) {
        final ext = oldId.contains('.png') ? '.png' : '.jpg';
        final newPath = '${oldFile.parent.path}/$_filePrefix$newId$ext';
        try {
          await oldFile.rename(newPath);
        } catch (_) {}
      }
    }
    await prefs.remove('$_kPrefix$oldId');
  }

  Future<Uint8List?> getCustomPhotoBytes(String ownerId) async {
    final path = await getCustomPhoto(ownerId);
    if (path == null) return null;
    if (path.startsWith('data:')) {
      final comma = path.indexOf(',');
      if (comma < 0) return null;
      return base64Decode(path.substring(comma + 1));
    }
    if (kIsWeb) return null;
    final f = File(path);
    if (!await f.exists()) return null;
    return f.readAsBytes();
  }
}
