import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImgbbService {
  static const _apiKeyPref = 'cpva_imgbb_api_key';
  static const _uploadUrl = 'https://api.imgbb.com/1/upload';
  static const _hardcodedApiKey = '[REDACTED_SECRET]';

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
  }

  Future<String?> getApiKey() async => _hardcodedApiKey;

  Future<String?> pickAndUpload() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Imgbb API key not configured. Set it in Admin Panel > Settings.');
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    return await uploadBytes(bytes, picked.name);
  }

  Future<String> uploadBytes(Uint8List bytes, String filename) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Imgbb API key not configured');
    }
    final base64Image = base64Encode(bytes);
    final response = await http.post(
      Uri.parse('$_uploadUrl?key=$apiKey'),
      body: {
        'image': base64Image,
        'name': filename,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Imgbb upload failed: ${response.body}');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('Imgbb returned error: ${data['error']?['message'] ?? 'unknown'}');
    }
    final imageData = data['data'] as Map<String, dynamic>;
    return imageData['url']?.toString() ?? imageData['display_url']?.toString() ?? '';
  }
}
