import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/drive_url_helper.dart';
import '../../../domain/entities/gallery_entity.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/section_state.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.read<AuthBloc>().state is AuthAuthenticated &&
            (context.read<AuthBloc>().state as AuthAuthenticated)
                .user
                .isAdmin;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gallery'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Item',
                onPressed: () => context.push('/edit-gallery'),
              ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.white,
            tabs: [
              Tab(icon: Icon(Icons.photo), text: 'Photos'),
              Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            ],
          ),
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/edit-gallery'),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                backgroundColor: AppColors.primary,
              )
            : null,
        body: StreamBuilder<List<GalleryEntity>>(
          stream: sl<ContentRepository>().streamGallery(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingState();
            }
            final items = snap.data ?? const [];
            final photos = items.where((e) => e.type == 'photo').toList();
            final videos = items.where((e) => e.type == 'video').toList();
            return TabBarView(
              children: [
                _buildGrid(context, photos, isAdmin),
                _buildGrid(context, videos, isAdmin),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<GalleryEntity> items, bool isAdmin) {
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.photo_library_outlined, title: 'No gallery items');
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final g = items[i];
          return Stack(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _GalleryDetailsPage(item: g),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: i.isEven ? 1 : 0.8,
                    child: g.imageUrl.isNotEmpty
                        ? Image.network(
                            DriveUrlHelper.convertToDirectImageUrl(g.imageUrl) ??
                                g.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.image,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.image,
                              size: 50,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
              ),
              if (g.type == 'video')
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: AppColors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    g.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (isAdmin)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.black.withValues(alpha: 0.6),
                          padding: const EdgeInsets.all(6),
                        ),
                        icon: const Icon(Icons.edit,
                            color: AppColors.white, size: 16),
                        onPressed: () => context.push(
                          '/edit-gallery',
                          extra: g,
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.black.withValues(alpha: 0.6),
                          padding: const EdgeInsets.all(6),
                        ),
                        icon: const Icon(Icons.delete,
                            color: AppColors.error, size: 16),
                        onPressed: () => _confirmDelete(context, g),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, GalleryEntity g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('"${g.title}" will be permanently deleted.'),
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
        await sl<ContentRepository>().deleteGallery(g.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${g.title}" deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    }
  }
}

class _GalleryDetailsPage extends StatelessWidget {
  final GalleryEntity item;
  const _GalleryDetailsPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: Text(item.title),
      ),
      body: Center(
        child: item.imageUrl.isNotEmpty
            ? Image.network(
                DriveUrlHelper.convertToDirectImageUrl(item.imageUrl) ??
                    item.imageUrl,
                fit: BoxFit.contain,
              )
            : const Icon(Icons.image, size: 100, color: Colors.white),
      ),
    );
  }
}
