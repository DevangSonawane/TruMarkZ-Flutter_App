import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'dart:math' as math;

import '../../../../core/models/verification_models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/batch_name_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/verification_list_notifier.dart';

class BatchProgressPage extends ConsumerStatefulWidget {
  const BatchProgressPage({super.key});

  @override
  ConsumerState<BatchProgressPage> createState() => _BatchProgressPageState();
}

class _BatchProgressPageState extends ConsumerState<BatchProgressPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () =>
          ref.read(verificationListNotifierProvider.notifier).load(limit: 500),
    );
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double refWidth = 402;
    final VerificationListState state = ref.watch(
      verificationListNotifierProvider,
    );
    final AsyncValue<VerificationListResponse> dataAsync = state.data;

    final VerificationListResponse? data = dataAsync.valueOrNull;
    final Map<String, String> savedBatchNames = ref.watch(
      batchNameStoreProvider,
    );
    final List<_BatchDirectoryItem> directory = data == null
        ? const <_BatchDirectoryItem>[]
        : _BatchDirectoryItem.fromUsers(
            data.users,
            savedBatchNames: savedBatchNames,
          );

    final String search = _searchController.text.trim().toLowerCase();
    final List<_BatchDirectoryItem> filtered = directory.where((
      _BatchDirectoryItem item,
    ) {
      if (search.isEmpty) return true;
      return item.batchName.toLowerCase().contains(search) ||
          item.batchId.toLowerCase().contains(search) ||
          item.updatedLabel.toLowerCase().contains(search);
    }).toList();

    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double contentWidth = math.min(screenWidth, refWidth);
    final double scale = (contentWidth / refWidth).clamp(0.0, 1.0);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(12)),
                  child: _Header(
                    scale: scale,
                    title: 'View All Certificates',
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                        return;
                      }
                      context.go(AppRouter.dashboardPath);
                    },
                    onAlertsTap: () => context.push(
                      '${AppRouter.notificationsPath}?flow=org',
                    ),
                    onProfileTap: () => context.push(AppRouter.settingsPath),
                  ),
                ),
                SizedBox(height: s(21)),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(s(20)),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        s(16),
                        s(32),
                        s(16),
                        s(24) + safeBottom + s(71.016),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _SearchRow(
                            scale: scale,
                            controller: _searchController,
                            onFilterTap: () {},
                          ),
                          SizedBox(height: s(24)),
                          if (dataAsync.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (dataAsync.hasError)
                            _ErrorCard(
                              message: dataAsync.error.toString(),
                              onRetry: () => ref
                                  .read(
                                    verificationListNotifierProvider.notifier,
                                  )
                                  .load(limit: 500),
                            )
                          else
                            Column(
                              children: <Widget>[
                                for (
                                  int i = 0;
                                  i < filtered.length;
                                  i++
                                ) ...<Widget>[
                                  _BatchCertificatesSection(
                                    scale: scale,
                                    item: filtered[i],
                                    imagePair: _carouselPairForIndex(i),
                                    onViewAll: () => context.push(
                                      '${AppRouter.appBatchTrackingDetailPath}?batch_id=${Uri.encodeComponent(filtered[i].batchId)}',
                                    ),
                                  ),
                                  if (i != filtered.length - 1)
                                    SizedBox(height: s(55)),
                                ],
                                if (filtered.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: s(24)),
                                    child: Text(
                                      'No batches found',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(14),
                                        fontWeight: FontWeight.w600,
                                        height: 20 / 14,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static List<String> _carouselPairForIndex(int index) {
    // Use Figma-exported certificate images to keep visuals pixel-perfect.
    // Cycle through the pairs for long lists.
    const List<List<String>> pairs = <List<String>>[
      <String>[
        'assets/images/figma/cert_card_1.png',
        'assets/images/figma/cert_card_2.png',
      ],
      <String>[
        'assets/images/figma/cert_card_3.png',
        'assets/images/figma/cert_card_4.png',
      ],
    ];
    return pairs[index % pairs.length];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.scale,
    required this.title,
    required this.onBack,
    this.onAlertsTap,
    this.onProfileTap,
  });

  final double scale;
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Row(
      children: <Widget>[
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(s(12)),
          child: SizedBox(
            width: s(24),
            height: s(24),
            child: SvgPicture.asset(
              'assets/icons/figma/certificates_back.svg',
              width: s(24),
              height: s(24),
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        SizedBox(width: s(12)),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(20),
              fontWeight: FontWeight.w600,
              height: 19.5 / 20,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: s(12)),
        GestureDetector(
          onTap: onAlertsTap,
          behavior: HitTestBehavior.opaque,
          child: SvgPicture.asset(
            'assets/icons/figma/all_batches_bell.svg',
            width: s(24),
            height: s(24),
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        SizedBox(width: s(12)),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: s(32),
            height: s(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/icons/dashbaord/profile.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.scale,
    required this.controller,
    required this.onFilterTap,
  });

  final double scale;
  final TextEditingController controller;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Row(
      children: <Widget>[
        Expanded(
          child: _SearchInput(scale: scale, controller: controller),
        ),
        SizedBox(width: s(12)),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(s(16)),
          child: Container(
            width: s(48),
            height: s(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(s(16)),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/figma/certificates_filter.svg',
              width: s(16),
              height: s(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.scale, required this.controller});

  final double scale;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return SizedBox(
      height: s(48),
      child: TextField(
        controller: controller,
        maxLines: 1,
        cursorColor: AppColors.brandBlue,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: s(14),
          fontWeight: FontWeight.w400,
          height: 16.70703125 / 14,
          color: const Color(0xFF0B0F19),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: s(16), right: s(14)),
            child: SvgPicture.asset(
              'assets/icons/figma/certificates_search.svg',
              width: s(14),
              height: s(14),
            ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: s(44),
            minHeight: s(48),
          ),
          contentPadding: EdgeInsets.fromLTRB(s(0), s(15), s(16), s(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(s(16)),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(s(16)),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(s(16)),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          hintText: 'Search certificates...',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(14),
            fontWeight: FontWeight.w400,
            height: 16.70703125 / 14,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _BatchCertificatesSection extends StatelessWidget {
  const _BatchCertificatesSection({
    required this.scale,
    required this.item,
    required this.imagePair,
    required this.onViewAll,
  });

  final double scale;
  final _BatchDirectoryItem item;
  final List<String> imagePair;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    final bool verified =
        item.records > 0 && item.verifiedCount >= item.records;
    final _BatchPillStyle pillStyle = verified
        ? _BatchPillStyle.verified
        : _BatchPillStyle.active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.batchName.trim().isNotEmpty
                        ? 'Batch: ${item.batchName.trim()}'
                        : 'Batch #${_batchCodeFromId(item.batchId)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(20),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1833819,
                      height: 17.7507286 / 20,
                      color: const Color(0xFF323232),
                    ),
                  ),
                  SizedBox(height: s(6)),
                  Text(
                    item.updatedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(12),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.1833819,
                      height: 17.7507286 / 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, -s(4)),
              child: _BatchStatusPill(scale: scale, style: pillStyle),
            ),
          ],
        ),
        SizedBox(height: s(14)),
        SizedBox(
          height: s(350),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: imagePair.length,
            clipBehavior: Clip.none,
            padding: EdgeInsets.fromLTRB(0, s(2), s(16), s(2)),
            separatorBuilder: (BuildContext context, int index) =>
                SizedBox(width: s(12)),
            itemBuilder: (BuildContext context, int index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(s(4.6872382)),
                child: Image.asset(
                  imagePair[index],
                  width: s(235),
                  height: s(350),
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        SizedBox(height: s(14)),
        _DashedActionButton(scale: scale, onTap: onViewAll),
      ],
    );
  }

  static String _batchCodeFromId(String batchId) {
    final String id = batchId;
    final String compact = id
        .replaceAll('-', '')
        .replaceAll('_', '')
        .toUpperCase();
    if (compact.isEmpty) return '—';
    if (compact.length <= 8) return compact;
    return '${compact.substring(0, 7)}-${compact.substring(compact.length - 1)}';
  }
}

enum _BatchPillStyle { active, verified }

class _BatchStatusPill extends StatelessWidget {
  const _BatchStatusPill({required this.scale, required this.style});

  final double scale;
  final _BatchPillStyle style;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    final bool isActive = style == _BatchPillStyle.active;
    final Color bg = isActive
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFDCFCE7);
    final Color fg = isActive ? AppColors.brandBlue : const Color(0xFF16A34A);
    final String label = isActive ? 'ACTIVE' : 'VERIFIED';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(4)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: s(12),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          height: 16 / 12,
          color: fg,
        ),
      ),
    );
  }
}

class _DashedActionButton extends StatelessWidget {
  const _DashedActionButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s(24)),
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: AppColors.brandBlue,
          strokeWidth: 1,
          dash: math.max(1, s(3)),
          gap: math.max(1, s(2)),
          radius: s(24),
        ),
        child: Container(
          height: s(56),
          decoration: BoxDecoration(
            color: const Color(0x80F1F5F9),
            borderRadius: BorderRadius.circular(s(24)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'View All SDC',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(16),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.0625,
                  height: 24 / 16,
                  color: AppColors.brandBlue,
                ),
              ),
              SizedBox(width: s(10)),
              SvgPicture.asset(
                'assets/icons/figma/view_all_arrow.svg',
                width: s(14),
                height: s(12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double len = math.min(dash, metric.length - distance);
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap ||
        oldDelegate.radius != radius;
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Failed to load',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 16 / 12,
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _BatchDirectoryItem {
  const _BatchDirectoryItem({
    required this.batchId,
    required this.batchName,
    required this.updatedLabel,
    required this.records,
    required this.pendingCount,
    required this.verifiedCount,
    required this.failedCount,
  });

  final String batchId;
  final String batchName;
  final String updatedLabel;
  final int records;
  final int pendingCount;
  final int verifiedCount;
  final int failedCount;

  static List<_BatchDirectoryItem> fromUsers(
    List<VerificationUser> users, {
    required Map<String, String> savedBatchNames,
  }) {
    final Map<String, List<VerificationUser>> byBatch =
        <String, List<VerificationUser>>{};
    for (final VerificationUser u in users) {
      final String id = u.batchId.trim();
      if (id.isEmpty) continue;
      (byBatch[id] ??= <VerificationUser>[]).add(u);
    }

    final List<_BatchDirectoryItem> items = <_BatchDirectoryItem>[];
    byBatch.forEach((String batchId, List<VerificationUser> batchUsers) {
      int pending = 0;
      int verified = 0;
      int failed = 0;
      DateTime? latest;
      String batchNameFromApi = '';

      for (final VerificationUser u in batchUsers) {
        final String status = u.verificationStatus.toLowerCase();
        if (status.contains('pending')) pending++;
        if (status.contains('verified')) verified++;
        if (status.contains('failed') || status.contains('rejected')) failed++;

        if (batchNameFromApi.isEmpty && u.batchName.trim().isNotEmpty) {
          batchNameFromApi = u.batchName.trim();
        }

        final DateTime? updatedAt = DateTime.tryParse(u.updatedAt);
        final DateTime? createdAt = DateTime.tryParse(u.createdAt);
        final DateTime? candidate = updatedAt ?? createdAt;
        if (candidate != null &&
            (latest == null || candidate.isAfter(latest))) {
          latest = candidate;
        }
      }

      final String updatedLabel = latest == null
          ? 'Updated —'
          : 'Updated ${_formatDate(latest)}';
      final String batchName =
          (savedBatchNames[batchId] ?? '').trim().isNotEmpty
          ? (savedBatchNames[batchId] ?? '').trim()
          : batchNameFromApi;

      items.add(
        _BatchDirectoryItem(
          batchId: batchId,
          batchName: batchName,
          updatedLabel: updatedLabel,
          records: batchUsers.length,
          pendingCount: pending,
          verifiedCount: verified,
          failedCount: failed,
        ),
      );
    });

    items.sort((a, b) => b.updatedLabel.compareTo(a.updatedLabel));
    return items;
  }

  static String _formatDate(DateTime dt) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final DateTime local = dt.toLocal();
    final String m = months[local.month - 1];
    return '$m ${local.day}, ${local.year}';
  }
}
