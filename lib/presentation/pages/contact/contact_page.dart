import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/contact_entity.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../blocs/auth/auth_bloc.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late Future<List<ContactEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<ContentRepository>().getContacts();
  }

  void _refresh() {
    setState(() {
      _future = sl<ContentRepository>().getContacts();
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
        title: const Text('Contact Directory'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Contact',
              onPressed: () async {
                final result = await context.push<bool>('/edit-contact');
                if (result == true) _refresh();
              },
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await context.push<bool>('/edit-contact');
                if (result == true) _refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: FutureBuilder<List<ContactEntity>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No contacts'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = items[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              c.name.isNotEmpty
                                  ? c.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  c.position,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAdmin)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () async {
                                    final result = await context.push<bool>(
                                      '/edit-contact',
                                      extra: c,
                                    );
                                    if (result == true) _refresh();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 18, color: AppColors.error),
                                  onPressed: () => _confirmDelete(c),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _call(c.phone),
                              icon: const Icon(Icons.phone, size: 16),
                              label: const Text('Call'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _email(c.email),
                              icon: const Icon(Icons.email, size: 16),
                              label: const Text('Email'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _toast('Cannot launch dialer');
    }
  }

  Future<void> _email(String email) async {
    if (email.isEmpty) {
      _toast('No email address');
      return;
    }
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _toast('Cannot launch mailer');
    }
  }

  Future<void> _confirmDelete(ContactEntity c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text('"${c.name}" will be permanently deleted.'),
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
      await sl<ContentRepository>().deleteContact(c.id);
      _refresh();
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
