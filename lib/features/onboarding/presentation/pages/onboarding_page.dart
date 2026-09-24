import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/google_sign_in_service.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/application/auth_notifier.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _isGoogleLoading = false;

  Future<void> _continueWithGoogle() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _isGoogleLoading = true);

    try {
      await ref.read(tokenStorageProvider).clearAll();

      final ({String? idToken, String? email}) googleResult =
          await GoogleSignInService.signIn();
      final String? idToken = googleResult.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const ApiException(
          statusCode: null,
          message: 'Google sign-in was cancelled.',
        );
      }

      await ref
          .read(authNotifierProvider.notifier)
          .loginWithGoogle(idToken: idToken, userType: 'individual');
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.message.trim().isEmpty
                ? 'Google sign-in failed. Please try again.'
                : e.message,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showSignupOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      elevation: 0,
      builder: (BuildContext sheetContext) {
        final double bottomInset = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;

        void open(String path) {
          Navigator.of(sheetContext).pop();
          context.go(path);
        }

        int selectedIndex = 0;
        String pathFor(int index) => index == 0
            ? '${AppRouter.registerPath}?force=true'
            : AppRouter.organisationRegistrationPath;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SizedBox(
              height: 225 + bottomInset,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(34),
                      blurRadius: 34,
                      offset: const Offset(0, -12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.x5,
                    AppSpacing.x4,
                    AppSpacing.x5,
                    AppSpacing.x5 + bottomInset,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'Who are you?',
                        textAlign: TextAlign.center,
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'Choose between your two roles',
                        textAlign: TextAlign.center,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x5),
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 130,
                                child: _SignupChoiceCard(
                                  label: 'Individual',
                                  selected: selectedIndex == 0,
                                  onTap: () {
                                    if (selectedIndex == 0) {
                                      open(pathFor(0));
                                    } else {
                                      setSheetState(() => selectedIndex = 0);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.x3),
                              SizedBox(
                                width: 130,
                                child: _SignupChoiceCard(
                                  label: 'Organisation',
                                  selected: selectedIndex == 1,
                                  onTap: () {
                                    if (selectedIndex == 1) {
                                      open(pathFor(1));
                                    } else {
                                      setSheetState(() => selectedIndex = 1);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x4),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Image.asset(
                  'assets/onboardingimage.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withAlpha(0),
                        Colors.black.withAlpha(0),
                        Colors.black.withAlpha(150),
                      ],
                      stops: const <double>[0, 0.58, 1],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.x6,
                    AppSpacing.x5,
                    AppSpacing.x6,
                    AppSpacing.x12 + systemBottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            _OnboardingTitleLine(text: 'Real verification.'),
                            const SizedBox(height: AppSpacing.x2),
                            _OnboardingTitleLine(text: 'Smart verification.'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x6),
                        Align(
                          child: SizedBox(
                            width: 252,
                            child: _PrimaryOnboardingButton(
                              onPressed: _showSignupOptions,
                              label: 'Sign up',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Divider(color: Colors.white.withAlpha(45)),
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            Text(
                              'Or',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withAlpha(105),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            Expanded(
                              child: Divider(color: Colors.white.withAlpha(45)),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 76,
                              child: _IconAuthButton(
                                onPressed: _isGoogleLoading
                                    ? null
                                    : _continueWithGoogle,
                                icon: _isGoogleLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : SvgPicture.asset(
                                        'assets/icons/google-icon-logo-svgrepo-com.svg',
                                        width: 18,
                                        height: 18,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            SizedBox(
                              width: 76,
                              child: _IconAuthButton(
                                onPressed: () =>
                                    context.go(AppRouter.loginPath),
                                icon: const Icon(
                                  Icons.alternate_email_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withAlpha(165),
                              height: 1.35,
                            ),
                            children: <InlineSpan>[
                              const TextSpan(
                                text: 'By using TruMarkZ, you agree to\n',
                              ),
                              TextSpan(
                                text:
                                    "TruMarkZ's Privacy Policy and Terms & Conditions.",
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  decorationThickness: 1.1,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

class _OnboardingTitleLine extends StatelessWidget {
  const _OnboardingTitleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: AppTypography.display2.copyWith(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w300,
          height: 1,
        ),
      ),
    );
  }
}

class _PrimaryOnboardingButton extends StatelessWidget {
  const _PrimaryOnboardingButton({
    required this.onPressed,
    required this.label,
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textTertiary,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
      ),
      child: Text(
        label,
        style: AppTypography.body2.copyWith(
          fontWeight: FontWeight.w600,
          color: onPressed == null
              ? AppColors.textTertiary
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _SignupChoiceCard extends StatelessWidget {
  const _SignupChoiceCard({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  static const Color _selectedColor = Color(0xFF1B3387);

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _selectedColor : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _selectedColor : AppColors.textSecondary,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAuthButton extends StatelessWidget {
  const _IconAuthButton({required this.onPressed, required this.icon});

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withAlpha(enabled ? 64 : 28),
                    Colors.white.withAlpha(enabled ? 22 : 12),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withAlpha(enabled ? 130 : 54),
                  width: 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha(28),
                    blurRadius: 10,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: IconThemeData(
                  color: enabled ? Colors.white : AppColors.textTertiary,
                ),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
