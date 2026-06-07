import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/member_entity.dart';
import '../../../domain/entities/news_entity.dart';
import '../../../domain/entities/notice_entity.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/section_state.dart';

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = sl<ContentRepository>();
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const LoadingState();
          }
          final user = state.user;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.cardGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: AppColors.white,
                                  child: Text(
                                    user.initials,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Welcome,',
                                        style: TextStyle(
                                          color: AppColors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.white
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user.memberId,
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.goldAccent
                                                  .withValues(alpha: 0.9),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user.isAdmin ? 'Admin' : 'Member',
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Access',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGrid(context, user),
                      const SizedBox(height: 24),
                      _buildLatestNotices(context, repo),
                      const SizedBox(height: 24),
                      _buildUpcomingEvents(context, repo),
                      const SizedBox(height: 24),
                      _buildRecentNews(context, repo),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context, MemberEntity user) {
    final cards = [
      _DashCard(
        'ID Card',
        Icons.badge,
        AppColors.primary,
        () => context.push('/id-card'),
      ),
      _DashCard(
        'Directory',
        Icons.people,
        Colors.purple,
        () => context.push('/members'),
      ),
      _DashCard(
        'Executive',
        Icons.workspace_premium,
        Colors.deepOrange,
        () => context.push('/executives'),
      ),
      _DashCard(
        'Notices',
        Icons.campaign,
        Colors.orange,
        () => context.push('/notices-list'),
      ),
      _DashCard(
        'Events',
        Icons.event,
        Colors.teal,
        () => context.push('/events-list'),
      ),
      _DashCard(
        'Payment',
        Icons.payment,
        Colors.green,
        () => context.push('/payments'),
      ),
      _DashCard(
        'News',
        Icons.article,
        Colors.blue,
        () => context.push('/news'),
      ),
      _DashCard(
        'Gallery',
        Icons.photo_library,
        Colors.pink,
        () => context.push('/gallery'),
      ),
      _DashCard(
        'Contact',
        Icons.contact_phone,
        Colors.indigo,
        () => context.push('/contacts'),
      ),
    ];

    if (user.isAdmin) {
      cards.add(_DashCard(
        'Admin Panel',
        Icons.admin_panel_settings,
        Colors.red.shade700,
        () => context.push('/admin-panel'),
      ));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => cards[i],
    );
  }

  Widget _buildLatestNotices(BuildContext context, ContentRepository repo) {
    return FutureBuilder<List<NoticeEntity>>(
      future: repo.getNotices(),
      builder: (context, snap) {
        final items = snap.data ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Notices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/notices-list'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.take(3).map((n) => _buildNoticeTile(context, n)),
          ],
        );
      },
    );
  }

  Widget _buildNoticeTile(BuildContext context, NoticeEntity n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _categoryColor(n.category).withValues(alpha: 0.15),
          child: Icon(
            Icons.campaign,
            color: _categoryColor(n.category),
            size: 20,
          ),
        ),
        title: Text(
          n.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${n.category} • ${_fmtDate(n.date)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/notice-details', extra: n),
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, ContentRepository repo) {
    return FutureBuilder<List<EventEntity>>(
      future: repo.getEvents(),
      builder: (context, snap) {
        final items = (snap.data ?? const [])
            .where((e) => e.isUpcoming)
            .toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...items.take(2).map((e) => _buildEventTile(context, e)),
          ],
        );
      },
    );
  }

  Widget _buildEventTile(BuildContext context, EventEntity e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.event, color: AppColors.white, size: 20),
        ),
        title: Text(
          e.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_fmtDate(e.date)} • ${e.venue}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/event-details', extra: e),
      ),
    );
  }

  Widget _buildRecentNews(BuildContext context, ContentRepository repo) {
    return FutureBuilder<List<NewsEntity>>(
      future: repo.getNews(),
      builder: (context, snap) {
        final items = snap.data ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent News',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...items.take(2).map((n) => _buildNewsTile(context, n)),
          ],
        );
      },
    );
  }

  Widget _buildNewsTile(BuildContext context, NewsEntity n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.article, color: AppColors.white, size: 20),
        ),
        title: Text(
          n.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          n.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/news-details', extra: n),
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('d MMM yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'meeting':
        return Colors.blue;
      case 'important':
        return AppColors.error;
      case 'training':
        return Colors.purple;
      case 'holiday':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashCard(this.title, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
