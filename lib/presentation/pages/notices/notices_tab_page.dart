import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notice_entity.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'notice_details_page.dart';

class NoticesTabPage extends StatefulWidget {
  const NoticesTabPage({super.key});

  @override
  State<NoticesTabPage> createState() => _NoticesTabPageState();
}

class _NoticesTabPageState extends State<NoticesTabPage> {
  late Future<List<NoticeEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<ContentRepository>().getNotices();
  }

  void _refresh() {
    setState(() {
      _future = sl<ContentRepository>().getNotices();
    });
  }

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
              onPressed: () async {
                final result = await context.push<bool>('/edit-notice');
                if (result == true) _refresh();
              },
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await context.push<bool>('/edit-notice');
                if (result == true) _refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Notice'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: FutureBuilder<List<NoticeEntity>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data ?? [])
            ..sort((a, b) {
              if (a.isPinned && !b.isPinned) return -1;
              if (!a.isPinned && b.isPinned) return 1;
              return b.date.compareTo(a.date);
            });
          if (items.isEmpty) {
            return const Center(child: Text('No notices'));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                return Card(
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.campaign,
                            color: AppColors.primary,
                          ),
                        ),
                        if (n.isPinned)
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      n.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${n.category} • ${_fmtDate(n.date)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdmin) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () async {
                              final result = await context.push<bool>(
                                '/edit-notice',
                                extra: n,
                              );
                              if (result == true) _refresh();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: AppColors.error),
                            onPressed: () => _confirmDelete(n),
                          ),
                        ],
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NoticeDetailsPage(notice: n),
                        ),
                      );
                    },
                  ),
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
      await sl<ContentRepository>().deleteNotice(n.id);
      _refresh();
    }
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
