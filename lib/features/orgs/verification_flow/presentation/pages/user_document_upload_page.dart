import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/file_picker_util.dart';
import '../../../data/verification_repository.dart';

class UserDocumentUploadPage extends ConsumerStatefulWidget {
  const UserDocumentUploadPage({super.key});

  @override
  ConsumerState<UserDocumentUploadPage> createState() =>
      _UserDocumentUploadPageState();
}

class _UserDocumentUploadPageState
    extends ConsumerState<UserDocumentUploadPage> {
  bool _didInit = false;
  String _token = '';

  bool _uploadingPhoto = false;
  Uint8List? _photoBytes;
  bool _photoUploaded = false;

  final Map<String, bool> _uploadedDocs = <String, bool>{
    'aadhar': false,
    'pan': false,
    'degree_certificate': false,
    'driving_license': false,
  };

  final Map<String, int> _docVersions = <String, int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _token = (GoRouterState.of(context).uri.queryParameters['token'] ?? '')
        .trim();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;
    if (_token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing invite token.')));
      return;
    }
    final PickedFile? picked = await FilePickerUtil.pickImage();
    if (picked == null) return;

    setState(() {
      _uploadingPhoto = true;
      _photoBytes = picked.bytes;
    });

    try {
      final repo = ref.read(verificationRepositoryProvider);
      await repo.uploadPhoto(
        inviteToken: _token,
        fileBytes: picked.bytes,
        fileName: picked.name,
      );
      if (!mounted) return;
      setState(() => _photoUploaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickAndUploadDoc(String label) async {
    if (_token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing invite token.')));
      return;
    }

    final PickedFile? picked = await FilePickerUtil.pickDocument();
    if (picked == null) return;

    setState(() => _uploadedDocs[label] = false);
    try {
      final repo = ref.read(verificationRepositoryProvider);
      final res = await repo.uploadDocument(
        inviteToken: _token,
        documentLabel: label,
        fileBytes: picked.bytes,
        fileName: picked.name,
      );
      if (!mounted) return;
      setState(() {
        _uploadedDocs[label] = true;
        _docVersions[label] = res.version;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isEmpty ? 'Uploaded.' : res.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showDoneSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Submitted', style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Your documents have been submitted. The organisation will review them and notify you.',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Okay'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasToken = _token.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text('Upload Your Documents'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x4),
          children: <Widget>[
            _InfoCard(
              title: 'Hello!',
              subtitle:
                  'Your organisation has requested document verification. Please upload the following.',
            ),
            const SizedBox(height: AppSpacing.x4),
            Text('Your Photo', style: AppTypography.heading2),
            const SizedBox(height: AppSpacing.x2),
            _UploadZone(
              onTap: hasToken ? _pickAndUploadPhoto : null,
              child: _photoBytes == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 32,
                          color: AppColors.brandBlue.withAlpha(220),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _uploadingPhoto
                              ? 'Uploading…'
                              : (hasToken ? 'Tap to upload' : 'Invalid link'),
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 44,
                          backgroundImage: MemoryImage(_photoBytes!),
                        ),
                        if (_photoUploaded)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text('Documents', style: AppTypography.heading2),
            const SizedBox(height: AppSpacing.x2),
            _DocTile(
              title: 'Aadhar Card',
              icon: Icons.credit_card_rounded,
              uploaded: _uploadedDocs['aadhar'] == true,
              version: _docVersions['aadhar'],
              onTap: hasToken ? () => _pickAndUploadDoc('aadhar') : null,
            ),
            const SizedBox(height: AppSpacing.x2),
            _DocTile(
              title: 'PAN Card',
              icon: Icons.badge_rounded,
              uploaded: _uploadedDocs['pan'] == true,
              version: _docVersions['pan'],
              onTap: hasToken ? () => _pickAndUploadDoc('pan') : null,
            ),
            const SizedBox(height: AppSpacing.x2),
            _DocTile(
              title: 'Degree/Certificate',
              icon: Icons.school_rounded,
              uploaded: _uploadedDocs['degree_certificate'] == true,
              version: _docVersions['degree_certificate'],
              onTap: hasToken
                  ? () => _pickAndUploadDoc('degree_certificate')
                  : null,
            ),
            const SizedBox(height: AppSpacing.x2),
            _DocTile(
              title: 'Driving License',
              icon: Icons.directions_car_rounded,
              uploaded: _uploadedDocs['driving_license'] == true,
              version: _docVersions['driving_license'],
              onTap: hasToken
                  ? () => _pickAndUploadDoc('driving_license')
                  : null,
            ),
            const SizedBox(height: AppSpacing.x6),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _showDoneSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withAlpha(150)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: AppColors.brandBlue.withAlpha(153),
              strokeWidth: 1.5,
              radius: 20,
              dash: const <double>[6, 4],
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x5),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.title,
    required this.icon,
    required this.uploaded,
    required this.version,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool uploaded;
  final int? version;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: uploaded
                      ? AppColors.successBg
                      : AppColors.brandBlue.withAlpha(14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  uploaded ? Icons.check_circle_rounded : icon,
                  color: uploaded ? AppColors.success : AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      uploaded
                          ? 'Uploaded${version == null ? '' : ' • v${version.toString()}'}'
                          : 'Tap to upload',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dash,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final List<double> dash;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final PathMetrics metrics = path.computeMetrics();

    for (final PathMetric metric in metrics) {
      double distance = 0;
      int index = 0;
      while (distance < metric.length) {
        final double len = dash[index % dash.length];
        final bool draw = index.isEven;
        if (draw) {
          final Path extract = metric.extractPath(
            distance,
            (distance + len).clamp(0, metric.length),
          );
          canvas.drawPath(extract, paint);
        }
        distance += len;
        index += 1;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dash != dash;
  }
}
