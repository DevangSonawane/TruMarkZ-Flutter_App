# TruMarkZ — Complete Flutter Frontend Codex Documentation
**Version:** 2.0 (Full PRD Analysis) | **Platform:** Android (Flutter/Dart) | **Min SDK:** 21 | **Target SDK:** 34

---

## MASTER CODEX SYSTEM PROMPT

> Paste this as the **system prompt** in every Codex session. It encodes everything.

```
You are a senior Flutter engineer building TruMarkZ — a blockchain-backed Trust Infrastructure 
Platform for identity verification and digital credentialing on Dhiway CORD Network.

══════════════════════════════════════════════════════
DESIGN SYSTEM (EXACT — never deviate)
══════════════════════════════════════════════════════

COLORS:
  primaryBlue:       #2563EB   // CTAs, active nav, badges, hero gradient start
  deepNavy:          #1E40AF   // Hero gradient end, dark card overlay
  pageBackground:    #F0F4FF   // ALL screen backgrounds — soft blue-white, NEVER pure white/grey
  cardSurface:       #FFFFFF   // All card surfaces
  blueTint:          #EEF3FF   // Chip backgrounds, tag fills, active tints
  darkCredential:    #0F172A   // Blockchain proof cards, credential header bg
  textPrimary:       #0F172A   // All headings, names, primary data
  textSecondary:     #475569   // Body text, descriptions, labels
  textTertiary:      #94A3B8   // Metadata, dates, IDs, captions, placeholders
  successGreen:      #15803D   // VALID badge text
  warningAmber:      #B45309   // EXPIRED badge text
  dangerRed:         #B91C1C   // REVOKED badge text, revoke buttons
  border:            #CBD5E1   // Card borders, dividers, input default borders

BADGE BACKGROUNDS:
  VALID:      bg #DCFCE7, text #15803D
  EXPIRED:    bg #FEF9C3, text #A16207
  REVOKED:    bg #FEE2E2, text #B91C1C
  PENDING:    bg #EEF3FF, text #2563EB
  PROCESSING: bg #EEF3FF, text #2563EB
  AUTOMATIC:  bg #EEF3FF, text #2563EB
  MANUAL:     bg #F1F5F9, text #64748B
  ALERT:      bg #FEE2E2, text #B91C1C

TYPOGRAPHY:
  Page Title:    Sora Bold 24sp        // Screen headings
  Section Header:Sora SemiBold 18sp    // Section labels
  Card Title:    Sora SemiBold 15sp    // List card labels
  Body:          Inter Regular 14sp    // Descriptions, paragraphs
  Metadata:      Inter Regular 12sp    // Dates, IDs, helper text
  Button:        Sora SemiBold 16sp    // ALL CTA buttons
  Hashes/IDs:    Monospace 11sp        // Blockchain hashes, credential IDs (JetBrains Mono)
  Caps Label:    Sora Medium 11sp UPPERCASE letter-spacing 1.5

SPACING (4px grid):
  xs: 4dp | sm: 8dp | md: 12dp | base: 16dp | lg: 20dp | xl: 24dp | xxl: 32dp | xxxl: 48dp
  Screen horizontal padding: 20dp
  Between sections: 24dp
  Card internal padding: 20dp

COMPONENTS:
  Primary Button: 54dp height, 16dp radius, gradient #2563EB→#1E40AF, white Sora SemiBold 16sp
                  Shadow: elevation 0 4 16 rgba(37,99,235,0.35). Full-width.
  Ghost Button:   54dp height, 16dp radius, white bg, 1.5dp border #2563EB, blue text
  Danger Ghost:   54dp height, 16dp radius, white bg, 1.5dp border #EF4444, red text
  FAB:            56dp circle, blue filled, white icon, shadow 0 6 20 rgba(37,99,235,0.4)
  Standard Card:  white bg, 20dp radius, shadow 0 2 12 rgba(37,99,235,0.08), 20dp padding
  Credential Card:gradient #1E3A5F→#0F172A, 20dp radius, shadow 0 8 32 rgba(0,0,0,0.3)
  Hero Card:      full-width, gradient #2563EB→#1E40AF, 24dp radius
  Blockchain Card:#0F172A bg, 16dp radius, monospace text
  Input Field:    54dp height, 14dp radius, Inter 14sp. Default: 1dp #CBD5E1 border.
                  Focused: 2dp #2563EB + shadow 0 0 0 4dp rgba(37,99,235,0.1)
                  Label above: Sora 12sp UPPERCASE #94A3B8
  Bottom Sheet:   24dp top radius, gray drag handle, dimmed overlay

ARCHITECTURE RULES:
  - Clean Architecture: domain / data / presentation layers per feature
  - State: flutter_bloc (BLoC for complex, Cubit for simple state)
  - Navigation: go_router with named routes + deep links
  - DI: get_it + injectable
  - API: Dio + Retrofit typed clients + auth interceptor
  - Sensitive data: flutter_secure_storage ONLY (Android Keystore)
  - Never use SharedPreferences for tokens or credentials
  - All colors from AppColors — never hardcode hex in widgets
  - All text styles from AppTypography — never inline TextStyle
  - All spacing from AppSpacing constants — multiples of 4dp only
  - shimmer loading state on EVERY data-driven widget
  - flutter_animate for ALL entrance animations
  - ListView.builder / SliverList for ALL dynamic lists (never Column)
  - reactive_forms for ALL forms
  - Biometric gate before any screen showing private credentials

USER ROLES (determines nav + screens shown):
  Organisation → tabs: Dashboard | Verifications | Upload | Batches
  Individual   → tabs: Identity | Scan | Vault | Profile
  Super Admin  → tabs: Dashboard | Orgs | Batches | Settings
  Public/Guest → no account, QR scan only

SCREENS (28 total — SCR-001 to SCR-028):
  Auth: Splash, Onboarding(3), RoleSelection, SignIn, OrgRegistration, OTP, PendingApproval
  Org:  Dashboard, VerificationPlan, BulkUpload, SingleUpload, BatchTracking, 
        RecordDetail, CredentialTemplate, FieldMapping, GenerationSuccess
  Shared: CredentialWallet, CredentialDetail, QRScanner, PublicVerification
  Individual: SkillTree, AddSkillTreeItem
  Admin: AdminDashboard, OrgApproval, BatchMonitoring
  Global: Notifications, Settings, RegistrySearch

BLOCKCHAIN: Dhiway CORD Network. W3C verifiable credentials. SHA-256 hashing.
            No PII on-chain — only credential hash fingerprint.
PAYMENTS: Razorpay — ₹5-10 for full public report unlock
TARGET: Android-only Phase 1. Min SDK 21. 1000+ concurrent users.
```

---

## 1. Complete pubspec.yaml

```yaml
name: trumarkz
description: Blockchain-backed Trust Infrastructure Platform
publish_to: none
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # ── State Management ─────────────────────────────────
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  
  # ── Navigation ────────────────────────────────────────
  go_router: ^14.2.7

  # ── Network ──────────────────────────────────────────
  dio: ^5.6.0
  retrofit: ^4.1.0
  json_annotation: ^4.9.0
  pretty_dio_logger: ^1.4.0

  # ── Storage ───────────────────────────────────────────
  flutter_secure_storage: ^9.2.2   # tokens, keys — NEVER SharedPreferences
  hive_flutter: ^1.1.0             # non-sensitive cache

  # ── DI ────────────────────────────────────────────────
  get_it: ^7.7.0
  injectable: ^2.4.2

  # ── QR & Camera ───────────────────────────────────────
  mobile_scanner: ^5.2.3           # QR scanning
  qr_flutter: ^4.1.0               # QR code generation
  camera: ^0.11.0                  # direct camera access
  image_picker: ^1.1.2             # gallery + camera picker
  file_picker: ^8.1.2              # Excel + ZIP selection

  # ── Payments ─────────────────────────────────────────
  razorpay_flutter: ^1.3.7

  # ── Firebase ──────────────────────────────────────────
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  firebase_analytics: ^11.3.3
  firebase_crashlytics: ^4.1.3

  # ── Auth ─────────────────────────────────────────────
  google_sign_in: ^6.2.1
  local_auth: ^2.3.0               # biometric gate

  # ── PDF ──────────────────────────────────────────────
  pdf: ^3.11.1                     # credential PDF generation
  printing: ^5.13.1

  # ── Sharing ───────────────────────────────────────────
  share_plus: ^9.0.0               # WhatsApp, email, link sharing

  # ── UI & Animations ───────────────────────────────────
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  lottie: ^3.1.2
  flutter_svg: ^2.0.10+1
  cached_network_image: ^3.3.1
  google_fonts: ^6.2.1

  # ── Forms ─────────────────────────────────────────────
  reactive_forms: ^17.0.0

  # ── Permissions ───────────────────────────────────────
  permission_handler: ^11.3.1

  # ── Serialization ────────────────────────────────────
  freezed_annotation: ^2.4.4

  # ── Utils ─────────────────────────────────────────────
  intl: ^0.19.0
  connectivity_plus: ^6.0.5
  package_info_plus: ^8.1.0
  url_launcher: ^6.3.0
  flutter_jailbreak_detection: ^1.10.0  # security

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.11
  retrofit_generator: ^8.1.0
  injectable_generator: ^2.4.2
  json_serializable: ^6.8.0
  freezed: ^2.5.7
  flutter_lints: ^4.0.0
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  assets:
    - assets/icons/           # SVG icons including TruMarkZ shield
    - assets/animations/      # Lottie JSON files
    - assets/images/          # Static images
    - assets/fonts/           # Bundled Sora + Inter + JetBrains Mono
  fonts:
    - family: Sora
      fonts:
        - asset: assets/fonts/Sora-Regular.ttf
        - asset: assets/fonts/Sora-Medium.ttf
          weight: 500
        - asset: assets/fonts/Sora-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Sora-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
```

