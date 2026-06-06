import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'event_details_page.dart';

class EventsTabPage extends StatefulWidget {
  const EventsTabPage({super.key});

  @override
  State<EventsTabPage> createState() => _EventsTabPageState();
}

class _EventsTabPageState extends State<EventsTabPage> {
  late Future<List<EventEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<ContentRepository>().getEvents();
  }

  void _refresh() {
    setState(() {
      _future = sl<ContentRepository>().getEvents();
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
        title: const Text('Events & Seminars'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Event',
              onPressed: () async {
                final result = await context.push<bool>('/edit-event');
                if (result == true) _refresh();
              },
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await context.push<bool>('/edit-event');
                if (result == true) _refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: FutureBuilder<List<EventEntity>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = (snap.data ?? const [])
            ..sort((a, b) => b.date.compareTo(a.date));
          final upcoming = all.where((e) => e.isUpcoming).toList();
          final past = all.where((e) => !e.isUpcoming).toList();

          if (all.isEmpty) {
            return const Center(child: Text('No events'));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Upcoming',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...upcoming.map((e) => _buildEventCard(e, isAdmin)),
                ],
                if (past.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Past Events',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...past.map((e) => _buildEventCard(e, isAdmin)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(EventEntity e, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: e.isUpcoming ? AppColors.primary : Colors.grey,
          child: const Icon(Icons.event, color: AppColors.white),
        ),
        title: Text(
          e.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_fmtDate(e.date)} • ${e.time}'),
            Text(e.venue, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () async {
                  final result = await context.push<bool>(
                    '/edit-event',
                    extra: e,
                  );
                  if (result == true) _refresh();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete,
                    size: 18, color: AppColors.error),
                onPressed: () => _confirmDelete(e),
              ),
            ],
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailsPage(event: e),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(EventEntity e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text('"${e.title}" will be permanently deleted.'),
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
      await sl<ContentRepository>().deleteEvent(e.id);
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
