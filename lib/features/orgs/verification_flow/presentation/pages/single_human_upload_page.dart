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

class SingleHumanUploadPage extends ConsumerStatefulWidget {
  const SingleHumanUploadPage({super.key});

  @override
  ConsumerState<SingleHumanUploadPage> createState() =>
      _SingleHumanUploadPageState();
}

class _SingleHumanUploadPageState extends ConsumerState<SingleHumanUploadPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _didInitFromRoute = false;
  String _industry = '';
  List<String> _checks = <String>[];
  String _access = '';
  List<String> _consent = <String>[];

  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();

  final TextEditingController _dob = TextEditingController();
  final TextEditingController _aadhar = TextEditingController();
  final TextEditingController _pan = TextEditingController();
  final TextEditingController _address1 = TextEditingController();
  final TextEditingController _address2 = TextEditingController();
  final TextEditingController _address3 = TextEditingController();
  final TextEditingController _pincode = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _country = TextEditingController();

  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;

    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    _industry = (qp['industry'] ?? '').trim();
    final String checksRaw = (qp['checks'] ?? '').trim();
    _checks = checksRaw.isEmpty
        ? <String>[]
        : checksRaw
            .split(',')
            .map((String s) => s.trim())
            .where((String s) => s.isNotEmpty)
            .toList();

    _access = (qp['access'] ?? '').trim();
    final String consentRaw = (qp['consent'] ?? '').trim();
    _consent = consentRaw.isEmpty
        ? <String>[]
        : consentRaw
            .split(',')
            .map((String s) => s.trim())
            .where((String s) => s.isNotEmpty)
            .toList();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _dob.dispose();
    _aadhar.dispose();
    _pan.dispose();
    _address1.dispose();
    _address2.dispose();
    _address3.dispose();
    _pincode.dispose();
    _state.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _copy(String text, {required String label}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  Future<void> _showSuccessSheet(SingleHumanUploadResponse res) async {
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
                      ? 'Share the invite link with the user to upload documents.'
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
      final repo = ref.read(verificationRepositoryProvider);
      final SingleHumanUploadResponse res = await repo.uploadSingleHuman(
        fullName: _fullName.text,
        phoneNumber: _phone.text,
        email: _email.text,
        dob: _dob.text,
        aadharNumber: _aadhar.text,
        panNumber: _pan.text,
        addressLine1: _address1.text,
        addressLine2: _address2.text,
        addressLine3: _address3.text,
        pincode: _pincode.text,
        state: _state.text,
        country: _country.text,
      );
      if (!mounted) return;
      await _showSuccessSheet(res);
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

  String? _requiredValidator(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Single Human Verification'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.x4),
            children: <Widget>[
              Text('Add one person', style: AppTypography.display2),
              const SizedBox(height: AppSpacing.x2),
              Text(
                'Fill required details to create an invite link for document upload.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
              ),
              if (_industry.isNotEmpty || _checks.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.x4),
                DecoratedBox(
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
                          'Selected Plan',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_industry.isNotEmpty)
                          Text(
                            'Industry: $_industry',
                            style: AppTypography.body2.copyWith(height: 1.25),
                          ),
                        if (_access.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            'Access: $_access',
                            style: AppTypography.body2.copyWith(height: 1.25),
                          ),
                        ],
                        if (_consent.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            'Consent: ${_consent.join(', ')}',
                            style: AppTypography.body2.copyWith(height: 1.25),
                          ),
                        ],
                        if (_checks.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final String c in _checks)
                                Chip(
                                  label: Text(c),
                                  backgroundColor:
                                      AppColors.brandBlue.withAlpha(14),
                                  labelStyle: AppTypography.caption.copyWith(
                                    color: AppColors.brandBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  side: BorderSide(
                                    color: AppColors.brandBlue.withAlpha(20),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x4),
              TextFormField(
                controller: _fullName,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Full Name'),
                validator: (String? v) =>
                    _requiredValidator(v, label: 'Full name'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Phone Number', hint: '+91…'),
                validator: (String? v) =>
                    _requiredValidator(v, label: 'Phone number'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Email'),
                validator: (String? v) => _requiredValidator(v, label: 'Email'),
              ),
              const SizedBox(height: AppSpacing.x4),
              Text('Optional Details', style: AppTypography.heading2),
              const SizedBox(height: AppSpacing.x2),
              TextFormField(
                controller: _dob,
                textInputAction: TextInputAction.next,
                decoration: _decoration('DOB', hint: 'YYYY-MM-DD'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _aadhar,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Aadhar Number'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _pan,
                textInputAction: TextInputAction.next,
                decoration: _decoration('PAN Number'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _address1,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Address Line 1'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _address2,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Address Line 2'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _address3,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Address Line 3'),
              ),
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _pincode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('Pincode'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: TextFormField(
                      controller: _state,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _country,
                textInputAction: TextInputAction.done,
                decoration: _decoration('Country'),
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
