import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/section_state.dart';
import 'event_details_page.dart';

class EventsTabPage extends StatelessWidget {
  const EventsTabPage({super.key});

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
              onPressed: () => context.push('/edit-event'),
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/edit-event'),
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: StreamBuilder<List<EventEntity>>(
        stream: sl<ContentRepository>().streamEvents(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snap.hasError) {
            return ErrorState(
              message: 'Could not load events',
              onRetry: () {
                // Force rebuild by navigating away and back
                context.pop();
                context.push('/events-list');
              },
            );
          }
          final all = (snap.data ?? const <EventEntity>[])
            ..sort((a, b) => b.date.compareTo(a.date));
          final upcoming = all.where((e) => e.isUpcoming).toList();
          final past = all.where((e) => !e.isUpcoming).toList();

          if (all.isEmpty) {
            return const EmptyState(icon: Icons.event_outlined, title: 'No events');
          }
          return ListView(
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
                ...upcoming.map((e) => _buildEventCard(context, e, isAdmin)),
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
                ...past.map((e) => _buildEventCard(context, e, isAdmin)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventEntity e, bool isAdmin) {
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
                onPressed: () => context.push('/edit-event', extra: e),
              ),
              IconButton(
                icon: const Icon(Icons.delete,
                    size: 18, color: AppColors.error),
                onPressed: () => _confirmDelete(context, e),
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

  Future<void> _confirmDelete(BuildContext context, EventEntity e) async {
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
      try {
        await sl<ContentRepository>().deleteEvent(e.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${e.title}" deleted.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete event: $err'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
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
