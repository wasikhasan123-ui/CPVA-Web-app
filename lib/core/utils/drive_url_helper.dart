class DriveUrlHelper {
  static String? convertToDirectImageUrl(String input) {
    if (input.isEmpty) return null;

    if (input.contains('drive.google.com') ||
        input.contains('drive.usercontent.google.com')) {
      final patterns = [
        RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
        RegExp(r'[?&]id=([a-zA-Z0-9_-]+)'),
        RegExp(r'/d/([a-zA-Z0-9_-]+)'),
      ];
      for (final p in patterns) {
        final m = p.firstMatch(input);
        if (m != null) {
          return 'https://lh3.googleusercontent.com/d/${m.group(1)}';
        }
      }
    }

    if (input.contains('lh3.googleusercontent.com') ||
        input.contains('googleusercontent.com')) {
      return input;
    }

    return input;
  }
}