---

## 2. Core Theme Files

### `lib/core/theme/app_colors.dart`
```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Palette ─────────────────────────────────────
  static const Color primaryBlue    = Color(0xFF2563EB);
  static const Color deepNavy       = Color(0xFF1E40AF);
  static const Color pageBackground = Color(0xFFF0F4FF);
  static const Color cardSurface    = Color(0xFFFFFFFF);
  static const Color blueTint       = Color(0xFFEEF3FF);
  static const Color darkCredential = Color(0xFF0F172A);

  // ── Text ──────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary  = Color(0xFF94A3B8);
  static const Color textOnDark    = Color(0xFFF8FAFC);

  // ── Semantic ──────────────────────────────────────────
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color danger  = Color(0xFFB91C1C);
  static const Color border  = Color(0xFFCBD5E1);

  // ── Badge Fills ───────────────────────────────────────
  static const Color badgeValidBg    = Color(0xFFDCFCE7);
  static const Color badgeExpiredBg  = Color(0xFFFEF9C3);
  static const Color badgeRevokedBg  = Color(0xFFFEE2E2);
  static const Color badgePendingBg  = Color(0xFFEEF3FF);
  static const Color badgeManualBg   = Color(0xFFF1F5F9);
  static const Color badgeAlertBg    = Color(0xFFFEE2E2);

  // ── Alert Cards ───────────────────────────────────────
  static const Color alertDangerBg   = Color(0xFFFEF2F2);
  static const Color alertDangerBdr  = Color(0xFFFECACA);
  static const Color alertWarningBg  = Color(0xFFFFFBEB);
  static const Color alertWarningBdr = Color(0xFFFDE68A);

  // ── Gradients ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryBlue, deepNavy],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, deepNavy],
  );

  static const LinearGradient credentialGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
  );
}
```

### `lib/core/theme/app_typography.dart`
```dart
import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String _sora          = 'Sora';
  static const String _inter         = 'Inter';
  static const String _jetBrains     = 'JetBrainsMono';

  // ── Sora (Headings/Labels/Buttons) ────────────────────
  static const TextStyle pageTitle = TextStyle(
    fontFamily: _sora, fontSize: 24, fontWeight: FontWeight.w700,
    color: Color(0xFF0F172A), letterSpacing: -0.02,
  );
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: _sora, fontSize: 18, fontWeight: FontWeight.w600,
    color: Color(0xFF0F172A),
  );
  static const TextStyle cardTitle = TextStyle(
    fontFamily: _sora, fontSize: 15, fontWeight: FontWeight.w600,
    color: Color(0xFF0F172A),
  );
  static const TextStyle button = TextStyle(
    fontFamily: _sora, fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const TextStyle capsLabel = TextStyle(
    fontFamily: _sora, fontSize: 11, fontWeight: FontWeight.w500,
    color: Color(0xFF94A3B8), letterSpacing: 1.5,
  );
  static const TextStyle labelMd = TextStyle(
    fontFamily: _sora, fontSize: 14, fontWeight: FontWeight.w600,
    color: Color(0xFF0F172A),
  );

  // ── Inter (Body/Metadata) ─────────────────────────────
  static const TextStyle body = TextStyle(
    fontFamily: _inter, fontSize: 14, fontWeight: FontWeight.w400,
    color: Color(0xFF475569),
  );
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _inter, fontSize: 16, fontWeight: FontWeight.w400,
    color: Color(0xFF475569),
  );
  static const TextStyle metadata = TextStyle(
    fontFamily: _inter, fontSize: 12, fontWeight: FontWeight.w400,
    color: Color(0xFF94A3B8),
  );

  // ── Monospace (Blockchain hashes) ─────────────────────
  static const TextStyle hash = TextStyle(
    fontFamily: _jetBrains, fontSize: 11, fontWeight: FontWeight.w400,
    color: Color(0xFF94A3B8), letterSpacing: 0.5,
  );
}
```

### `lib/core/theme/app_spacing.dart`
```dart
class AppSpacing {
  AppSpacing._();
  static const double xs    = 4;
  static const double sm    = 8;
  static const double md    = 12;
  static const double base  = 16;
  static const double lg    = 20;
  static const double xl    = 24;
  static const double xxl   = 32;
  static const double xxxl  = 48;
  static const double screenH = 20;  // horizontal screen padding
  static const double cardP   = 20;  // internal card padding
  static const double sectionGap = 24;
}
```

### `lib/core/theme/app_theme.dart`
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.pageBackground,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: AppColors.deepNavy,
      surface: AppColors.cardSurface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.pageBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.pageTitle,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: AppTypography.button,
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.danger),
      ),
      labelStyle: AppTypography.capsLabel,
      hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.blueTint,
      labelStyle: AppTypography.body.copyWith(color: AppColors.primaryBlue),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
```

---

## 3. Project Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── app_theme.dart
│   ├── router/
│   │   └── app_router.dart           # go_router, all 28 routes
│   ├── di/
│   │   ├── injection.dart
│   │   └── injection.config.dart     # generated
│   ├── network/
│   │   ├── api_client.dart           # Dio setup
│   │   ├── auth_interceptor.dart
│   │   └── certificate_pinning.dart
│   ├── constants/
│   │   └── app_constants.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   └── extensions.dart
│   └── widgets/                      # Design system components
│       ├── tmz_button.dart
│       ├── tmz_card.dart
│       ├── tmz_input.dart
│       ├── tmz_badge.dart
│       ├── tmz_shimmer.dart
│       ├── tmz_bottom_nav.dart
│       └── tmz_logo.dart
├── features/
│   ├── auth/
│   │   ├── data/ domain/ presentation/
│   │   └── presentation/pages/
│   │       ├── splash_page.dart       # SCR-001
│   │       ├── onboarding_page.dart   # SCR-002
│   │       ├── sign_in_page.dart      # SCR-003
│   │       ├── role_selection_page.dart # SCR-004
│   │       ├── org_registration_page.dart # SCR-005
│   │       ├── otp_page.dart          # SCR-006
│   │       └── pending_approval_page.dart # SCR-007
│   ├── org_dashboard/
│   │   └── presentation/pages/
│   │       ├── org_dashboard_page.dart   # SCR-008
│   │       ├── verification_plan_page.dart # SCR-009
│   │       ├── bulk_upload_page.dart     # SCR-010
│   │       ├── single_upload_page.dart   # SCR-011
│   │       └── batch_tracking_page.dart  # SCR-012
│   ├── credentials/
│   │   └── presentation/pages/
│   │       ├── record_detail_page.dart     # SCR-013
│   │       ├── credential_template_page.dart # SCR-014
│   │       ├── field_mapping_page.dart     # SCR-015
│   │       ├── generation_success_page.dart # SCR-016
│   │       ├── credential_wallet_page.dart  # SCR-017
│   │       └── credential_detail_page.dart  # SCR-018
│   ├── scanner/
│   │   └── presentation/pages/
│   │       ├── qr_scanner_page.dart         # SCR-019
│   │       └── public_verification_page.dart # SCR-020
│   ├── skill_tree/
│   │   └── presentation/pages/
│   │       ├── skill_tree_page.dart         # SCR-021
│   │       └── add_skill_item_page.dart     # SCR-022
│   ├── admin/
│   │   └── presentation/pages/
│   │       ├── admin_dashboard_page.dart    # SCR-023
│   │       ├── org_approval_page.dart       # SCR-024
│   │       └── batch_monitoring_page.dart   # SCR-025
│   └── global/
│       └── presentation/pages/
│           ├── notifications_page.dart      # SCR-026
│           ├── settings_page.dart           # SCR-027
│           └── registry_search_page.dart    # SCR-028
└── main.dart
```

---

## 4. Shared Widget Codex Prompts

---

### PROMPT W-01 — StatusBadge

```
Create a Flutter StatelessWidget called StatusBadge in 
lib/core/widgets/tmz_badge.dart.

An enum BadgeStatus { valid, expired, revoked, pending, processing, automatic, manual, alert }

Display a pill-shaped status badge.

Spec per status:
  valid:      bg #DCFCE7, text #15803D, label "VALID"
  expired:    bg #FEF9C3, text #A16207, label "EXPIRED"
  revoked:    bg #FEE2E2, text #B91C1C, label "REVOKED"
  pending:    bg #EEF3FF, text #2563EB, label "PENDING"
  processing: bg #EEF3FF, text #2563EB, label "PROCESSING" + small spinner
  automatic:  bg #EEF3FF, text #2563EB, label "AUTOMATIC"
  manual:     bg #F1F5F9, text #64748B, label "MANUAL"
  alert:      bg #FEE2E2, text #B91C1C, label "ALERT"

Props:
  status: BadgeStatus (required)
  compact: bool (default false — compact hides text, shows dot only)

Text: Inter SemiBold 11sp uppercase letter-spacing 0.5
Padding: horizontal 10dp, vertical 4dp
Radius: full pill (borderRadius 999)
Add optional shield/check icon before text (2dp gap) using badgeIcon() helper.
Import AppColors and AppTypography.
```

---

### PROMPT W-02 — PrimaryButton (Gradient)

