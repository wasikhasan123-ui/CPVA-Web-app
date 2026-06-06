import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../data/datasources/photo_service.dart';
import 'photo_avatar.dart';

class MemberAvatar extends StatelessWidget {
  final String? memberId;
  final String? photoUrl;
  final String initials;
  final double radius;
  final bool showOverlay;
  final bool refreshable;

  const MemberAvatar({
    super.key,
    this.memberId,
    this.photoUrl,
    required this.initials,
    this.radius = 24,
    this.showOverlay = false,
    this.refreshable = false,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoAvatar(
      ownerId: memberId,
      photoUrl: photoUrl,
      photoService: sl<PhotoService>(instanceName: 'member'),
      initials: initials,
      radius: radius,
      showOverlay: showOverlay,
      refreshable: refreshable,
    );
  }
}

class ExecutiveAvatar extends StatelessWidget {
  final String? executiveId;
  final String? photoUrl;
  final String initials;
  final double radius;
  final bool showOverlay;
  final bool refreshable;

  const ExecutiveAvatar({
    super.key,
    this.executiveId,
    this.photoUrl,
    required this.initials,
    this.radius = 24,
    this.showOverlay = false,
    this.refreshable = false,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoAvatar(
      ownerId: executiveId,
      photoUrl: photoUrl,
      photoService: sl<PhotoService>(instanceName: 'executive'),
      initials: initials,
      radius: radius,
      showOverlay: showOverlay,
      refreshable: refreshable,
    );
  }
}
