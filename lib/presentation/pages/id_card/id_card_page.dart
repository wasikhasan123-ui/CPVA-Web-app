import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/cpva_info.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_text.dart';
import '../../../data/datasources/executive_local_datasource.dart';
import '../../../data/models/executive_member_model.dart';
import '../../../domain/entities/member_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/member_avatar.dart';

class IdCardPage extends StatefulWidget {
  const IdCardPage({super.key});

  @override
  State<IdCardPage> createState() => _IdCardPageState();
}

class _IdCardPageState extends State<IdCardPage> {
  final PageController _pageController = PageController();
  final GlobalKey _frontCardKey = GlobalKey();
  final GlobalKey _backCardKey = GlobalKey();

  int _page = 0;
  bool _downloading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital ID Card'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = state.user;
          return FutureBuilder<ExecutiveMemberModel?>(
            future: _lookupExecutive(user),
            builder: (context, snap) {
              final exec = snap.data;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final cardW = maxW < 520 ? maxW - 32 : 480.0;
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: cardW,
                            child: AspectRatio(
                              aspectRatio: 1.45 / 1,
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (i) =>
                                    setState(() => _page = i),
                                children: [
                                  RepaintBoundary(
                                    key: _frontCardKey,
                                    child: _FrontSide(
                                      user: user,
                                      executive: exec,
                                      cardW: cardW,
                                    ),
                                  ),
                                  RepaintBoundary(
                                    key: _backCardKey,
                                    child: _BackSide(
                                      user: user,
                                      cardW: cardW,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _pageController.animateToPage(
                                  0,
                                  duration:
                                      const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                ),
                                child: _dot(0),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _pageController.animateToPage(
                                  1,
                                  duration:
                                      const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                ),
                                child: _dot(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _page == 0
                                ? 'সম্মুখ ভাগ (Front Side)'
                                : 'বিপরীত ভাগ (Back Side)',
                            style: BengaliText.regular(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: cardW,
                            child: FilledButton.icon(
                              onPressed: _downloading
                                  ? null
                                  : () => _downloadIdCardPdf(
                                        user: user,
                                        executive: exec,
                                      ),
                              icon: _downloading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(
                                _downloading
                                    ? 'Preparing ID Card...'
                                    : 'Download ID Card',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Downloads front and back sides as a PDF',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _downloadIdCardPdf({
    required MemberEntity user,
    required ExecutiveMemberModel? executive,
  }) async {
    if (_downloading) return;

    setState(() => _downloading = true);

    final originalPage = _page;

    try {
      // Capture front side.
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      final frontBytes = await _captureBoundary(_frontCardKey);

      // Capture back side.
      await _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      final backBytes = await _captureBoundary(_backCardKey);

      // Restore the page user was viewing.
      if (mounted) {
        await _pageController.animateToPage(
          originalPage,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }

      final pdfBytes = await _buildIdCardPdf(
        frontBytes: frontBytes,
        backBytes: backBytes,
        user: user,
        executive: executive,
      );

      final fileName = _idCardFileName(user);

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digital ID card is ready to download'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download ID card: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<Uint8List> _captureBoundary(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      throw Exception('ID card is not ready yet. Please try again.');
    }

    final boundary = context.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('Could not capture ID card.');
    }

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Could not create ID card image.');
    }

    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> _buildIdCardPdf({
    required Uint8List frontBytes,
    required Uint8List backBytes,
    required MemberEntity user,
    required ExecutiveMemberModel? executive,
  }) async {
    final doc = pw.Document();

    final frontImage = pw.MemoryImage(frontBytes);
    final backImage = pw.MemoryImage(backBytes);

    pw.Widget buildPage(pw.ImageProvider image, String title) {
      return pw.Container(
        width: double.infinity,
        height: double.infinity,
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Expanded(
              child: pw.Center(
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (_) => buildPage(frontImage, 'CPVA Digital ID Card - Front'),
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (_) => buildPage(backImage, 'CPVA Digital ID Card - Back'),
      ),
    );

    return doc.save();
  }

  String _idCardFileName(MemberEntity user) {
    final cleanName = user.name
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final cleanMobile = user.mobileClean.isNotEmpty
        ? user.mobileClean
        : user.mobile.replaceAll(RegExp(r'[^\d]'), '');

    final namePart = cleanName.isNotEmpty ? cleanName : 'member';
    final mobilePart = cleanMobile.isNotEmpty ? '_$cleanMobile' : '';

    return 'CPVA_ID_$namePart$mobilePart.pdf';
  }

  Future<ExecutiveMemberModel?> _lookupExecutive(MemberEntity user) async {
    try {
      final all = await sl<ExecutiveLocalDataSource>().getAll();
      try {
        return all.firstWhere(
          (e) => e.mobileClean == user.mobileClean,
        );
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Widget _dot(int i) {
    final active = _page == i;
    return Container(
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.textHint,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _FrontSide extends StatelessWidget {
  final MemberEntity user;
  final ExecutiveMemberModel? executive;
  final double cardW;

  const _FrontSide({
    required this.user,
    this.executive,
    required this.cardW,
  });

  @override
  Widget build(BuildContext context) {
    final validity = CpvaInfo.cardValidity();
    final validityText = CpvaInfo.formatValidity(validity);

    final nameBn = executive?.nameBn ?? '';
    final name = nameBn.isNotEmpty ? nameBn : user.name;
    final designation = executive?.designationBn ?? 'সাধারণ সদস্য';
    final designationEn = executive?.designation ?? 'General Member';
    final memberNo = executive != null
        ? executive!.id.replaceFirst('Cpva-', 'CPVA-').toUpperCase()
        : 'CPVA-${user.bvcRegNo.padLeft(4, "0")}';

    final unit = cardW / 100;

    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(unit * 1.5),
      ),
      child: Column(
        children: [
          _header(unit),
          Expanded(
            child: Container(
              color: CpvaInfo.cardBody,
              padding: EdgeInsets.fromLTRB(
                unit * 2.2,
                unit * 2,
                unit * 2.2,
                unit * 1.5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BengaliText.bold(
                            fontSize: unit * 3.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: unit * 1.2),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: unit * 1.4,
                            vertical: unit * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: CpvaInfo.cardAccent,
                            borderRadius:
                                BorderRadius.circular(unit * 0.6),
                          ),
                          child: Text(
                            '$designation ($designationEn)',
                            style: BengaliText.semibold(
                              fontSize: unit * 2.3,
                              color: AppColors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: unit * 2.4),
                        _kv(
                          CpvaInfo.idLabel,
                          memberNo,
                          unit: unit,
                        ),
                        SizedBox(height: unit * 1.4),
                        _kv(
                          CpvaInfo.bloodGroupLabel,
                          _bloodGroupDisplay(user.bloodGroup),
                          unit: unit,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: unit * 1.8),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.06),
                              border: Border.all(
                                color: AppColors.textHint,
                                width: 1,
                              ),
                              borderRadius:
                                  BorderRadius.circular(unit * 0.8),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(unit * 0.6),
                              child: MemberAvatar(
                                memberId: user.id,
                                photoUrl: user.photoUrl.isNotEmpty
                                    ? user.photoUrl
                                    : null,
                                initials: user.initials,
                                radius: 200,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: unit * 0.8),
                        Text(
                          CpvaInfo.photoPlaceholder,
                          style: TextStyle(
                            fontSize: unit * 2.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          CpvaInfo.photoHint,
                          style: BengaliText.regular(
                            fontSize: unit * 1.9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: CpvaInfo.cardAccent,
            padding: EdgeInsets.symmetric(vertical: unit * 1.5),
            alignment: Alignment.center,
            child: Text(
              '${CpvaInfo.validityPrefix}$validityText',
              style: TextStyle(
                color: AppColors.white,
                fontSize: unit * 2.4,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(double unit) {
    return Container(
      width: double.infinity,
      color: CpvaInfo.cardHeader,
      padding: EdgeInsets.fromLTRB(
        unit * 1.8,
        unit * 1.5,
        unit * 1.8,
        unit * 1.5,
      ),
      child: Row(
        children: [
          Container(
            width: unit * 7,
            height: unit * 7,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'CPVA',
              style: TextStyle(
                color: CpvaInfo.cardHeader,
                fontSize: unit * 1.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: unit * 1.6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  CpvaInfo.orgName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: unit * 2.2,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: unit * 0.3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${CpvaInfo.orgNameBn} ${CpvaInfo.estd}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: BengaliText.regular(
                      fontSize: unit * 2.0,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: unit * 7),
        ],
      ),
    );
  }

  Widget _kv(String label, String value, {required double unit}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: unit * 13,
          child: Text(
            label,
            style: BengaliText.regular(
              fontSize: unit * 2.2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: BengaliText.medium(
              fontSize: unit * 2.2,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _bloodGroupDisplay(String bg) {
    if (bg.isEmpty) return 'N/A';
    final bn = CpvaInfo.bloodGroupBn[bg.trim()];
    if (bn != null) return '$bg ($bn)';
    return bg;
  }
}

class _BackSide extends StatelessWidget {
  final MemberEntity user;
  final double cardW;

  const _BackSide({required this.user, required this.cardW});

  @override
  Widget build(BuildContext context) {
    final unit = cardW / 100;
    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(unit * 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: CpvaInfo.cardBackHeader,
            padding: EdgeInsets.symmetric(vertical: unit * 1.5),
            alignment: Alignment.center,
            child: Text(
              CpvaInfo.termsHeader,
              style: TextStyle(
                color: AppColors.white,
                fontSize: unit * 2.3,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: CpvaInfo.cardBody,
              padding: EdgeInsets.fromLTRB(
                unit * 2.2,
                unit * 2,
                unit * 2.2,
                unit * 1.5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...CpvaInfo.termsBn.map(
                    (t) => Padding(
                      padding: EdgeInsets.only(bottom: unit * 1.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                top: unit * 0.2, right: unit * 0.6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: unit * 2.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              t,
                              style: BengaliText.regular(
                                fontSize: unit * 2.2,
                                color: AppColors.textPrimary,
                              ).copyWith(height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _signature(
                          CpvaInfo.sigLeft,
                          CpvaInfo.sigLeftSub,
                          unit: unit,
                        ),
                      ),
                      Expanded(
                        child: _signature(
                          CpvaInfo.sigRight,
                          CpvaInfo.sigRightSub,
                          unit: unit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: CpvaInfo.cardAccent,
            padding: EdgeInsets.symmetric(vertical: unit * 1.5),
            alignment: Alignment.center,
            child: Text(
              CpvaInfo.backFooter,
              style: TextStyle(
                color: AppColors.white,
                fontSize: unit * 2.2,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signature(String label, String sub, {required double unit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 1,
          color: AppColors.textHint,
          margin: EdgeInsets.symmetric(horizontal: unit * 2),
        ),
        SizedBox(height: unit * 0.8),
        Text(
          label,
          style: BengaliText.bold(
            fontSize: unit * 2.2,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          sub,
          style: BengaliText.regular(
            fontSize: unit * 1.8,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