```
Create a Flutter StatelessWidget called TmzButton in 
lib/core/widgets/tmz_button.dart.

enum TmzButtonVariant { primary, ghost, dangerGhost, text }

Props:
  label: String
  onPressed: VoidCallback?
  isLoading: bool (default false)
  variant: TmzButtonVariant (default primary)
  icon: IconData? (leading icon)
  fullWidth: bool (default true)

Specs:
  All variants: height 54dp, radius 16dp, Sora SemiBold 16sp

  primary: 
    - Gradient decoration: LinearGradient #2563EB → #1E40AF (left to right)
    - Use Container with BoxDecoration (not ElevatedButton) to apply gradient
    - Shadow: BoxShadow(color: Color(0x592563EB), blurRadius: 16, offset: Offset(0,4))
    - Text + icon: white
    - isLoading: show SizedBox(16,16) CircularProgressIndicator.adaptive(strokeWidth:2, color: white)

  ghost: white bg, 1.5dp solid border #2563EB, text color #2563EB
  dangerGhost: white bg, 1.5dp solid border #B91C1C, text #B91C1C
  text: no bg/border, text #2563EB, height auto

  disabled (onPressed == null): Opacity 0.45
  
  Use flutter_animate: add .animate().scale(begin: Sp(0.97), end: Sp(1.0), 
  duration: 100ms) on press via GestureDetector + StatefulWidget.

Import AppColors, AppTypography, AppSpacing.
```

---

### PROMPT W-03 — Input Field with Label

```
Create a Flutter StatelessWidget called TmzInput in 
lib/core/widgets/tmz_input.dart.

Wraps ReactiveTextField from reactive_forms with TruMarkZ styling.

Props:
  formControlName: String
  label: String (shown ABOVE field in UPPERCASE Sora 11sp #94A3B8, letter-spacing 1.5)
  hint: String?
  obscureText: bool (default false — adds eye toggle icon if true)
  keyboardType: TextInputType (default text)
  prefix: Widget? (leading icon inside field)
  suffix: Widget? (trailing widget — overrides eye toggle)
  maxLines: int (default 1)
  readOnly: bool (default false)

Specs:
  Height: 54dp (enforced via contentPadding)
  Radius: 14dp
  Default border: 1dp #CBD5E1
  Focused: 2dp #2563EB + shadow 0 0 0 4dp rgba(37,99,235,0.1)
  Error: 1dp #EF4444 border + red helper text below
  Fill: #F8FAFF
  Font: Inter 14sp #0F172A

Add 8dp gap between label and field.
Show ReactiveTextField's validationMessages for:
  'required': 'This field is required'
  'email': 'Enter a valid email'
  'minLength': 'Too short'
```

---

### PROMPT W-04 — Shimmer Skeleton Cards

```
Create a Flutter file lib/core/widgets/tmz_shimmer.dart.

Three shimmer skeleton widgets using the shimmer package:

1. CardShimmer — full-width white card (20dp radius, 20dp padding):
   Rows: 2 shimmer lines (80% width, 12dp height) + 1 short line (40%)
   Spacing: 12dp between rows
   
2. ListTileShimmer — horizontal layout:
   Left: 48dp circle shimmer
   Right: 2 shimmer lines stacked
   
3. CredentialCardShimmer — matches IdentityCard dimensions:
   140dp height, full-width, gradient shimmer

All shimmer: baseColor #F0F4FF, highlightColor #FFFFFF
Import shimmer package.
Use as: CardShimmer() inside ListView.builder for loading states.
```

---

## 5. Screen Codex Prompts (All 28 Screens)

---

### PROMPT SCR-001 — Splash Screen

```
Create Flutter page SplashPage in 
lib/features/auth/presentation/pages/splash_page.dart.

Background: #2563EB solid blue — full screen.

Layout (centered column):
  - TruMarkZ shield SVG logo mark (white version), 100dp
  - 'TruMarkZ' text: Sora Bold 32sp white, 12dp below logo
  - 'VERIFY • TRUST • TRANSFORM': Inter 11sp rgba(255,255,255,0.65), letter-spacing 2.0
  - Thin white linear progress indicator (2dp height, 40% screen width) at bottom — 
    animates from 0.0 to 1.0 over 2 seconds

Logic:
  - On initState, start a 2-second timer
  - After 2 seconds:
    - If first launch (check flutter_secure_storage key 'has_seen_onboarding'): 
      go to /onboarding
    - If returning user with valid token: go to /dashboard
    - Else: go to /sign-in
  - Use flutter_animate for logo entrance: fadeIn(300ms) + scale(from 0.8, 300ms)

Import AppColors, go_router.
```

---

### PROMPT SCR-002 — Onboarding (3 Slides)

```
Create Flutter StatefulWidget OnboardingPage in 
lib/features/auth/presentation/pages/onboarding_page.dart.

3 swipeable slides using PageView. Background #F0F4FF.

Slide data:
  Slide 1: 
    illustration: Lottie animation 'assets/animations/shield_verify.json', 280dp
    headline: 'Verify Anyone. Anything.'
    subtext: 'Blockchain-backed credentials for workers, products, and services.'
  Slide 2:
    illustration: Lottie 'assets/animations/blockchain_nodes.json', 280dp
    headline: 'Tamper-Proof Credentials.'
    subtext: 'SHA-256 hashed on Dhiway CORD — mathematically guaranteed authentic.'
  Slide 3:
    illustration: Lottie 'assets/animations/qr_scan_success.json', 280dp
    headline: 'Trust in 2 Seconds.'
    subtext: 'Anyone can scan a TruMarkZ QR. No app download needed.'

Bottom section (white card, full-width, 32dp top radius):
  - Headline: Sora Bold 26sp #0F172A
  - Subtext: Inter 15sp #475569, top margin 12dp
  - Pagination dots: active = blue filled pill 8x8dp, inactive = grey circle 6x6dp
    horizontal: 8dp gap between dots
  - 'Get Started' primary blue button (full-width, 54dp)
  - 'Already have an account? Sign In' — centered, 'Sign In' in blue, 16dp below button
  
Page transition: auto-advance not required. Manual swipe or button advances.
Track currentPage state. On slide 3: 'Get Started' navigates to /role-selection.
On skip ('Sign In' tapped on any slide): navigate to /sign-in.
Save 'has_seen_onboarding' = true to flutter_secure_storage on GetStarted tap.
Use flutter_animate for bottom card slideY entrance on each page change.
```

---

### PROMPT SCR-003 — Sign In

```
Create Flutter page SignInPage in 
lib/features/auth/presentation/pages/sign_in_page.dart.

Background: #F0F4FF. 

Layout:
  Top section (36dp top padding):
    - TruMarkZ shield SVG + wordmark, centered, 48dp logo
    - 'VERIFY • TRUST • TRANSFORM' caps label, centered, 8dp below
  
  White card (radius 24dp, shadow 0 4 24 rgba(37,99,235,0.10), 20dp margin horizontal):
    - 'Welcome Back' Sora Bold 22sp #0F172A
    - 'Sign in to your TruMarkZ account' Inter 14sp #475569, 4dp below
    - 24dp gap
    - TmzInput: formControlName='email', label='EMAIL ADDRESS', 
      keyboardType=email, prefix=Icon(Icons.mail_outline)
    - 16dp gap
    - TmzInput: formControlName='password', label='PASSWORD', 
      obscureText=true, prefix=Icon(Icons.lock_outline)
    - 'Forgot Password?' right-aligned blue text link, 8dp below password field
    - 20dp gap
    - TmzButton primary 'Sign In'
    - 16dp gap
    - Row with dividers: '————  or continue with  ————'
    - TmzButton ghost 'Continue with Google' + Google logo SVG left
    - 24dp gap
    - 'Don't have an account?  Register' centered — 'Register' in #2563EB

  Bottom security footer:
    - Shield icon (Icons.verified_user_outlined) + 'Secured by TruMarkZ Identity Protocol'
    - Inter 12sp #94A3B8, centered, 24dp below card

Form: ReactiveForm with FormGroup:
  email: FormControl(validators: [Validators.required, Validators.email])
  password: FormControl(validators: [Validators.required, Validators.minLength(8)])

BLoC: AuthBloc. On submit: add SignInEvent. On AuthSuccess: go to role-based dashboard.
On AuthFailure: show SnackBar with error message.
Use flutter_animate for card: fadeIn + slideY(from 0.04), 400ms, delay 200ms.
```

---

### PROMPT SCR-004 — Role Selection

```
Create Flutter page RoleSelectionPage in 
lib/features/auth/presentation/pages/role_selection_page.dart.

Background: #F0F4FF.

Title: 'How will you use TruMarkZ?' Sora Bold 24sp, 32dp top padding, 20dp horizontal.
Subtitle: 'You can change this later in settings.' Inter 14sp #475569.

Two role cards (TmzCard, full-width, 20dp radius):
  UNSELECTED state: white bg, 0.5dp #CBD5E1 border
  SELECTED state: #F8FBFF tint bg, 2dp #2563EB border, 4dp blue left accent strip

  Organisation card:
    Left: 48dp circle bg #EEF3FF with Icons.business_outlined blue icon
    Right column: 'Organisation' Sora SemiBold 16sp | 
                  'Verify workers, products & services in bulk' Inter 13sp #475569
    Far right: Radio circle (filled blue if selected)
  
  Individual card:
    Left: 48dp circle bg #EEF3FF with Icons.person_outlined blue icon
    Right column: 'Individual' Sora SemiBold 16sp |
                  'Build your verified skill tree resume' Inter 13sp #475569
    Far right: Radio circle

24dp gap after cards.
TmzButton primary 'Continue' — disabled until a role is selected.

On Continue: save selected role to flutter_secure_storage key 'user_role'.
Navigate to /org-registration (if Organisation) or /sign-in (if Individual who is new).
Use flutter_animate: cards staggered slideY entrance (delay 100ms each).
```

