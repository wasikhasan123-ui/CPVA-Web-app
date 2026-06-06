import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/member_remote_datasource.dart';
import '../../../domain/entities/member_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/member/member_bloc.dart';
import '../../widgets/member_avatar.dart';

class MemberDirectoryPage extends StatefulWidget {
  const MemberDirectoryPage({super.key});

  @override
  State<MemberDirectoryPage> createState() => _MemberDirectoryPageState();
}

class _MemberDirectoryPageState extends State<MemberDirectoryPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MemberBloc>().add(const LoadMembers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshMembers() {
    sl<MemberRemoteDataSource>()
        .getAllMembers()
        .then((_) => context.read<MemberBloc>().add(const LoadMembers()));
  }

  Widget _buildAvatar(MemberEntity member) {
    return MemberAvatar(
      memberId: member.id,
      photoUrl: member.photoUrl.isNotEmpty ? member.photoUrl : null,
      initials: member.initials,
      radius: 25,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.read<AuthBloc>().state is AuthAuthenticated &&
            (context.read<AuthBloc>().state as AuthAuthenticated)
                .user
                .isAdmin;
    return Scaffold(
      appBar: isAdmin
          ? AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              title: const Text('Members'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Add Member',
                  onPressed: () async {
                    final result =
                        await context.push<bool>('/edit-member');
                    if (result == true) _refreshMembers();
                  },
                ),
              ],
            )
          : null,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await context.push<bool>('/edit-member');
                if (result == true) _refreshMembers();
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, mobile, BVC reg. no, institute...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<MemberBloc>()
                              .add(const LoadMembers());
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isNotEmpty) {
                  context.read<MemberBloc>().add(SearchMembers(value));
                } else {
                  context.read<MemberBloc>().add(const LoadMembers());
                }
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<MemberBloc, MemberState>(
              builder: (context, state) {
                if (state is MemberLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is MemberError) {
                  return Center(child: Text(state.message));
                }
                if (state is MembersLoaded) {
                  if (state.members.isEmpty) {
                    return const Center(
                      child: Text('No members found'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.members.length,
                    itemBuilder: (context, index) {
                      final member = state.members[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: _buildAvatar(member),
                          title: Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(member.memberId),
                              if (member.specialization.isNotEmpty)
                                Text(
                                  member.specialization,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdmin) ...[
                                IconButton(
                                  icon: const Icon(Icons.key, size: 18,
                                      color: Colors.orange),
                                  tooltip: 'Reset Password',
                                  onPressed: () => _resetPassword(member),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () async {
                                    final result = await context.push<bool>(
                                      '/edit-member',
                                      extra: member,
                                    );
                                    if (result == true) _refreshMembers();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 18,
                                      color: AppColors.error),
                                  onPressed: () =>
                                      _confirmDelete(member),
                                ),
                              ],
                              const Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                          onTap: () {
                            context.push(
                              '/member-details',
                              extra: member,
                            );
                          },
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(MemberEntity m) async {
    if (m.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the admin user'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Member?'),
        content: Text('"${m.name}" will be permanently deleted.'),
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
      await sl<MemberRemoteDataSource>().deleteMember(m.id);
      _refreshMembers();
    }
  }

  Future<void> _resetPassword(MemberEntity m) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.key, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Reset Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Member: ${m.name}'),
              Text('Mobile: ${m.mobile}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => obscureNew = !obscureNew),
                    child: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                    child: Icon(
                      obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final result = await sl<AuthRepository>().setPasswordForMember(
            m.id,
            newPasswordController.text,
          );
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Password reset for ${m.name}. New password is active.'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    }
  }
}
