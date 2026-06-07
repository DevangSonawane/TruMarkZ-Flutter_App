import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class IndividualSingleUploadPage extends StatefulWidget {
  const IndividualSingleUploadPage({super.key});

  @override
  State<IndividualSingleUploadPage> createState() =>
      _IndividualSingleUploadPageState();
}

class _IndividualSingleUploadPageState extends State<IndividualSingleUploadPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  String get _industry => GoRouterState.of(context).uri.queryParameters['industry'] ?? '';
  String get _industryLabel =>
      GoRouterState.of(context).uri.queryParameters['industry_label'] ?? '';
  String get _checks =>
      GoRouterState.of(context).uri.queryParameters['checks'] ?? '';

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

  String? _requiredValidator(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
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

  void _continue() {
    final Uri uri = Uri(
      path: AppRouter.individualVerificationCertificatePreviewPath,
      queryParameters: <String, String>{
        'flow': 'individual',
        if (_industry.isNotEmpty) 'industry': _industry,
        if (_industryLabel.isNotEmpty) 'industry_label': _industryLabel,
        if (_checks.isNotEmpty) 'checks': _checks,
        'full_name': _fullName.text.trim(),
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Single Verification Upload'),
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
                'Fill in the details for an individual verification request.',
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
                        if (_industryLabel.isNotEmpty)
                          Text(
                            'Industry: $_industryLabel',
                            style: AppTypography.body2.copyWith(height: 1.25),
                          ),
                        if (_checks.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            'Checks: $_checks',
                            style: AppTypography.body2.copyWith(height: 1.25),
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
                decoration: _decoration('Full Name', hint: 'Alex Johnson'),
                validator: (String? v) => _requiredValidator(v, label: 'Full name'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Phone Number', hint: '+91 9876543210'),
                validator: (String? v) => _requiredValidator(v, label: 'Phone number'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Email Address', hint: 'name@example.com'),
                validator: (String? v) => _requiredValidator(v, label: 'Email'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _dob,
                decoration: _decoration('Date of Birth', hint: 'YYYY-MM-DD'),
                validator: (String? v) => _requiredValidator(v, label: 'Date of birth'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _aadhar,
                decoration: _decoration('Aadhar Number'),
                validator: (String? v) => _requiredValidator(v, label: 'Aadhar number'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _pan,
                decoration: _decoration('PAN Number'),
                validator: (String? v) => _requiredValidator(v, label: 'PAN number'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _address1,
                decoration: _decoration('Address Line 1'),
                validator: (String? v) => _requiredValidator(v, label: 'Address line 1'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _address2,
                decoration: _decoration('Address Line 2'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _address3,
                decoration: _decoration('Address Line 3'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _pincode,
                keyboardType: TextInputType.number,
                decoration: _decoration('Pincode'),
                validator: (String? v) => _requiredValidator(v, label: 'Pincode'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _state,
                decoration: _decoration('State'),
                validator: (String? v) => _requiredValidator(v, label: 'State'),
              ),
              const SizedBox(height: AppSpacing.x3),
              TextFormField(
                controller: _country,
                decoration: _decoration('Country'),
                validator: (String? v) => _requiredValidator(v, label: 'Country'),
              ),
              const SizedBox(height: AppSpacing.x4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final FormState? state = _formKey.currentState;
                    if (state == null || !state.validate()) return;
                    _continue();
                  },
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