---

### PROMPT SCR-005 — Organisation Registration

```
Create Flutter page OrgRegistrationPage in 
lib/features/auth/presentation/pages/org_registration_page.dart.

Background: #F0F4FF.
AppBar: back arrow + 'Register Organisation' title.

Step progress indicator at top: 3 steps, 'Step 1 of 3' text.
Horizontal line with 3 dots — active=blue filled, done=blue filled with checkmark, future=grey.

White card (radius 20dp, 20dp padding):
  Title: 'Organisation Details' Sora SemiBold 18sp.
  Fields (all TmzInput, top label UPPERCASE):
    - Organisation Name
    - Address (maxLines: 3)
    - Industry (dropdown using DropdownButtonFormField styled to match TmzInput — 
      options: Transport, Healthcare, Education, Manufacturing, Security, 
      Agriculture, Products/Services, Others)
    - GST Number (keyboard: text, hint: '22AAAAA0000A1Z5')
    - Business Registration Number
    - Official Email (suffix: TextButton 'Send OTP' in #2563EB)
    - Phone Number (prefix: Container with '+91' Inter 14sp #475569, 
      vertical divider, phone icon)

After all fields: 
  Trust signal pill: row with Icons.lock_outline + 'Enterprise Grade Security'
  Pill bg: #EEF3FF, text #2563EB Inter 12sp, radius 999, padding h:12 v:6.

TmzButton primary 'Send OTP & Continue' — full-width, 24dp top margin.
'Already registered? Sign In' — centered text link below.

Form: ReactiveForm with validators on all fields.
On 'Send OTP & Continue': add OrgRegistrationSendOtpEvent → navigate to /otp.
```

---

### PROMPT SCR-006 — OTP Verification

```
Create Flutter StatefulWidget OtpPage in 
lib/features/auth/presentation/pages/otp_page.dart.

Background: #F0F4FF. Centered layout.

Top section (36dp top):
  - 72dp circle #EEF3FF bg with Icons.mail_outline in #2563EB (32dp)
  - 'Verify Your Email' Sora Bold 22sp, 16dp below
  - 'Enter the 6-digit code sent to {email}' Inter 14sp #475569

OTP Input Row (24dp top):
  6 individual TextFormField boxes, each:
    56x56dp, radius 14dp, border 1dp #CBD5E1
    Active/filled: border 2dp #2563EB
    Text: Sora Bold 22sp #0F172A, centered
    Background: white
  Spacing: 8dp between boxes
  Auto-focus next box when digit entered.
  Auto-submit when all 6 filled.

Resend row (16dp top):
  'Resend code in 00:48' Inter 14sp #94A3B8
  Countdown timer using Timer.periodic every 1 second.
  When timer hits 0: show 'Resend Code' blue link instead.

TmzButton primary 'Verify', 24dp top. Full-width.
'← Back to login' blue text link centered below.

Error state: all boxes get red 2dp border + shake animation using flutter_animate
  + 'Incorrect OTP. Please try again.' red Inter 13sp.

Shake animation: .animate(controller: _shakeController)
  .moveX(begin: -8, end: 8, duration: 50ms, curve: Curves.easeInOut) × 4 repeats
  
BLoC: AuthBloc. OtpVerifyEvent → AuthOtpSuccess → go to /pending-approval (org).
```

---

### PROMPT SCR-007 — Pending Approval

```
Create Flutter page PendingApprovalPage in 
lib/features/auth/presentation/pages/pending_approval_page.dart.

Background: #F0F4FF.

Top: 
  - Animated clock illustration: Lottie 'assets/animations/clock_pending.json', 
    180dp, loop: true
  - 'Application Submitted!' Sora Bold 24sp, 16dp below
  - 'Our team will review your organisation within 24 hours.' Inter 15sp #475569 centered

Submission summary white card (20dp radius, 20dp padding, 24dp top):
  Header row: shield icon + 'SUBMISSION SUMMARY' capsLabel #2563EB, bg: #EEF3FF 
              (rounded top only, -20dp padding offset to touch card edges)
  
  Inside card (16dp top pad):
    Row: org initials circle (44dp, blue bg) + org name Sora SemiBold 16sp + StatusBadge(pending)
    12dp gap
    Row: 'Entity Type' #94A3B8 / 'Private Limited' #0F172A
    8dp gap
    Row: 'Submitted On' / formatted date
    16dp divider
    'Uploaded Documents' Sora SemiBold 14sp
    2 file chips: 
      Each: Row with Icons.insert_drive_file_outlined (green) + filename Inter 13sp + 
            'View' blue text link
      bg: #F8FAFF, 8dp radius, padding h:12 v:8, border 1dp #CBD5E1

TmzButton ghost 'Notify Me When Approved' (full-width) — triggers push permission request.
16dp gap
'Log Out' danger text button centered.

Polling: in initState, start Timer.periodic(60 seconds) calling ApprovalStatusCubit.
On approval: context.go('/dashboard').
```

---

### PROMPT SCR-008 — Organisation Dashboard

```
Create Flutter page OrgDashboardPage in 
lib/features/org_dashboard/presentation/pages/org_dashboard_page.dart.

Use CustomScrollView with SliverList for performance.

AppBar (non-sliver, stays at top):
  Left: TruMarkZ shield SVG 28dp + 'TruMarkZ' Sora SemiBold 18sp #2563EB, horizontal gap 8dp
  Right: Stack(bell icon + blue dot badge with count) + CircleAvatar 36dp (initials)

HERO CARD (full-width, gradient #2563EB→#1E40AF, 24dp radius, 24dp padding):
  Left side (flex 1.6):
    'Good morning, [Name]' Sora Bold 22sp white
    'Here is your verification summary.' Inter 14sp rgba(255,255,255,0.75), 4dp below
    16dp gap
    Row of 2 white pill chips (opacity 90%):
      Chip 1: '[N] Verified' with green dot
      Chip 2: '[N] Pending' with amber dot
    Each chip: bg white, radius 999, padding h:14 v:8, Inter SemiBold 13sp #0F172A
  Right side (flex 1):
    Lottie 'assets/animations/credential_float.json', 130dp, loop true

STATS ROW (20dp top, horizontal): 3 equal white cards, no horizontal margin between:
  Each card: 
    capsLabel text (e.g., 'TOTAL VERIFIED'), 6dp gap, Sora Bold 28sp #2563EB number
    shadow 0 2 12 rgba(37,99,235,0.08)
  Stats: 'TOTAL VERIFIED' | 'ACTIVE BATCHES' | 'PENDING'

QUICK ACTIONS (24dp top): 'Quick Actions' sectionHeader + 'View All' blue right
  2x2 Grid (GridView.count, crossAxisCount:2, childAspectRatio:1.1, spacing:12dp):
    4 cards: 
      Card layout: 40dp circle #EEF3FF bg with icon, 12dp gap, Sora SemiBold 13sp label
      Actions: 'New Batch Upload' (upload_file icon) | 'View Credentials' (verified_user) | 
               'Skill Tree' (account_tree) | 'Registry Search' (search)

RECENT BATCHES (24dp top): 'Recent Batches' sectionHeader + 'View All' blue right
  ListView.builder (shrinkWrap:true, NeverScrollableScrollPhysics):
    BatchListTile widget per item:
      Left: 48dp circle colored bg + letter initial, tint based on status
      Center column: batch name Sora SemiBold 14sp + count + date Inter 12sp #94A3B8
      Right: StatusBadge widget

SHIMMER: when BLoC state is loading, show:
  ShimmerCard() for hero, 3×ShimmerStatCard, 4×ShimmerQuickAction, 3×ListTileShimmer

Entrance animation (flutter_animate):
  Hero: fadeIn 400ms
  Stats: fadeIn + slideY(0.05), staggered 100ms each  
  Sections: slideY(0.03) 300ms, delays 200ms apart
```

---

### PROMPT SCR-009 — Verification Plan Setup

```
Create Flutter page VerificationPlanPage in 
lib/features/org_dashboard/presentation/pages/verification_plan_page.dart.

3-step stepper at top: INDUSTRY → CHECKS → SUMMARY (active step highlighted blue).

STEP 1 — Industry Selection:
  Title: 'Select Your Industry' sectionHeader
  Wrap widget with industry chips (not scrollable):
    Options: Transport, Healthcare, Education, Manufacturing, Security, 
             Agriculture, Products/Services, Others
    Unselected chip: white bg, 1dp #CBD5E1 border, #475569 text, radius 20dp
    Selected chip: #2563EB bg, white text, radius 20dp
    Padding per chip: h:16 v:10

STEP 2 — Check Selection (shown after industry chosen):
  Title: 'Select Verification Checks' sectionHeader
  ListView of check rows (white card wrapping all rows):
    Each row: 
      Left: 36dp circle bg (tinted) + icon
      Center: check name Sora SemiBold 14sp + StatusBadge(automatic/manual) row + 
              timeline string Inter 12sp #94A3B8
      Right: Switch (Flutter Switch, active #2563EB)
    Divider between rows

STEP 3 — Summary:
  Cost breakdown white card with 4dp blue left border:
    capsLabel 'COST BREAKDOWN' blue
    Per-check rows: name + '₹[amount]' Sora SemiBold 14sp #0F172A
    Divider
    'TOTAL PER UNIT' capsLabel + '₹[total]' Sora Bold 20sp #2563EB
  
  Permission card (below): 
    'Access Control' Sora SemiBold 15sp
    Two selection pills in a Row:
      'Public Search' — selected: #EEF3FF bg + blue border + 'PUBLIC' blue text
      'Permission Required' — similar
  
  Legal disclaimer: Inter 12sp #94A3B8

Bottom: TmzButton primary 'Agree & Continue' 

BLoC: VerificationPlanBloc with 3 steps. 'Next' on each step advances state.
Go back with AppBar back arrow.
```

