import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class RegistrySearchPage extends StatefulWidget {
  const RegistrySearchPage({super.key});

  @override
  State<RegistrySearchPage> createState() => _RegistrySearchPageState();
}

class _RegistrySearchPageState extends State<RegistrySearchPage> {
  String _selectedCategory = 'Consultants';

  @override
  Widget build(BuildContext context) {
    final List<_RegistryResult> results = _RegistryResult.sample();

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            titleSpacing: 20,
            title: Text(
              'TruMarkZ',
              style: AppTypography.heading1.copyWith(
                color: const Color(0xFF1D4ED8),
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: <Widget>[
              IconButton(
                onPressed: () => context.go(AppRouter.notificationsPath),
                icon: const Icon(Icons.notifications_none_rounded),
                color: AppColors.textSecondary,
              ),
              IconButton(
                onPressed: () => context.go(AppRouter.settingsPath),
                icon: const Icon(Icons.account_circle_outlined),
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFDBEAFE), width: 1),
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x142563EB),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(<Widget>[
                _HeroHubCard(
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (v) =>
                      setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 16),
                _ResultsHeader(onExport: () {}),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    final int cols = c.maxWidth >= 720 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: results.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 148,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        return _RegistryResultCard(result: results[index]);
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                const _B2bCtaCard(),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    final int cols = c.maxWidth >= 860 ? 3 : 1;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: cols == 1 ? 3.6 : 2.9,
                      children: const <Widget>[
                        _HubStatCard(
                          icon: Icons.apartment_rounded,
                          iconBg: Color(0x1A2563EB),
                          iconFg: AppColors.brandBlue,
                          label: 'Verified Companies',
                          value: '42,000+',
                        ),
                        _HubStatCard(
                          icon: Icons.badge_rounded,
                          iconBg: Color(0xFFE7F7EE),
                          iconFg: Color(0xFF16A34A),
                          label: 'Verified Experts',
                          value: '1.2M+',
                        ),
                        _HubStatCard(
                          icon: Icons.security_rounded,
                          iconBg: Color(0xFFFFF7ED),
                          iconFg: Color(0xFFD97706),
                          label: 'Compliance Uptime',
                          value: '99.9%',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 110),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHubCard extends StatelessWidget {
  const _HeroHubCard({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    const Color border = Color(0x80DBEAFE);
    const List<String> categories = <String>[
      'Consultants',
      'SaaS Vendors',
      'Fintech',
      'Legal Partners',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F2563EB),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'Organisation Registry Hub',
            textAlign: TextAlign.center,
            style: AppTypography.display1.copyWith(
              fontSize: 32,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Authoritative directory for verified professionals, vendors, and corporate partners.',
              textAlign: TextAlign.center,
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _BigSearchField(
            hintText: 'Search by name, GSTIN, Aadhaar, or company ID...',
            onChanged: (_) {},
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final String c in categories)
                _PillChip(
                  label: c,
                  selected: selectedCategory == c,
                  onTap: () => onCategoryChanged(c),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigSearchField extends StatelessWidget {
  const _BigSearchField({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC3C6D7)),
      ),
      alignment: Alignment.center,
      child: TextField(
        onChanged: onChanged,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.body1.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.brandBlue,
            size: 24,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          isDense: true,
          filled: false,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFEDEDF9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFC3C6D7)),
        ),
        child: Text(
          label,
          style: AppTypography.body2.copyWith(
            color: selected ? AppColors.brandBlue : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.onExport});

  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Search Results',
            style: AppTypography.display2.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Download',
          onPressed: onExport,
          icon: const Icon(Icons.download_rounded, color: AppColors.brandBlue),
        ),
      ],
    );
  }
}

enum _RegistryType { individual, organisation }

class _RegistryResult {
  const _RegistryResult({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.statusLabel,
    required this.metaLeft,
    required this.metaRight,
    this.imageUrl,
    this.initials,
    this.avatarBg,
    this.avatarFg,
    required this.actionsLeft,
    required this.ctaLabel,
    required this.ctaIcon,
  });

  final _RegistryType type;
  final String name;
  final String subtitle;
  final String badgeLabel;
  final IconData badgeIcon;
  final String statusLabel;
  final String metaLeft;
  final String metaRight;
  final String? imageUrl;
  final String? initials;
  final Color? avatarBg;
  final Color? avatarFg;
  final List<IconData> actionsLeft;
  final String ctaLabel;
  final IconData ctaIcon;

  static List<_RegistryResult> sample() => const <_RegistryResult>[
    _RegistryResult(
      type: _RegistryType.individual,
      name: 'Arjun Malhotra',
      subtitle: 'Lead Technical Consultant',
      badgeLabel: 'Verified Professional',
      badgeIcon: Icons.verified_user_rounded,
      statusLabel: 'ACTIVE',
      metaLeft: 'TM-ID: 9942-X-2024',
      metaRight: '',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDHV6Ah7MV4AlpMeISFp-qOJfp9ArKAwNUzZR29uoXWQSDV3x4S6E65gwZGqzi8HvOy4RWCLqj8y387x8TR2nU3LJSIjXmnA4-Cdsz1iKrLKWjZgTTUTh44kdYBFkmij80E0FFJD6e6WFV4m6NiM73DGfDUTSWNgbQaQEmonm4cOb9YOIva1enNu4fzgIqOR-FWOr8ibUkxU_-Q2u8j8bjWUN3I99WPVimGTvk-eaLZyj8tUk7SIWQQCbXCZK97XxtlPpCb9V2VN6M',
      actionsLeft: <IconData>[
        Icons.contact_page_outlined,
        Icons.share_outlined,
      ],
      ctaLabel: 'View Profile',
      ctaIcon: Icons.arrow_outward_rounded,
    ),
    _RegistryResult(
      type: _RegistryType.organisation,
      name: 'Zetachain Kinetics',
      subtitle: 'Fintech & Infrastructure',
      badgeLabel: 'Verified Entity',
      badgeIcon: Icons.domain_verification_rounded,
      statusLabel: 'Mumbai, HQ',
      metaLeft: 'Auth. Vendor',
      metaRight: '',
      initials: 'ZK',
      avatarBg: Color(0xFFACBFFF),
      avatarFg: Color(0xFF394C84),
      actionsLeft: <IconData>[
        Icons.description_outlined,
        Icons.history_rounded,
      ],
      ctaLabel: 'Compliance Hub',
      ctaIcon: Icons.open_in_new_rounded,
    ),
    _RegistryResult(
      type: _RegistryType.organisation,
      name: 'Omni-Solutions Ltd',
      subtitle: 'Enterprise Logistics',
      badgeLabel: 'Verified Entity',
      badgeIcon: Icons.domain_verification_rounded,
      statusLabel: 'AUDIT PENDING',
      metaLeft: 'Tier 1 Supplier',
      metaRight: '',
      initials: 'OS',
      avatarBg: Color(0xFFBC4800),
      avatarFg: Colors.white,
      actionsLeft: <IconData>[Icons.assignment_outlined],
      ctaLabel: 'Registry Details',
      ctaIcon: Icons.chevron_right_rounded,
    ),
    _RegistryResult(
      type: _RegistryType.individual,
      name: 'Priya Sharma',
      subtitle: 'Compliance Auditor',
      badgeLabel: 'Verified Auditor',
      badgeIcon: Icons.verified_user_rounded,
      statusLabel: 'RENEWAL DUE',
      metaLeft: 'Verified Jan 2022',
      metaRight: '',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDXIWpba8MH8hZrRw_iWvtgyelK7UHeNS8cpnA0DE1uwz6wURLc3cEhT6HZrGhLaOLOzhnoLYYSD7auazWuhZ7-pv4Ala10TvBXlY8R9Dsotwzp5BjVpwGUlkGIlp7mtRmEsdPXipIbJwLLDv5zLZYlmRLR_KIyQFbsLxZf895CJEECRZcrx_ctnLNGkIAmUDT-nol284b_9ZxyIv8WNulKAfcVK9Tbqg4uEVN4cdKNY64tysyGupMUldVRTzi7RCQB7tSXw8X4koM',
      actionsLeft: <IconData>[Icons.qr_code_2_rounded],
      ctaLabel: 'Renew Now',
      ctaIcon: Icons.refresh_rounded,
    ),
  ];
}

class _RegistryResultCard extends StatelessWidget {
  const _RegistryResultCard({required this.result});

  final _RegistryResult result;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x142563EB),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ResultAvatar(result: result),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      result.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        _VerifiedBadge(
                          icon: result.badgeIcon,
                          label: result.badgeLabel,
                        ),
                        const SizedBox(width: 6),
                        _StatusChip(label: result.statusLabel),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            result.metaLeft,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          for (final IconData icon
                              in result.actionsLeft) ...<Widget>[
                            _IconActionButton(icon: icon, onTap: () {}),
                            const SizedBox(width: 10),
                          ],
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    result.ctaLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    result.ctaIcon,
                                    size: 16,
                                    color: AppColors.brandBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultAvatar extends StatelessWidget {
  const _ResultAvatar({required this.result});

  final _RegistryResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: result.avatarBg ?? const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        result.initials ?? 'TM',
        style: AppTypography.display2.copyWith(
          color: result.avatarFg ?? AppColors.brandBlue,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.blueTint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 12, color: AppColors.brandBlue),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 9,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool ok = label == 'ACTIVE' || label.contains('Mumbai');
    final Color fg = ok ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final Color bg = ok ? const Color(0xFFE7F7EE) : const Color(0xFFFFF7ED);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 92),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: fg,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC3C6D7)),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _B2bCtaCard extends StatelessWidget {
  const _B2bCtaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'ENTERPRISE SOLUTIONS',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Advanced Due Diligence',
            style: AppTypography.display2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Institutional-grade verification for supply chains, KYC, and corporate governance. Access bulk reports and API verification hooks.',
            style: AppTypography.body2.copyWith(
              color: Colors.white.withValues(alpha: 0.90),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.corporate_fare_rounded),
              label: const Text('Request B2B Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brandBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubStatCard extends StatelessWidget {
  const _HubStatCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4DC3C6D7)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
