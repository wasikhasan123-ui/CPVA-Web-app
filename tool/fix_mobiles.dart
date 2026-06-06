// One-time script to fix +880 mobile numbers in Firestore
// Run with: dart run tool/fix_mobiles.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  print('Connecting to Firestore...');
  final db = FirebaseFirestore.instance;

  final fixes = {
    '+8801714367786': '01714367786',
    '+8801639053165': '01639053165',
  };

  for (final entry in fixes.entries) {
    final oldMobile = entry.key;
    final newMobile = entry.value;
    print('Looking for member with mobile: $oldMobile...');

    final query = await db
        .collection('members')
        .where('mobile', isEqualTo: oldMobile)
        .get();

    if (query.docs.isEmpty) {
      print('  No member found with mobile $oldMobile. Skipping.');
      continue;
    }

    for (final doc in query.docs) {
      await doc.reference.update({'mobile': newMobile});
      print('  Updated ${doc.id}: $oldMobile -> $newMobile');
    }
  }

  print('Done!');
}