---

### PROMPT SCR-010 — Bulk Upload

```
Create Flutter page BulkUploadPage in 
lib/features/org_dashboard/presentation/pages/bulk_upload_page.dart.

AppBar: 'Upload Records' + step indicator (2 tabs: 'Bulk Upload' active | 'Single Record')

Upload Zone Widget (UploadZone) — reuse for both zones:
  Props: title, icon, acceptedFormats, onFilePicked
  Container: full-width, 120dp height, radius 16dp, dashed border 1.5dp #2563EB (using 
  CustomPainter for dashed border or package), bg white
  Center: icon (48dp, tinted blue) + title Sora SemiBold 14sp + format hint Inter 12sp #94A3B8
  After file selected: replace with FileChip (filename + size + green check + 'Change' link)

Two upload zones:
  Zone 1: 'Upload Excel Template' — Icons.table_chart_outlined green/excel color
           'Download Template' blue text link below zone
  Zone 2: 'Upload Photo ZIP' — Icons.folder_zip_outlined blue
           'Match filenames exactly with Excel photo column' note

After both files selected — show PREVIEW TABLE card:
  White card, title 'Preview (first 3 rows)' Sora SemiBold 14sp
  Table: Name | ID | Phone columns, first 3 rows from parsed Excel
  Inter 13sp in cells, #CBD5E1 borders
  
  Batch Name TmzInput below: label 'BATCH NAME', hint 'e.g. Driver Verification Q1'

TmzButton primary 'Create Batch' — disabled until both files + batch name provided.
On success: go to /batch-tracking/{batchId}.

BLoC: BulkUploadBloc. FilePickedEvent → parse preview → show table.
CreateBatchEvent → show LinearProgressIndicator → BatchCreatedState.
```

---

### PROMPT SCR-011 — Single Individual Upload

```
Create Flutter page SingleUploadPage in 
lib/features/org_dashboard/presentation/pages/single_upload_page.dart.

Tab switcher at top (from BulkUploadPage context, this is 'Single Record' active tab).

White card with all fields:
  - Full Name
  - Date of Birth (show date picker on tap, formatted DD/MM/YYYY)
  - Aadhaar Number (12 digits, masked after entry — show ****-****-8765)
  - PAN Number (auto-uppercase, formatted ABCDE1234F)
  - Address (maxLines: 3)
  - Photo upload zone (large 120x120dp square dashed zone):
      Icons.add_a_photo_outlined, 'Take Photo or Upload'
      On tap: show bottom sheet with 2 options (Camera / Gallery)
      After selection: show thumbnail preview 120x120 with 'Remove' overlay

Applied Checks info card (#EEF3FF bg, 4dp blue left border):
  'CHECKS APPLIED' capsLabel + List of check chips (blue tint filled)

Row of 2 buttons:
  TmzButton ghost 'Save as Draft' (flex 1)
  TmzButton primary 'Submit for Verification' (flex 2)

Aadhaar masking: show last 4 digits only after user moves focus away from field.
All fields use reactive_forms.
```

---

### PROMPT SCR-012 — Batch Tracking Detail

```
Create Flutter page BatchTrackingPage in 
lib/features/org_dashboard/presentation/pages/batch_tracking_page.dart.

AppBar: back arrow + batch name + StatusBadge

3 stat cards (Row, equal flex):
  'RECORDS' / count / Sora Bold 24sp blue
  'CREATED' / formatted date
  'SLA REMAINING' / time string (red if < 20% remaining)

Overall Progress white card (24dp top):
  'Verification Progress' Sora SemiBold 16sp + percentage right (Sora Bold 28sp #2563EB)
  16dp gap
  LinearProgressIndicator (track: #EEF3FF, value color: #2563EB, height 8dp, radius 4dp)
  '82 of 200 records complete' Inter 13sp #475569

CHECKS SECTION:
  'Verification Checks' sectionHeader
  ListView of CheckStatusTile:
    Left: 36dp circle icon (color tinted to status — green=verified, blue=processing, 
          grey=pending, red=alert)
    Center: check name Sora SemiBold 14sp + verifier name Inter 12sp #94A3B8
    Right column: 'XX/YY' Inter 13sp + StatusBadge
    Status icons: verified=checkmark, processing=circular spinner (AnimatedWidget), 
                  pending=schedule icon, alert=warning icon

SLA ALERT card (#FEF2F2 bg, 1dp #FECACA border, 16dp radius) — shown only when risk:
  Row: Icons.warning_amber_rounded red 20dp + text + 'Resolve' TmzButton ghost (shrink)

Bottom: TmzButton ghost 'Download Full Batch Report' + Icons.download.

BLoC: BatchTrackingBloc. Poll every 30s with BatchRefreshEvent.
```

---

### PROMPT SCR-013 — Individual Record Detail

```
Create Flutter page RecordDetailPage in 
lib/features/credentials/presentation/pages/record_detail_page.dart.

CREDENTIAL PREVIEW (dark card, gradient #1E3A5F→#0F172A, 20dp radius, 20dp pad, 
 full-width, 180dp height):
  Row: CircleAvatar 72dp (photo from network, cached_network_image) 
       + Column (name Sora Bold 22sp white, credential ID monospace 11sp #94A3B8)
  Bottom row: 'Active Credential' green pill + issued date Inter 12sp #94A3B8

3-TAB BAR below: 'Checks' | 'Report' | 'Blockchain'
  Tab indicator: bottom border 2dp #2563EB on active, Inter SemiBold 14sp

CHECKS TAB:
  ListView of CheckResultTile:
    Icon circle + check name Sora SemiBold 14sp + verifier name Inter 12sp + 
    date Inter 12sp + StatusBadge right

REPORT TAB:
  White card with PDF preview button (Icons.picture_as_pdf_outlined red + 
  'Download Full Report PDF' + file size) — on tap: launch PDF viewer or share.

BLOCKCHAIN TAB:
  Dark card (#0F172A bg, 16dp radius, 20dp pad):
    'TRANSACTION HASH' capsLabel white
    hash string: JetBrains Mono 11sp #94A3B8, selectable (SelectableText)
    'DHIWAY CORD NETWORK' row: blue dot 8dp + label white Inter 13sp
    'REPORT INTEGRITY' row: Icons.verified_outlined green + 'Not Modified' green
    'TIMESTAMP' row: UTC datetime

Bottom: TmzButton primary 'Download Verifiable Report' (gradient full-width).

Tab management: DefaultTabController(3). 
Use flutter_animate for tab content fadeIn 200ms on tab change.
```

---

### PROMPT SCR-014 — Credential Template Selector

```
Create Flutter page CredentialTemplatePage in 
lib/features/credentials/presentation/pages/credential_template_page.dart.

AppBar: 'Create Credential' + step indicator (Step 1 of 3).

6-template grid (GridView.count, crossAxisCount:2, childAspectRatio:0.9, spacing:12dp):

Template data:
  T1: Workforce/Driver ID — Icons.badge_outlined, Transport
  T2: Healthcare/Nurse — Icons.local_hospital_outlined, Healthcare  
  T3: Education/Student — Icons.school_outlined, Education
  T4: Product/Compliance — Icons.inventory_2_outlined, Products
  T5: Service/Professional — Icons.engineering_outlined, Professionals
  T6: Skill Tree Credential — Icons.account_tree_outlined, Individuals

Each TemplateCard widget:
  Unselected: white bg, 1dp #CBD5E1 border, 16dp radius, 16dp pad
  Selected: 4dp blue left border + #EEF3FF tint bg + 1dp blue border
  Content: 44dp circle #EEF3FF bg + icon #2563EB 
           + template name Sora SemiBold 14sp (8dp top) 
           + use-case Inter 12sp #94A3B8 (4dp top)

Bottom row (fixed, white bg, shadow):
  TmzButton ghost 'Preview Template' (flex 1) | TmzButton primary 'Continue' (flex 2)
  'Continue' disabled until template selected.
  On Continue: go to /field-mapping with templateId.

Use flutter_animate: grid items staggered slideY + fade, 60ms delay each.
```

---

### PROMPT SCR-015 — Credential Field Mapping

```
Create Flutter page FieldMappingPage in 
lib/features/credentials/presentation/pages/field_mapping_page.dart.

AppBar: 'Map Credential Fields' + step 2 of 3.

Info card (#EEF3FF bg, blue left border 4dp):
  Icons.info_outline blue + 'Choose up to 6 fields to appear on the credential card face.'

Two-panel layout (Column, not Row — mobile-first):

Panel 1: 'Available Fields' Sora SemiBold 15sp
  ListView of FieldRow:
    Checkbox (blue when checked) + field name Sora 14sp #0F172A + 
    field type chip (Inter 11sp #94A3B8)
  Max 6 selectable — when at 6, disable remaining unchecked rows (opacity 0.4)

Panel 2: 'On Credential Face' Sora SemiBold 15sp (with '${count}/6 selected' right)
  Wrap of blue chips (selected fields):
    Each chip: #EEF3FF bg + field name Inter 13sp #2563EB + Icons.close 14dp
    Remove on × tap

'Preview Credential' ghost button — opens BottomSheet showing live card preview using 
  selected fields with sample data from first record.

TmzButton primary 'Generate Credentials for [N] Records'
  Note below (Inter 13sp #2563EB): 'Runs in background — you can close the app.'

On tap: add GenerateCredentialsEvent → go to /generation-success.
```

