import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../orgs/verification_flow/presentation/pages/flow_step_progress.dart';
import 'individual_industry_label_utils.dart';

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

  String get _industry =>
      GoRouterState.of(context).uri.queryParameters['industry'] ?? '';
  String get _industryLabel =>
      summarizeIndividualIndustryLabel(
        GoRouterState.of(context).uri.queryParameters['industry_label'] ?? '',
        fallback: '',
      );
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
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const double referenceWidth = 402;
            final double contentWidth = constraints.maxWidth < referenceWidth
                ? constraints.maxWidth
                : referenceWidth;
            final double scale = contentWidth / referenceWidth;
            double s(double v) => v * scale;

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(8), s(16), 0),
                      child: Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: () => context.pop(),
                            radius: s(22),
                            child: SvgPicture.asset(
                              'assets/icons/figma/new_batch_back.svg',
                              width: s(24),
                              height: s(24),
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          SizedBox(width: s(12)),
                          Text(
                            'Single Upload',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: s(21),
                              fontWeight: FontWeight.w600,
                              height: 19.5 / 21,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(24)),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(20)),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(32),
                                  s(16),
                                  s(24),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      FlowStepProgress(
                                        scale: scale,
                                        stepLabel: 'STEP 3 OF 5',
                                        progressLabel: '60%',
                                        fillFactor: 0.6,
                                      ),
                                      SizedBox(height: s(24)),
                                      Text(
                                        'Add One Person',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: s(24),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: s(1.18),
                                          height: 22.6 / 24,
                                          color: const Color(0xFF323232),
                                        ),
                                      ),
                                      SizedBox(height: s(12)),
                                      Text(
                                        'Fill in the details for an individual verification request.',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: s(12),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: s(1.18),
                                          height: 17.75 / 12,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      if (_industry.isNotEmpty ||
                                          _checks.isNotEmpty) ...<Widget>[
                                        SizedBox(height: s(24)),
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              s(16),
                                            ),
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          padding: EdgeInsets.all(s(14)),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                'Selected Plan',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: s(10),
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: s(0.8),
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              SizedBox(height: s(8)),
                                              if (_industryLabel.isNotEmpty)
                                                Text(
                                                  'Industry: $_industryLabel',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: s(13),
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF0F172A,
                                                    ),
                                                  ),
                                                ),
                                              if (_checks.isNotEmpty) ...<Widget>[
                                                SizedBox(height: s(8)),
                                                Text(
                                                  'Checks: $_checks',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: s(13),
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.25,
                                                    color: const Color(
                                                      0xFF334155,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: s(24)),
                                      TextFormField(
                                        controller: _fullName,
                                        decoration: _decoration(
                                          'Full Name',
                                          hint: 'Alex Johnson',
                                        ),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'Full name',
                                            ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _phone,
                                        keyboardType: TextInputType.phone,
                                        decoration: _decoration(
                                          'Phone Number',
                                          hint: '+91 9876543210',
                                        ),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'Phone number',
                                            ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: _decoration(
                                          'Email Address',
                                          hint: 'name@example.com',
                                        ),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'Email',
                                            ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _dob,
                                        decoration: _decoration(
                                          'Date of Birth',
                                          hint: 'YYYY-MM-DD',
                                        ),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'Date of birth',
                                            ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _aadhar,
                                        decoration: _decoration('Aadhar Number'),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'Aadhar number',
                                            ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _pan,
                                        decoration: _decoration('PAN Number'),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'PAN number',
                                            ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _address1,
                                        decoration: _decoration(
                                          'Address Line 1',
                                        ),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'Address line 1',
                                            ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _address2,
                                        decoration: _decoration(
                                          'Address Line 2',
                                        ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _address3,
                                        decoration: _decoration(
                                          'Address Line 3',
                                        ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _pincode,
                                        keyboardType: TextInputType.number,
                                        decoration: _decoration('Pincode'),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'Pincode',
                                            ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _state,
                                        decoration: _decoration('State'),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'State',
                                            ),
                                      ),
                                      SizedBox(height: s(12)),
                                      TextFormField(
                                        controller: _country,
                                        decoration: _decoration('Country'),
                                        validator: (String? v) =>
                                            _requiredValidator(
                                              v,
                                              label: 'Country',
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: SizedBox(
                                width: double.infinity,
                                height: s(60),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.brandBlue,
                                    borderRadius: BorderRadius.circular(s(16)),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(s(16)),
                                      onTap: () {
                                        final FormState? state =
                                            _formKey.currentState;
                                        if (state == null || !state.validate()) {
                                          return;
                                        }
                                        _continue();
                                      },
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              'Continue',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: s(18),
                                                fontWeight: FontWeight.w700,
                                                height: 28 / 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: s(10)),
                                            SvgPicture.asset(
                                              'assets/icons/figma/new_batch_continue_arrow.svg',
                                              width: s(16),
                                              height: s(16),
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.scale,
    required this.child,
  });

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: s(12.864), sigmaY: s(12.864)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            s(13.604),
            s(12.864),
            s(13.668),
            s(12.864),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(204),
            border: Border(
              top: BorderSide(color: const Color(0xFFF3F4F6), width: s(1.072)),
            ),
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}
