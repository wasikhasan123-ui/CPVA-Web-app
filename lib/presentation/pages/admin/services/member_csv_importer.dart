import '../../../../core/di/injection.dart';
import '../../../../data/datasources/member_remote_datasource.dart';
import '../../../../data/models/member_model.dart';

class MemberCsvImporter {
  Future<MemberCsvImportResult> import(String content) async {
    final rows = _parseCsvRows(content);

    int headerIdx = -1;
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].any((cell) => _safe(cell).isNotEmpty)) {
        headerIdx = i;
        break;
      }
    }

    if (headerIdx < 0) {
      return const MemberCsvImportResult(
        imported: 0,
        skippedExisting: 0,
        skippedInvalid: 0,
      );
    }

    final headers = rows[headerIdx]
        .map((h) => _safe(h).trim().toLowerCase())
        .toList();

    print('CSV headers detected: $headers');

    final headerToField = <int, String>{};

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];

      if (header == 'timestamp' || header.startsWith('i hereby declare')) {
        continue;
      }

      final field = _kHeaderToField[header];
      if (field != null) {
        headerToField[i] = field;
      }
    }

    print('Header to field map: $headerToField');

    final dataSource = sl<MemberRemoteDataSource>();

    final existingMembers = await dataSource.getAllMembers();

    final existingKeys = <String>{};
    for (final member in existingMembers) {
      final idKey = _cleanMobile(member.id);
      final mobileKey = _cleanMobile(member.mobile);

      if (idKey.isNotEmpty) existingKeys.add(idKey);
      if (mobileKey.isNotEmpty) existingKeys.add(mobileKey);
    }

    int imported = 0;
    int skippedExisting = 0;
    int skippedInvalid = 0;

    for (int rowIndex = headerIdx + 1; rowIndex < rows.length; rowIndex++) {
      try {
        final cells = rows[rowIndex];

        if (cells.every((cell) => _safe(cell).isEmpty)) {
          continue;
        }

        final values = <String, String>{};

        headerToField.forEach((columnIndex, fieldName) {
          if (columnIndex < cells.length) {
            values[fieldName] = _safe(cells[columnIndex]);
          }
        });

        final mobile = _cleanMobile(values['mobile'] ?? '');

        if (mobile.isEmpty || mobile.length < 10) {
          skippedInvalid++;
          print(
            'Skipping CSV row ${rowIndex + 1}: invalid mobile "${values['mobile']}"',
          );
          continue;
        }

        if (existingKeys.contains(mobile)) {
          skippedExisting++;
          print(
            'Skipping CSV row ${rowIndex + 1}: existing member $mobile / ${values['name']}',
          );
          continue;
        }

        final rawPhotoUrl = _safe(values['photoUrl']);
        final rawLicenseUrl = _safe(values['licenseUrl']);

        final member = MemberModel(
          id: mobile,
          name: _safe(values['name']),
          nameBn: '',
          fatherName: _safe(values['fatherName']),
          motherName: _safe(values['motherName']),
          gender: _safe(values['gender']),
          permanentAddress: _safe(values['permanentAddress']),
          mailingAddress: _safe(values['mailingAddress']).isNotEmpty
              ? _safe(values['mailingAddress'])
              : _safe(values['permanentAddress']),
          mobile: mobile,
          email: _safe(values['email']),
          emergencyContact: _safe(values['emergencyContact']),
          bvcRegNo: _safe(values['bvcRegNo']),
          dateOfBirth: _safe(values['dateOfBirth']),
          bloodGroup: _safe(values['bloodGroup']),
          dvmInstitute: _safe(values['dvmInstitute']),
          msc: _safe(values['msc']),
          phd: _safe(values['phd']),
          experience: _safe(values['experience']),
          specialization: _safe(values['specialization']),
          workType: _safe(values['workType']),
          instituteName: _safe(values['instituteName']),
          interests: _safe(values['interests']),
          photoUrl: _cleanPhotoUrl(rawPhotoUrl),
          licenseUrl: _isUsableWebUrl(rawLicenseUrl) ? rawLicenseUrl : '',
        );

        await dataSource.saveMember(member);

        existingKeys.add(mobile);
        imported++;

        print('Saved CSV row ${rowIndex + 1}: ${member.name} / ${member.mobile}');
      } catch (rowError, rowSt) {
        print('CSV row ${rowIndex + 1} failed: $rowError');
        print(rowSt);
      }
    }

    print(
      'CSV import finished. Imported: $imported, skipped existing: $skippedExisting, skipped invalid: $skippedInvalid',
    );

    return MemberCsvImportResult(
      imported: imported,
      skippedExisting: skippedExisting,
      skippedInvalid: skippedInvalid,
    );
  }

  List<List<String>> _parseCsvRows(String content) {
    final rows = <List<String>>[];
    var row = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"') {
        if (inQuotes && i + 1 < content.length && content[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(buffer.toString().trim());
        buffer.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++;
        }

        row.add(buffer.toString().trim());
        buffer.clear();

        if (row.any((cell) => cell.trim().isNotEmpty)) {
          rows.add(row);
        }

        row = <String>[];
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty || row.isNotEmpty) {
      row.add(buffer.toString().trim());

      if (row.any((cell) => cell.trim().isNotEmpty)) {
        rows.add(row);
      }
    }

    return rows;
  }

  String _safe(dynamic val) {
    if (val == null) return '';
    final s = val.toString().trim();
    if (s == 'null' || s == 'nan' || s == 'NaN') return '';
    return s;
  }

  String _cleanMobile(String raw) {
    String v = raw.trim().replaceAll(RegExp(r'[^\d+]'), '');

    if (v.startsWith('+880')) {
      v = '0${v.substring(4)}';
    } else if (v.startsWith('880') && v.length > 10) {
      v = '0${v.substring(3)}';
    }

    v = v.replaceAll(RegExp(r'[^\d]'), '');

    if (v.length == 10 && !v.startsWith('0')) {
      v = '0$v';
    }

    return v;
  }

  bool _isUsableWebUrl(String value) {
    final v = value.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  String _cleanPhotoUrl(String value) {
    final raw = value.trim();

    if (!_isUsableWebUrl(raw)) {
      return '';
    }

    final directGoogleUrl = _convertGoogleDriveToDirectImageUrl(raw);
    return directGoogleUrl ?? raw;
  }

  String? _convertGoogleDriveToDirectImageUrl(String input) {
    if (input.isEmpty) return null;

    if (input.contains('drive.google.com') ||
        input.contains('drive.usercontent.google.com')) {
      final patterns = [
        RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
        RegExp(r'[?&]id=([a-zA-Z0-9_-]+)'),
        RegExp(r'/d/([a-zA-Z0-9_-]+)'),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(input);
        if (match != null) {
          return 'https://lh3.googleusercontent.com/d/${match.group(1)}';
        }
      }
    }

    if (input.contains('lh3.googleusercontent.com') ||
        input.contains('googleusercontent.com')) {
      return input;
    }

    return null;
  }

  static const Map<String, String> _kHeaderToField = {
    'name': 'name',
    'father\'s name/husband\'s name': 'fatherName',
    'mother\'s name': 'motherName',
    'gender': 'gender',
    'permanent address': 'permanentAddress',
    'mailing address': 'mailingAddress',
    'mobile number': 'mobile',
    'email': 'email',
    'emergency contact number(any of family member)': 'emergencyContact',
    'bvc reg. no': 'bvcRegNo',
    'date of birth': 'dateOfBirth',
    'blood group': 'bloodGroup',
    'dvm/bsc. vet. sci. & ah: institute name': 'dvmInstitute',
    'msc.: subject & institute name': 'msc',
    'phd : institute name': 'phd',
    'experience (years)': 'experience',
    'specialization (limited to tow)': 'specialization',
    'work': 'workType',
    'institute name': 'instituteName',
    'game(interest)': 'interests',
    'passport size picture': 'photoUrl',
    'bvc licences copy': 'licenseUrl',
  };
}

class MemberCsvImportResult {
  final int imported;
  final int skippedExisting;
  final int skippedInvalid;

  const MemberCsvImportResult({
    required this.imported,
    required this.skippedExisting,
    required this.skippedInvalid,
  });
}