---

### PROMPT SCR-016 — Generation Success

```
Create Flutter page GenerationSuccessPage in 
lib/features/credentials/presentation/pages/generation_success_page.dart.

Centered layout on #F0F4FF background.

Success animation:
  Lottie 'assets/animations/success_check.json', 120dp, loop:false, autoPlay.
  Wait for animation complete (onLoaded callback), then animate in text content.

'All Done!' Sora Bold 28sp #0F172A, 16dp below animation
'Successfully generated [N] credentials and recorded on Dhiway blockchain.' Inter 15sp #475569 centered.

3 stat mini-cards (Row, equal, 24dp top):
  'GENERATED / [N]' green
  'FAILED / [N]' red (0 if success)
  'BLOCKCHAIN / [N]%' blue

Action cards (24dp top, vertical stack):
  White card row: Icons.download + 'Download All as PDF' Sora SemiBold 15sp → PDF
  White card row: Icons.share + 'Share via WhatsApp' green icon
  White card row: Icons.account_balance_wallet_outlined blue + 'View Credential Wallet' 
                  — this is the primary CTA, make chevron visible

'View Batch Report' blue text link at bottom.

Cards entrance: flutter_animate staggered slideY + fadeIn.
```

---

### PROMPT SCR-017 — Credential Wallet

```
Create Flutter page CredentialWalletPage in 
lib/features/credentials/presentation/pages/credential_wallet_page.dart.

AppBar: 'My Credentials' pageTitle + Icons.filter_list right.

Filter chips (horizontal SingleChildScrollView, scrollDirection:horizontal):
  'All' | 'Workers' | 'Products' | 'Skills'
  Selected: #2563EB filled white text. Unselected: white border blue text.

ListView.builder of CredentialListCard:
  White card, 20dp radius, shadow 0 2 12 rgba(37,99,235,0.08):
  Left: 52dp circle (org initial letter, colored bg based on org hash) with 
        16dp TruMarkZ shield SVG badge overlay bottom-right
  Center: credential name Sora SemiBold 15sp + org name Inter 13sp #475569 + 
          issue date Inter 12sp #94A3B8
  Right: StatusBadge + Icons.qr_code_2_outlined #94A3B8 below

FAB (pill-shaped, bottom center, not bottom-right):
  Blue gradient, '+ Issue New Credential' Sora SemiBold 14sp white

Empty state (when list empty):
  Lottie 'assets/animations/empty_wallet.json', 160dp
  'No credentials yet' Sora Bold 20sp
  'Your verified credentials will appear here.' Inter 14sp #475569
  TmzButton primary 'Issue First Credential'

Shimmer: 4 × CardShimmer while loading.
On tap: go to /credential-detail/{credentialId}.
```

---

### PROMPT SCR-018 — Credential Detail & Share

```
Create Flutter page CredentialDetailPage in 
lib/features/credentials/presentation/pages/credential_detail_page.dart.

ISSUER HEADER (white card, rounded corners 20dp, 20dp pad):
  Left: CircleAvatar 48dp (org logo) + org name Sora SemiBold 15sp
  Right: TruMarkZ shield SVG 24dp
  Bottom separator: 4dp height Container gradient #2563EB→#1E40AF, full-width

CREDENTIAL BODY (white card, 20dp pad, continuation):
  CircleAvatar 72dp centered (credential holder photo)
  name Sora Bold 22sp #0F172A centered (8dp top)
  role/designation Inter 14sp #2563EB centered (4dp top)
  16dp gap
  2-column grid of detail rows:
    'ISSUE DATE' / formatted date Inter 13sp
    'EXPIRY DATE' / formatted date
    'CREDENTIAL ID' / TM-TRN-2026-XXXXX monospace 11sp (selectable)
    'VERIFIED BY' / org name
  16dp gap  
  'TruMarkZ Verified' pill badge: 
    #EEF3FF bg, radius 999, Icons.verified #2563EB 16dp + 'TruMarkZ Verified' Inter SemiBold 12sp #2563EB
  QR code 60x60dp using qr_flutter, right side of row

SHARE ROW (white card, 16dp pad):
  'Share Credential' Sora SemiBold 15sp
  3 icon buttons: 
    WhatsApp circle (green bg, white icon, 48dp)
    Copy Link (blue bg, Icons.link)
    Download PDF (red bg, Icons.picture_as_pdf)

BLOCKCHAIN RECORD (dark card #0F172A, 16dp radius, 20dp pad):
  'BLOCKCHAIN RECORD' capsLabel #94A3B8
  hash: JetBrains Mono 11sp #94A3B8 (first 16 chars + '...' + last 8)
  'IMMUTABLE' pill: green bg, white text
  UTC timestamp Inter 12sp #94A3B8

REVOKE (dangerGhost button) — only visible if currentUser.isOrgAdmin:
  'Revoke Credential' + confirmation dialog before action.
  Admin note: 'Only authorized administrators can revoke.' Inter 12sp #94A3B8
```

---

### PROMPT SCR-019 — QR Scanner

```
Create Flutter StatefulWidget QRScannerPage in 
lib/features/scanner/presentation/pages/qr_scanner_page.dart.

Split layout: top 60% camera, bottom 40% white sheet.

CAMERA SECTION:
  MobileScanner (MobileScannerController, facing: front option toggle)
  Dark overlay: ColorFilter or Stack with semi-transparent #0B0F19 (70% opacity) 
                covering all areas EXCEPT the scan window
  
  Top bar (on dark overlay):
    Left: Icons.flip_camera_android_outlined white 24dp (flip camera)
    Center: TruMarkZ wordmark Inter SemiBold 14sp white
    Right: Icons.flashlight_on_outlined / off toggle white 24dp
  
  SCAN FRAME (280x280dp centered):
    No fill. Only corner brackets drawn using CustomPainter:
      4 L-shaped brackets, each arm 24dp long, 3dp stroke, color #2563EB, round ends
    Animated scan line: Container 2dp height, full scan window width
      color: linear gradient transparent→#2563EB→transparent
      AnimationController loop 0→1 translating Y from top to bottom of scan window, 1.5s
  
  Caption below frame: 'Point at a TruMarkZ QR Code' Inter 13sp rgba(255,255,255,0.7)

BOTTOM SHEET (white, top radius 24dp, gray 40x4dp drag handle centered at top):
  Default state: 'Ready to Scan' Inter 14sp #94A3B8 centered + QR illustration 60dp
  
  On scan detected:
    HapticFeedback.mediumImpact()
    Sheet animates up (DraggableScrollableSheet or AnimatedSize):
    Show ScanResultCard:
      CircleAvatar 56dp + 'IDENTITY VERIFIED' capsLabel blue + 
      name Sora Bold 18sp + org name Inter 13sp #475569 + StatusBadge
    TmzButton primary 'View Full Report' → go to /public-verification/{id}

MobileScannerController.dispose in dispose().
```

---

### PROMPT SCR-020 — Public Verification Result

```
Create Flutter page PublicVerificationPage in 
lib/features/scanner/presentation/pages/public_verification_page.dart.

No login required. Accessible via deep link: /verify/{credentialId}.

STATUS BANNER (full-width card, 0dp horizontal margin, top):
  VERIFIED state:  bg #DCFCE7, left border 4dp #15803D
    Icons.verified green 32dp + 'VERIFIED' Sora Bold 22sp #15803D + 
    'Valid TruMarkZ Digital Identity' Inter 13sp #15803D
  EXPIRED state:   bg #FEF9C3, amber colors
  REVOKED state:   bg #FEE2E2, red colors + Icons.gpp_bad

PROFILE CARD (white, 20dp radius, centered content):
  CircleAvatar 80dp (photo) with 24dp blue shield badge bottom-right
  name Sora Bold 22sp #0F172A centered (12dp top)
  'TMZ-ID: TM-TRN-2026-00394' monospace 11sp #94A3B8 centered

CHECKS GRID (2x2, white card):
  4 check chips (full-width row each):
    Icons.check_circle green 18dp + check name Sora SemiBold 13sp
    Divider between rows

FULL REPORT CARD (2dp #2563EB border, 20dp radius, 20dp pad):
  'Unlock Full Report' Sora Bold 18sp
  '₹10 · One-time payment' Inter 15sp #0F172A (bold the ₹10)
  'Secure payment via Razorpay' Inter 12sp #94A3B8 + Razorpay logo 
  TmzButton primary 'Unlock Full Report' → trigger Razorpay.open()

BLOCKCHAIN PROOF (dark #0F172A card):
  hash monospace + 'CORD Mainnet' label + 'View on Explorer' link #2563EB

Footer: TruMarkZ logo + 'Powered by Dhiway CORD' #94A3B8

Razorpay: use razorpay_flutter. On PaymentSuccess → fetch and display full report.
```

---

### PROMPT SCR-021 — My Skill Tree

