import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notice_entity.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/section_state.dart';
import 'notice_details_page.dart';

class _NoticeCard extends StatelessWidget {
  final NoticeEntity notice;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _NoticeCard({
    required this.notice,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.04),
                AppColors.primary.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign, color: AppColors.primary, size: 22),
                  ),
                  if (notice.isPinned)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.push_pin, size: 10, color: AppColors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.softGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notice.category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _fmtDate(notice.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (isAdmin)
                    SizedBox(
                      height: 28,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 18,
                            color: AppColors.textSecondary),
                        onSelected: (v) {
                          if (v == 'edit') onEdit?.call();
                          if (v == 'delete') onDelete?.call();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit, size: 18),
                              title: Text('Edit',
                                  style: TextStyle(fontSize: 13)),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, size: 18,
                                  color: AppColors.error),
                              title: Text('Delete',
                                  style: TextStyle(fontSize: 13,
                                      color: AppColors.error)),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, size: 18,
                      color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class NoticesTabPage extends StatefulWidget {
  const NoticesTabPage({super.key});

  @override
  State<NoticesTabPage> createState() => _NoticesTabPageState();
}

class _NoticesTabPageState extends State<NoticesTabPage> {
  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.read<AuthBloc>().state is AuthAuthenticated &&
            (context.read<AuthBloc>().state as AuthAuthenticated)
                .user
                .isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Notice',
              onPressed: () => context.push<bool>('/edit-notice'),
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push<bool>('/edit-notice'),
              icon: const Icon(Icons.add),
              label: const Text('Add Notice'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: StreamBuilder<List<NoticeEntity>>(
        stream: sl<ContentRepository>().streamNotices(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const EmptyState(icon: Icons.campaign_outlined, title: 'No notices');
          }
          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                return _NoticeCard(
                  notice: n,
                  isAdmin: isAdmin,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoticeDetailsPage(notice: n),
                      ),
                    );
                  },
                  onEdit: () async {
                    await context.push<bool>('/edit-notice', extra: n);
                  },
                  onDelete: () => _confirmDelete(n),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(NoticeEntity n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Notice?'),
        content: Text('"${n.title}" will be permanently deleted.'),
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
      try {
        await sl<ContentRepository>().deleteNotice(n.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete notice: $e')),
          );
        }
      }
    }
  }
}
