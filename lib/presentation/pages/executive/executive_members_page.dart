import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/executive_local_datasource.dart';
import '../../../data/models/executive_member_model.dart';
import '../../../domain/entities/executive_member_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/member_avatar.dart';

class ExecutiveMembersPage extends StatefulWidget {
  const ExecutiveMembersPage({super.key});

  @override
  State<ExecutiveMembersPage> createState() => _ExecutiveMembersPageState();
}

class _ExecutiveMembersPageState extends State<ExecutiveMembersPage> {
  late Future<List<ExecutiveMemberModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<ExecutiveLocalDataSource>().getAll();
  }

  void _refresh() {
    setState(() {
      _future = sl<ExecutiveLocalDataSource>().getAll();
    });
  }

  Future<void> _confirmDelete(ExecutiveMemberEntity e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Executive?'),
        content: Text('"${e.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await sl<ExecutiveLocalDataSource>().delete(e.id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthBloc>().state is AuthAuthenticated &&
        (context.watch<AuthBloc>().state as AuthAuthenticated).user.isAdmin;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Executive Members'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Add Executive',
              onPressed: () async {
                final result = await context.push<bool>('/edit-executive');
                if (result == true) _refresh();
              },
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await context.push<bool>('/edit-executive');
                if (result == true) _refresh();
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Executive'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: FutureBuilder<List<ExecutiveMemberModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No executive members'));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final e = list[index];
                return _ExecutiveCard(
                  executive: e,
                  isAdmin: isAdmin,
                  onEdit: () async {
                    final result = await context.push<bool>(
                      '/edit-executive',
                      extra: e,
                    );
                    if (result == true) _refresh();
                  },
                  onDelete: () => _confirmDelete(e),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ExecutiveCard extends StatelessWidget {
  final ExecutiveMemberEntity executive;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExecutiveCard({
    required this.executive,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExecutiveAvatar(
              executiveId: executive.id,
              photoUrl: executive.photoUrl.isNotEmpty ? executive.photoUrl : null,
              initials: executive.initials,
              radius: 30,
              refreshable: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    executive.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      executive.designation,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        executive.mobile,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.badge,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        executive.id,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isAdmin)
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        size: 18, color: AppColors.error),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
