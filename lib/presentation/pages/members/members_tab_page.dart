import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../member/member_directory_page.dart';

class MembersTabPage extends StatelessWidget {
  const MembersTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: const MemberDirectoryPage(),
    );
  }
}