```
Create Flutter page SkillTreePage in 
lib/features/skill_tree/presentation/pages/skill_tree_page.dart.

AppBar: 'PROFESSIONAL IDENTITY' capsLabel blue (subtitle) above 'My Skill Tree' pageTitle.
Right: Icons.share_outlined + Icons.notifications_outlined.

4 expandable white cards (20dp radius, AnimatedSize or ExpansionTile custom):

EDUCATION section:
  Header: Icons.school_outlined in circle + 'Education' Sora SemiBold 16sp + count badge + chevron
  Items (SkillTreeItem):
    education icon circle (44dp, #EEF3FF) + degree name Sora SemiBold 14sp + institution 
    Inter 13sp #475569 + years Inter 12sp #94A3B8 + StatusBadge(verified/pending) right
    If verified: credential ID monospace 11sp link below in #2563EB → credential detail

WORK EXPERIENCE section:
  Same pattern, Icons.work_outline, work role + org + duration

EXPERTISE & SKILLS section:
  Wrap of skill pills:
    Each: #EEF3FF bg, radius 20dp, Icons.shield_outlined 14dp blue + skill name Inter 13sp blue

CERTIFICATIONS section:
  cert icon + name + issuer + date + StatusBadge

FAB: Icons.add, blue circle, bottom-right.
On FAB tap: showModalBottomSheet → AddSkillItemSheet (SCR-022).

Empty section state: blue outlined illustration + 'Add your first [section] item'.
Entrance animation: staggered section cards slideY + fadeIn.
```

---

### PROMPT SCR-022 — Add Skill Tree Item (Bottom Sheet)

```
Create Flutter StatefulWidget AddSkillItemSheet in 
lib/features/skill_tree/presentation/widgets/add_skill_item_sheet.dart.

showModalBottomSheet with:
  isScrollControlled: true
  backgroundColor: Colors.white
  shape: RoundedRectangleBorder(topLeft: Radius.circular(24), topRight: ...)

Content:
  Top: gray drag handle (40x4dp, centered, 12dp top)
  Row: 'Add Item' Sora SemiBold 20sp + Icons.close right (dismiss)
  
  4-tab switcher (custom — NOT DefaultTabController):
    'Education' | 'Experience' | 'Certification' | 'Skills'
    Active: #EEF3FF bg, #2563EB text. Inactive: transparent.
    Row of 4 equal tap areas, 40dp height, 8dp radius.

  EDUCATION TAB fields:
    Institution Name, Course/Degree, Year of Completion (date picker tap), 
    Upload Document (dashed zone):
      80dp height, dashed border, Icons.upload_file + 'Upload Certificate' Inter 13sp

  EXPERIENCE TAB: Company Name, Role/Position, Start Date, End Date, Description

  CERTIFICATION TAB: Certification Name, Issuing Organization, Issued Date, Upload

  SKILLS TAB: Skill Name (text input) + Proficiency (chips: Beginner/Intermediate/Expert)

  Info note pill: #EEF3FF bg, Icons.info_outline blue 16dp, 
    'Verification takes 24–48 hours.' Inter 13sp #475569, 8dp radius

  TmzButton primary 'Submit for Verification' full-width at bottom.
  'Cancel' text link below.

Resize when keyboard appears: use padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom).
```

---

### PROMPT SCR-023 — Super Admin Dashboard

```
Create Flutter page AdminDashboardPage in 
lib/features/admin/presentation/pages/admin_dashboard_page.dart.

AppBar: 'Admin Dashboard' + user avatar right.

SLA ALERT BANNER (conditional — show when alerts > 0):
  #FEF2F2 bg, 4dp red left border, 16dp radius, 16dp pad:
  Icons.warning_rounded red + '[N] SLA Breaches Detected' Sora SemiBold 15sp + 
  'View All' blue right

STATS GRID (2x2, GridView.count crossAxisCount:2, spacing:12dp):
  'PENDING ORGS' blue number + Icons.business outlined
  'ACTIVE BATCHES' blue + Icons.layers outlined
  'SLA ALERTS' red number + Icons.timer_off_outlined
  'TODAY'S REVENUE' green '₹[amount]' + Icons.currency_rupee_outlined

ORGS AWAITING APPROVAL section:
  'Pending Approval' sectionHeader + 'View All' link
  2 OrgApprovalCard widgets:
    Left: 48dp circle (initials, blue bg) + org name Sora SemiBold 14sp + 
          industry chip + GST Inter 12sp + 'Submitted X days ago' #94A3B8
    Bottom row: TmzButton ghost 'Reject' (danger, small) + TmzButton ghost 'Approve' (blue, small)

BATCH MONITORING TABLE:
  'Active Batches' sectionHeader
  White card with Table:
    Columns: Org | Batch | Records | SLA | % Done | Status
    Inter 13sp cells. Header: capsLabel.
    SLA-at-risk rows: #FFF5F5 row bg.
    On row tap: go to /admin/batch/{id}

Bottom nav: Dashboard | Orgs | Batches | Settings
```

---

### PROMPT SCR-024 — Org Approval Detail

```
Create Flutter page OrgApprovalPage in 
lib/features/admin/presentation/pages/org_approval_page.dart.

AppBar: 'Organisation Review' + StatusBadge(pending) chip in title row.

ORG HEADER card:
  64dp circle (blue bg, white initials) + org name Sora Bold 20sp (12dp left)
  entity type chip + 'Submitted [date]' Inter 12sp #94A3B8 (4dp top)
  'PENDING VERIFICATION' blue outlined pill centered (12dp top)

ORG DETAILS card:
  Title: 'Organisation Details' Sora SemiBold 16sp
  Row pairs: field label (#94A3B8 12sp) / value (#0F172A 14sp Sora SemiBold)
  Fields: GST Number | Business Registration ID | Business Email (+ ✓ OTP Verified badge)
          Phone Number | Industry | Address

VERIFICATION CHECKS card:
  CheckRow each: icon + check name + StatusBadge
  GST API → PASSED | Email OTP → PASSED | Manual Review → PENDING

UPLOADED DOCUMENTS card:
  File rows: Icons.description_outlined + filename + file size + 'View' blue link

ACTION BUTTONS (fixed bottom, white bg, shadow):
  TmzButton primary 'Approve Organisation' (full-width)
  12dp gap
  TmzButton dangerGhost 'Reject & Notify' (full-width)

On Approve: show confirmation dialog → add ApproveOrgEvent.
On Reject: show dialog with reason text field → add RejectOrgEvent.
```

---

### PROMPT SCR-025 — Batch Monitoring Detail (Admin)

```
Create Flutter page BatchMonitoringPage in 
lib/features/admin/presentation/pages/batch_monitoring_page.dart.

AppBar: batch name + 'Activate Project' TextButton right (blue, fires org notification).

3 stat cards (Row): org name (capsLabel) | record count | time remaining (red if <30% SLA).

SLA RISK card (#FEF2F2 bg, red border, 16dp radius) — conditional:
  risk description Inter 14sp #B91C1C
  TmzButton ghost 'Notify Verifier' (shrunk width)

VERIFICATION PROGRESS list (white card):
  CheckProgressRow: 
    icon circle + check name Sora SemiBold 14sp + verifier name Inter 12sp + 
    '[done]/[total]' Inter 13sp + StatusBadge
  Progress bar per row (thin 4dp height, bg #EEF3FF, fill blue, full width)

STAKEHOLDER card:
  'Assigned Verifier' Sora SemiBold 15sp
  verifier agency name Sora Bold 16sp
  Contact lead name, SLA efficiency %, verification type badge
  Row: TmzButton primary 'Send Reminder' + TmzButton ghost 'Call Support'

BLoC: AdminBatchBloc. ActivateProjectEvent sends org notification.
```

---

### PROMPT SCR-026 — Notifications

```
Create Flutter page NotificationsPage in 
lib/features/global/presentation/pages/notifications_page.dart.

AppBar: 'Notifications' + 'Mark all read' blue TextButton right.

Section headers: 'TODAY' and 'THIS WEEK' as capsLabel #94A3B8 sticky.

NotificationCard per item:
  Left: 4dp vertical bar (colored by type: green/red/blue)
       + 44dp circle icon (tinted bg matching bar color)
  Center: title Sora SemiBold 14sp #0F172A (2 lines max) +
          body Inter 13sp #475569 (2 lines, overflow ellipsis) +
          timestamp Inter 11sp #94A3B8
  Right: 8dp blue filled circle (unread indicator, hidden if read)

5 notification types and colors:
  Batch Verified:   green left bar, Icons.check_circle
  SLA Alert:        red, Icons.timer_off
  Credential Issued:blue, Icons.badge
  Payment Received: green, Icons.payments
  Org Approved:     blue, Icons.business

Tap notification: mark as read + navigate to relevant screen.
Swipe to dismiss: Dismissible widget with red bg + trash icon.

Empty state: illustration + 'No notifications yet.'
```

---

### PROMPT SCR-027 — Settings & Profile

