import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImgbbService {
  static const _apiKeyPref = 'cpva_imgbb_api_key';
  static const _uploadUrl = 'https://api.imgbb.com/1/upload';

  // IMPORTANT:
  // Replace this with the real ImgBB API key.
  //
  // For Flutter Web, this key is visible in browser/network traffic.
  // This is acceptable only as a temporary/simple solution.
  // Long-term safer options: Cloudinary unsigned preset, Firebase Storage,
  // or backend upload proxy.
  static const _fallbackApiKey = '0ff82139c3cde492b95e79208da506fa';

  Future<void> setApiKey(String key) async {
    final cleanKey = key.trim();

    final prefs = await SharedPreferences.getInstance();

    if (cleanKey.isEmpty) {
      await prefs.remove(_apiKeyPref);
      return;
    }

    await prefs.setString(_apiKeyPref, cleanKey);
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(_apiKeyPref);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }

    if (_fallbackApiKey.trim().isNotEmpty &&
        _fallbackApiKey != 'PUT_YOUR_REAL_IMGBB_API_KEY_HERE') {
      return _fallbackApiKey.trim();
    }

    return null;
  }

  Future<String?> pickAndUpload() async {
    final apiKey = await getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'ImgBB API key is not configured. Please contact admin.',
      );
    }

    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();

    return uploadBytes(
      bytes,
      picked.name.isNotEmpty
          ? picked.name
          : 'payment_screenshot_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<String> uploadBytes(Uint8List bytes, String filename) async {
    final apiKey = await getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'ImgBB API key is not configured. Please contact admin.',
      );
    }

    if (bytes.isEmpty) {
      throw Exception('Selected image is empty. Please choose another image.');
    }

    final safeFilename = _safeFilename(filename);
    final base64Image = base64Encode(bytes);

    late http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$_uploadUrl?key=$apiKey'),
            body: {
              'image': base64Image,
              'name': safeFilename,
            },
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception(
        'Image upload failed. Please check your internet connection and try again.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(_cleanUploadError(response.body));
    }

    final Map<String, dynamic> data;

    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('ImgBB returned an invalid response.');
    }

    if (data['success'] != true) {
      final error = data['error'];

      if (error is Map && error['message'] != null) {
        throw Exception(_cleanUploadError(error['message'].toString()));
      }

      throw Exception('ImgBB upload failed. Please try again.');
    }

    final imageData = data['data'];

    if (imageData is! Map<String, dynamic>) {
      throw Exception('ImgBB upload response did not include image data.');
    }

    final url = imageData['url']?.toString();
    final displayUrl = imageData['display_url']?.toString();

    final finalUrl = (url != null && url.isNotEmpty) ? url : displayUrl;

    if (finalUrl == null || finalUrl.isEmpty) {
      throw Exception('ImgBB upload succeeded but no image URL was returned.');
    }

    return finalUrl;
  }

  String _safeFilename(String filename) {
    final clean = filename
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (clean.isEmpty) {
      return 'payment_screenshot_${DateTime.now().millisecondsSinceEpoch}';
    }

    return clean;
  }

  String _cleanUploadError(String raw) {
    final lower = raw.toLowerCase();

    if (lower.contains('invalid api key') ||
        lower.contains('invalid key') ||
        lower.contains('key is invalid')) {
      return 'Invalid ImgBB API key. Please contact admin.';
    }

    if (lower.contains('image source is missing') ||
        lower.contains('source is missing')) {
      return 'No image was selected. Please choose a screenshot and try again.';
    }

    if (lower.contains('too large') || lower.contains('file size')) {
      return 'Image is too large. Please upload a smaller screenshot.';
    }

    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Image upload limit reached. Please try again later.';
    }

    return 'ImgBB upload failed. Please try again.';
  }
}
