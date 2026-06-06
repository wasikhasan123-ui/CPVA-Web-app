import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/member_photo_cache.dart';
import '../../../data/datasources/photo_service.dart';

class PhotoAvatar extends StatefulWidget {
  final String? ownerId;
  final String? photoUrl;
  final PhotoService photoService;
  final String initials;
  final double radius;
  final bool showOverlay;
  final bool refreshable;

  const PhotoAvatar({
    super.key,
    this.ownerId,
    this.photoUrl,
    required this.photoService,
    required this.initials,
    this.radius = 24,
    this.showOverlay = false,
    this.refreshable = false,
  });

  @override
  State<PhotoAvatar> createState() => _PhotoAvatarState();
}

class _PhotoAvatarState extends State<PhotoAvatar> {
  String? _customPath;
  Uint8List? _customBytes;
  Uint8List? _cachedBytes;
  late final MemberPhotoCache _photoCache;

  @override
  void initState() {
    super.initState();
    _photoCache = sl<MemberPhotoCache>();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant PhotoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId ||
        oldWidget.photoUrl != widget.photoUrl ||
        oldWidget.photoService != widget.photoService) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final id = widget.ownerId;
    final url = widget.photoUrl;
    String? customPath;
    Uint8List? customBytes;
    Uint8List? cached;

    if (id != null) {
      customPath = await widget.photoService.getCustomPhoto(id);
      if (customPath != null && customPath.startsWith('data:')) {
        final comma = customPath.indexOf(',');
        if (comma >= 0) {
          try {
            customBytes = base64.decode(customPath.substring(comma + 1));
          } catch (_) {}
        }
      }
    }
    if (customBytes == null && id != null && url != null && url.isNotEmpty) {
      cached = await _photoCache.get(id, url);
    }

    if (mounted) {
      setState(() {
        _customPath = customPath;
        _customBytes = customBytes;
        _cachedBytes = cached;
      });
    }
  }

  Future<void> _onChangePhoto() async {
    if (widget.ownerId == null) return;
    final svc = widget.photoService;
    final src = await showModalBottomSheet<_PhotoSrc>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, _PhotoSrc.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, _PhotoSrc.camera),
            ),
            if (_customBytes != null ||
                (_customPath != null &&
                    _customPath!.isNotEmpty &&
                    !_customPath!.startsWith('data:') &&
                    !kIsWeb))
              ListTile(
                leading:
                    const Icon(Icons.delete, color: AppColors.error),
                title: const Text(
                  'Remove custom photo',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(context, _PhotoSrc.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (src == null) return;
    try {
      if (src == _PhotoSrc.remove) {
        await svc.removeCustomPhoto(widget.ownerId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom photo removed')),
          );
        }
      } else if (src == _PhotoSrc.gallery) {
        await svc.pickFromGallery(ownerId: widget.ownerId!);
      } else {
        await svc.takePhoto(ownerId: widget.ownerId!);
      }
      _resolve();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustom = _customBytes != null ||
        (_customPath != null &&
            _customPath!.isNotEmpty &&
            !_customPath!.startsWith('data:') &&
            !kIsWeb);
    final inner = _buildInner();
    if (!widget.showOverlay) return inner;
    return GestureDetector(
      onTap: widget.refreshable ? _onChangePhoto : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          inner,
          if (widget.refreshable)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasCustom ? Icons.check : Icons.camera_alt,
                  color: AppColors.white,
                  size: widget.radius * 0.45,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInner() {
    if (_customBytes != null) {
      return _wrap(
        Image.memory(
          _customBytes!,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _InitialsAvatar(
            initials: widget.initials,
            radius: widget.radius,
          ),
        ),
      );
    }
    if (_customPath != null &&
        !_customPath!.startsWith('data:') &&
        !kIsWeb) {
      return _wrap(
        Image.file(
          File(_customPath!),
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _InitialsAvatar(
            initials: widget.initials,
            radius: widget.radius,
          ),
        ),
      );
    }
    if (_cachedBytes != null) {
      return _wrap(
        Image.memory(
          _cachedBytes!,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _InitialsAvatar(
            initials: widget.initials,
            radius: widget.radius,
          ),
        ),
      );
    }
    return _InitialsAvatar(
      initials: widget.initials,
      radius: widget.radius,
    );
  }

  Widget _wrap(Widget child) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      child: ClipOval(child: child),
    );
  }
}

enum _PhotoSrc { gallery, camera, remove }

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double radius;

  const _InitialsAvatar({required this.initials, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