```
Create Flutter page SettingsPage in 
lib/features/global/presentation/pages/settings_page.dart.

PROFILE HEADER card (white, 20dp radius, 20dp pad, centered):
  CircleAvatar 88dp with 3dp #2563EB ring border 
    (achieved with Container circle bg + nested CircleAvatar)
  name Sora Bold 20sp #0F172A (8dp top)
  'Organisation Admin' pill (#EEF3FF bg, blue text) centered (4dp top)
  email Inter 13sp #475569 (4dp top)
  'Edit Profile' blue TextButton (8dp top)

4 settings cards (white, 20dp radius, 16dp pad, divider between rows):

Card 1 — Account:
  SettingRow: Icons.edit + 'Edit Profile' → navigate
  SettingRow: Icons.lock_outline + 'Change Password'
  SettingRow: Icons.phonelink_lock + 'OTP Settings'

Card 2 — Notifications:
  SettingRowToggle: 'Push Notifications' + Switch (state from cubit)
  SettingRowToggle: 'Email Alerts'
  SettingRowToggle: 'SLA Alerts'
  SettingRowToggle: 'WhatsApp Notifications'

Card 3 — Privacy:
  SettingRowToggle: 'Public Credential Visibility'
  SettingRow: 'Permission Access Settings'
  SettingRow: 'Download My Data'

Card 4 — App:
  SettingRow: 'About TruMarkZ'
  SettingRow: 'Help & Support'
  SettingRow: 'Terms of Service'
  SettingRow: 'Privacy Policy'
  SettingRow: 'Version 1.0.0' (no chevron, just text right)

'Log Out' danger ghost button full-width (24dp top) → confirmation dialog.

SettingRow widget: Icons.chevron_right #94A3B8 on right.
SettingRowToggle: Switch on right (active: #2563EB).
```

---

### PROMPT SCR-028 — Registry Search

```
Create Flutter page RegistrySearchPage in 
lib/features/global/presentation/pages/registry_search_page.dart.

AppBar: 'Verify Anyone' pageTitle + TruMarkZ logo right (small).

Search input (full-width, white bg, 16dp radius, 54dp height):
  Icons.search #94A3B8 left prefix
  placeholder: 'Search by name, credential ID, or licence no.'
  Remove border when unfocused (outline:none feel — use OutlineInputBorder with transparent color)
  Focused: 2dp #2563EB border + shadow

Filter chips (horizontal scroll, 8dp gap, 16dp top):
  'Name' | 'Credential ID' | 'Date of Birth' | 'Licence No.'
  Selected: #2563EB bg, white text. Unselected: white bg, #CBD5E1 border.

RESULTS ListView.builder (after search):
  SearchResultCard:
    Left: 48dp circle (org initials, colored) + TruMarkZ badge overlay 12dp
    Center: credential name Sora SemiBold 14sp + type Inter 13sp #475569 + 
            'TMZ-ID: ...' monospace 11sp #94A3B8
    Right: StatusBadge

Info note (#EEF3FF bg, 8dp radius, 12dp pad):
  'Basic credential info is free. Full report costs ₹5–₹10 via Razorpay.'
  Inter 13sp #475569, Icons.info_outline blue left.

Empty state (before search): 
  magnifier illustration + 'Search by name, ID, or licence number' Inter 15sp #94A3B8

No results state:
  'No results found for "[query]".' + 'Try a different search term.'

On result tap: go to /public-verification/{id}.
BLoC: RegistrySearchBloc. DebounceTransformer(300ms) on SearchQueryChanged event.
```

---

## 6. go_router Setup

```dart
// lib/core/router/app_router.dart
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // role-based redirect logic
  },
  routes: [
    GoRoute(path: '/splash', builder: (c,s) => const SplashPage()),
    GoRoute(path: '/onboarding', builder: (c,s) => const OnboardingPage()),
    GoRoute(path: '/sign-in', builder: (c,s) => const SignInPage()),
    GoRoute(path: '/role-selection', builder: (c,s) => const RoleSelectionPage()),
    GoRoute(path: '/org-registration', builder: (c,s) => const OrgRegistrationPage()),
    GoRoute(path: '/otp', builder: (c,s) => const OtpPage()),
    GoRoute(path: '/pending-approval', builder: (c,s) => const PendingApprovalPage()),
    // Org routes
    ShellRoute(
      builder: (c, s, child) => OrgShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (c,s) => const OrgDashboardPage()),
        GoRoute(path: '/verification-plan', builder: (c,s) => const VerificationPlanPage()),
        GoRoute(path: '/bulk-upload', builder: (c,s) => const BulkUploadPage()),
        GoRoute(path: '/batch-tracking/:id', builder: (c,s) => BatchTrackingPage(batchId: s.pathParameters['id']!)),
        GoRoute(path: '/record-detail/:id', builder: (c,s) => RecordDetailPage(recordId: s.pathParameters['id']!)),
        GoRoute(path: '/credential-template', builder: (c,s) => const CredentialTemplatePage()),
        GoRoute(path: '/field-mapping', builder: (c,s) => const FieldMappingPage()),
        GoRoute(path: '/generation-success', builder: (c,s) => const GenerationSuccessPage()),
        GoRoute(path: '/credential-wallet', builder: (c,s) => const CredentialWalletPage()),
        GoRoute(path: '/credential-detail/:id', builder: (c,s) => CredentialDetailPage(id: s.pathParameters['id']!)),
      ],
    ),
    // Public (no auth)
    GoRoute(path: '/qr-scanner', builder: (c,s) => const QRScannerPage()),
    GoRoute(path: '/verify/:id', builder: (c,s) => PublicVerificationPage(credentialId: s.pathParameters['id']!)),
    GoRoute(path: '/registry-search', builder: (c,s) => const RegistrySearchPage()),
    // Individual
    GoRoute(path: '/skill-tree', builder: (c,s) => const SkillTreePage()),
    // Admin
    GoRoute(path: '/admin/dashboard', builder: (c,s) => const AdminDashboardPage()),
    GoRoute(path: '/admin/org-approval/:id', builder: (c,s) => OrgApprovalPage(orgId: s.pathParameters['id']!)),
    GoRoute(path: '/admin/batch/:id', builder: (c,s) => BatchMonitoringPage(batchId: s.pathParameters['id']!)),
    // Global
    GoRoute(path: '/notifications', builder: (c,s) => const NotificationsPage()),
    GoRoute(path: '/settings', builder: (c,s) => const SettingsPage()),
  ],
);
```

---

## 7. Animation Patterns Reference

```dart
// Standard entrance animations for all screens:

// 1. Page-level hero content:
Widget.animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0, duration: 400.ms)

// 2. Staggered list items (use index for delay):
Widget.animate(delay: (100 * index).ms)
  .fadeIn(duration: 300.ms)
  .slideY(begin: 0.05, end: 0, duration: 300.ms)

// 3. Bottom sheets:
Widget.animate().slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut)

// 4. Error shake:
Widget.animate(controller: shakeController)
  .shake(hz: 4, duration: 500.ms)

// 5. Loading pulse (for pending states):
Widget.animate(onPlay: (c) => c.repeat(reverse: true))
  .fade(begin: 0.5, end: 1.0, duration: 800.ms)

// 6. Success scale pop:
Widget.animate().scale(begin: Offset(0.7,0.7), end: Offset(1,1), 
  duration: 500.ms, curve: Curves.elasticOut)

// Keep all durations under 500ms. Never animate decorative elements.
// Animate structural content only (cards, buttons, key data).
```

---

## 8. Security Implementation Checklist

```dart
// These MUST be implemented before Play Store submission:

// 1. Certificate Pinning (in DioClient setup)
(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  final sha256 = 'YOUR_CERT_SHA256_HERE'; // from server cert
  client.badCertificateCallback = (cert, host, port) {
    final certSha = sha256.convert(cert.der).toString();
    return certSha == sha256;
  };
  return client;
};

// 2. Root detection on app start (main.dart)
final isJailbroken = await FlutterJailbreakDetection.jailbroken;
if (isJailbroken) { showRootedDeviceDialog(); return; }

// 3. Biometric gate (before credential detail):
final localAuth = LocalAuthentication();
final canAuth = await localAuth.canCheckBiometrics;
if (canAuth) {
  final authenticated = await localAuth.authenticate(
    localizedReason: 'Verify your identity to view credentials',
    options: const AuthenticationOptions(biometricOnly: true),
  );
  if (!authenticated) return;
}

// 4. Token storage (AuthRepository):
await _secureStorage.write(key: 'auth_token', value: token);
await _secureStorage.write(key: 'refresh_token', value: refreshToken);
// NEVER: SharedPreferences.setString('token', value)

// 5. Aadhaar/PAN masking after entry:
// Listen to FocusNode. On unfocus: replace value with masked version.
// Store full value only in FormControl; display masked.

// 6. No PII in logs:
// Disable pretty_dio_logger in release mode:
if (kDebugMode) dio.interceptors.add(PrettyDioLogger());

// 7. Screenshot prevention (sensitive screens only):
// Add to initState of CredentialDetailPage:
SystemChannels.platform.invokeMethod('SystemChrome.setPreferredOrientations');
// Use flutter_windowmanager package: WindowManager.addFlags(FLAG_SECURE)
```

---

## 9. Performance Rules

| Concern | Required Pattern |
|---|---|
| ALL dynamic lists | `ListView.builder` or `SliverList` — NEVER `Column` with map |
| Images | `CachedNetworkImage` with `memCacheWidth`/`memCacheHeight` set |
| State updates | `BlocSelector` to subscribe to only the field that changes |
| BLoC re-renders | Wrap leaf widgets in `BlocSelector`, not entire screens in `BlocBuilder` |
| Bulk batch UI | Show progress from server polling. Never block UI for >500ms |
| Font loading | Bundle Sora + Inter + JetBrains Mono — never use Google Fonts CDN in production |
| API caching | Dio cache interceptor + Hive for dashboards. TTL: 5 minutes |
| Image compression | Compress to 1MB before S3 upload using `image` package |
| Startup | Lazy-load camera, QR scanner, Razorpay via deferred imports |

---

*TruMarkZ — Verify · Trust · Transform | Flutter Frontend Documentation v2.0 | April 2026 | CONFIDENTIAL*