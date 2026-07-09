import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/verification_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';
import '../../../orgs/data/verification_repository.dart';

class IndividualSdcRecordDetailPage extends ConsumerStatefulWidget {
  const IndividualSdcRecordDetailPage({super.key});

  @override
  ConsumerState<IndividualSdcRecordDetailPage> createState() =>
      _IndividualSdcRecordDetailPageState();
}

class _IndividualSdcRecordDetailPageState
    extends ConsumerState<IndividualSdcRecordDetailPage> {
  bool _didInit = false;
  String _publicId = '';
  String _instanceKey = 'de';

  AsyncValue<SdcRecordDetailResponse> _data = const AsyncLoading();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    _publicId = (qp['public_id'] ?? qp['publicId'] ?? '').trim();
    _instanceKey = (qp['instance_key'] ?? qp['instanceKey'] ?? 'de').trim();
    _load();
  }

  Future<void> _load() async {
    if (_publicId.isEmpty) {
      setState(() {
        _data = AsyncError(
          const ApiException(statusCode: null, message: 'Missing public_id.'),
          StackTrace.current,
        );
      });
      return;
    }
    setState(() => _data = const AsyncLoading());
    try {
      final VerificationRepository repo = ref.read(verificationRepositoryProvider);
      final SdcRecordDetailResponse res = await repo.getSdcRecord(
        publicId: _publicId,
        instanceKey: _instanceKey,
      );
      if (!mounted) return;
      setState(() => _data = AsyncData(res));
    } on ApiException catch (e, st) {
      if (!mounted) return;
      setState(() => _data = AsyncError(e, st));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _data = AsyncError(e, st));
    }
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRouter.appSdcPath);
  }

  Future<void> _openUrl(String url) async {
    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null || url.trim().isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x3,
                AppSpacing.x4,
                AppSpacing.x3,
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Single SDC Record',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _data.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object err, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Unable to load record',
                          style: AppTypography.display2,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          err.toString(),
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (SdcRecordDetailResponse res) {
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.x4,
                        AppSpacing.x4,
                        AppSpacing.x4,
                        AppSpacing.x6 +
                            MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      children: <Widget>[
                        TMZCard(
                          padding: const EdgeInsets.all(AppSpacing.x4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Record Details',
                                style: AppTypography.heading2.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.x3),
                              _kv('Public ID', res.publicId),
                              _kv('Instance Key', _instanceKey),
                              _kv('PDF', res.pdfUrl.isEmpty ? 'Unavailable' : res.pdfUrl),
                              _kv(
                                'Verify',
                                res.verifyUrl.isEmpty ? 'Unavailable' : res.verifyUrl,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        TMZButton(
                          label: 'Open PDF',
                          icon: Icons.picture_as_pdf_rounded,
                          onPressed: res.pdfUrl.trim().isEmpty
                              ? null
                              : () => _openUrl(res.pdfUrl),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        TMZButton(
                          label: 'Open Verify Page',
                          icon: Icons.verified_rounded,
                          variant: TMZButtonVariant.secondary,
                          onPressed: res.verifyUrl.trim().isEmpty
                              ? null
                              : () => _openUrl(res.verifyUrl),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              key,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
