import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../data/verification_repository.dart';

class SingleProductUploadPage extends ConsumerStatefulWidget {
  const SingleProductUploadPage({super.key});

  @override
  ConsumerState<SingleProductUploadPage> createState() =>
      _SingleProductUploadPageState();
}

class _SingleProductUploadPageState
    extends ConsumerState<SingleProductUploadPage> {
  bool _didInitFromRoute = false;
  String _sector = '';
  String _mode = 'verification'; // 'verification' | 'warranty'

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryId = TextEditingController();
  final TextEditingController _productName = TextEditingController();
  final TextEditingController _customFieldsJson = TextEditingController();

  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;

    final GoRouterState state = GoRouterState.of(context);
    final Object? extra = state.extra;
    final String? extraSector = extra is String ? extra : null;
    _sector = (extraSector ?? state.uri.queryParameters['sector'] ?? '').trim();
    _categoryId.text =
        (state.uri.queryParameters['category_id'] ?? _sector).trim();

    final String mode = (state.uri.queryParameters['mode'] ?? 'verification')
        .trim()
        .toLowerCase();
    if (mode == 'warranty' || mode == 'verification') _mode = mode;
  }

  @override
  void dispose() {
    _categoryId.dispose();
    _productName.dispose();
    _customFieldsJson.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  Map<String, dynamic>? _parseCustomFields() {
    final String raw = _customFieldsJson.text.trim();
    if (raw.isEmpty) return null;
    final dynamic decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('custom_fields must be a JSON object.');
  }

  Future<void> _copy(String text, {required String label}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  Future<void> _showSuccessSheet(SingleProductUploadResponse res) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Invite Created', style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  res.message.isEmpty
                      ? 'Share the invite link to upload documents/images.'
                      : res.message,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                _KeyValueRow(label: 'Entity ID', value: res.entityId),
                const SizedBox(height: AppSpacing.x2),
                _KeyValueRow(label: 'Entity Type', value: res.entityType),
                const SizedBox(height: AppSpacing.x2),
                _KeyValueRow(label: 'Invite Token', value: res.inviteToken),
                const SizedBox(height: AppSpacing.x2),
                _KeyValueRow(label: 'Invite Link', value: res.inviteLink),
                const SizedBox(height: AppSpacing.x4),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TMZButton(
                        label: 'Copy Link',
                        icon: Icons.copy_rounded,
                        onPressed: res.inviteLink.trim().isEmpty
                            ? null
                            : () => _copy(res.inviteLink, label: 'Invite link'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: TMZButton(
                        label: 'Open Link',
                        icon: Icons.open_in_new_rounded,
                        variant: TMZButtonVariant.secondary,
                        onPressed: res.inviteLink.trim().isEmpty
                            ? null
                            : () async {
                                final Uri uri = Uri.parse(res.inviteLink);
                                if (!await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                )) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not open link.'),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                SizedBox(
                  width: double.infinity,
                  child: TMZButton(
                    label: 'Done',
                    variant: TMZButtonVariant.ghost,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final FormState? state = _formKey.currentState;
    if (state == null) return;
    if (!state.validate()) return;

    setState(() => _submitting = true);
    try {
      final Map<String, dynamic>? customFields = _parseCustomFields();
      final repo = ref.read(verificationRepositoryProvider);
      final SingleProductUploadResponse res = await repo.uploadSingleProduct(
        categoryId: _categoryId.text,
        productName: _productName.text,
        customFields: <String, dynamic>{
          if (_sector.trim().isNotEmpty) 'sector': _sector.trim(),
          'mode': _mode,
          if (customFields != null) ...customFields,
        },
      );
      if (!mounted) return;
      await _showSuccessSheet(res);
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String modeLabel = _mode == 'warranty' ? 'Warranty' : 'Verification';
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Single Product • $modeLabel'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.x4),
            children: <Widget>[
              Text('Add one product', style: AppTypography.display2),
              const SizedBox(height: AppSpacing.x2),
              Text(
                'Create an invite link to upload product documents/images.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
              TextFormField(
                controller: _categoryId,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Category ID', hint: _sector),
                validator: (String? v) =>
                    _requiredValidator(v, label: 'Category ID'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _productName,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Product Name'),
                validator: (String? v) =>
                    _requiredValidator(v, label: 'Product name'),
              ),
              const SizedBox(height: AppSpacing.x4),
              Text('Custom Fields (Optional)', style: AppTypography.heading2),
              const SizedBox(height: AppSpacing.x2),
              TextFormField(
                controller: _customFieldsJson,
                minLines: 4,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                decoration: _decoration(
                  'custom_fields JSON',
                  hint: '{\n  "serial_number": "...",\n  "model": "..."\n}',
                ),
              ),
              const SizedBox(height: AppSpacing.x5),
              TMZButton(
                label: 'Create Invite',
                icon: Icons.send_rounded,
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              value.isEmpty ? '-' : value,
              style: AppTypography.body2.copyWith(height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}
