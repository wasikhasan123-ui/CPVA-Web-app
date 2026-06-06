import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmailService {
  static const String _kServiceId = 'cpva_emailjs_service_id_v1';
  static const String _kTemplateId = 'cpva_emailjs_template_id_v1';
  static const String _kPublicKey = 'cpva_emailjs_public_key_v1';
  static const String _kApiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  Future<String?> getServiceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kServiceId);
  }

  Future<void> setServiceId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kServiceId, value);
  }

  Future<String?> getTemplateId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTemplateId);
  }

  Future<void> setTemplateId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTemplateId, value);
  }

  Future<String?> getPublicKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPublicKey);
  }

  Future<void> setPublicKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPublicKey, value);
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isConfigured() {
    return false;
  }

  Future<bool> isReady() async {
    final serviceId = await getServiceId();
    final templateId = await getTemplateId();
    final publicKey = await getPublicKey();
    return (serviceId?.isNotEmpty ?? false) &&
        (templateId?.isNotEmpty ?? false) &&
        (publicKey?.isNotEmpty ?? false);
  }

  Future<bool> sendVerificationCode({
    required String toEmail,
    required String code,
    required String memberName,
  }) async {
    final serviceId = await getServiceId();
    final templateId = await getTemplateId();
    final publicKey = await getPublicKey();

    if (serviceId == null ||
        serviceId.isEmpty ||
        templateId == null ||
        templateId.isEmpty ||
        publicKey == null ||
        publicKey.isEmpty) {
      throw Exception(
          'EmailJS not configured. Admin must set Service ID, Template ID, and Public Key in Email Settings.');
    }

    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f7f5; margin: 0; padding: 20px; }
  .container { max-width: 480px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
  .header { background: linear-gradient(135deg, #2E7D32, #4CAF50); padding: 32px 24px; text-align: center; }
  .header h1 { color: #ffffff; margin: 0; font-size: 28px; font-weight: 800; letter-spacing: 2px; }
  .header p { color: rgba(255,255,255,0.9); margin: 6px 0 0; font-size: 13px; }
  .body { padding: 32px 28px; }
  .greeting { font-size: 15px; color: #1B1B1B; margin-bottom: 16px; }
  .message { font-size: 14px; color: #555; line-height: 1.6; margin-bottom: 24px; }
  .code-box { background: linear-gradient(135deg, #2E7D32, #4CAF50); color: #ffffff; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }
  .code-label { font-size: 12px; text-transform: uppercase; letter-spacing: 1.5px; color: rgba(255,255,255,0.85); margin-bottom: 8px; }
  .code { font-size: 36px; font-weight: 900; letter-spacing: 8px; color: #ffffff; }
  .expiry { font-size: 12px; color: #888; text-align: center; margin-top: 16px; }
  .footer { background: #f5f7f5; padding: 20px; text-align: center; font-size: 11px; color: #888; border-top: 1px solid #eee; }
  .footer p { margin: 4px 0; }
  .warn { background: #fff3cd; border-left: 3px solid #f57c00; padding: 12px 16px; border-radius: 6px; font-size: 12px; color: #6b4d00; margin-top: 20px; }
</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>CPVA</h1>
      <p>Chattogram Private Veterinary Association</p>
    </div>
    <div class="body">
      <p class="greeting">Dear <strong>${_escape(memberName)}</strong>,</p>
      <p class="message">
        We received a request to reset your CPVA member portal password.
        Use the verification code below to complete your password reset.
      </p>
      <div class="code-box">
        <div class="code-label">Your Verification Code</div>
        <div class="code">$code</div>
      </div>
      <p class="expiry">This code is valid for <strong>15 minutes</strong> and can be used only once.</p>
      <div class="warn">
        <strong>Security Notice:</strong> If you did not request this password reset,
        please ignore this email or contact CPVA admin. Your account is still secure.
      </div>
    </div>
    <div class="footer">
      <p><strong>CPVA</strong> &middot; Chattogram Private Veterinary Association</p>
      <p>This is an automated message. Please do not reply directly to this email.</p>
    </div>
  </div>
</body>
</html>
''';

    final textBody =
        'CPVA Password Reset\n\nDear $memberName,\n\nYour verification code is: $code\n\nThis code is valid for 15 minutes.\n\nIf you did not request this, please ignore this email.\n\nCPVA - Chattogram Private Veterinary Association';

    final payload = {
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'to_email': toEmail,
        'email': toEmail,
        'to': toEmail,
        'recipient': toEmail,
        'user_email': toEmail,
        'to_name': memberName,
        'name': memberName,
        'code': code,
        'passcode': code,
        'verification_code': code,
        'from_name': 'CPVA',
        'subject': 'CPVA - Password Reset Verification Code',
        'message': 'Your verification code is: $code (valid for 15 minutes)',
        'html_body': htmlBody,
        'text_body': textBody,
      },
    };

    try {
      final response = await http.post(
        Uri.parse(_kApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'https://emailjs.com',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final body = response.body;
        if (response.statusCode == 400 && body.contains('template')) {
          throw Exception(
              'EmailJS template not found. Check the Template ID in Email Settings. '
              'Make sure the template exists at emailjs.com and uses {{to_email}} and {{code}} variables.');
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception(
              'EmailJS rejected the request. Check:\n'
              '1) Public Key is correct (Account → API Keys in emailjs.com)\n'
              '2) Service ID matches the connected email service\n'
              '3) Free-tier limit (200 emails/month) not exceeded\n'
              'Details: $body');
        }
        throw Exception(
            'EmailJS API error: ${response.statusCode} - $body');
      }
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  String _escape(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
