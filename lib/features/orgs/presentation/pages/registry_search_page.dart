import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum _EntityFilter { all, individuals, organisations }

class RegistrySearchPage extends StatefulWidget {
  const RegistrySearchPage({super.key});

  @override
  State<RegistrySearchPage> createState() => _RegistrySearchPageState();
}

class _RegistrySearchPageState extends State<RegistrySearchPage> {
  _EntityFilter _filter = _EntityFilter.all;
  String _selectedCategory = 'Consultants';

  @override
  Widget build(BuildContext context) {
    final List<_RecentVerified> recent = _RecentVerified.sample();
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
              delegate: SliverChildListDelegate.fixed(
                <Widget>[
                  _HeroHubCard(
                    filter: _filter,
                    selectedCategory: _selectedCategory,
                    onFilterChanged: (v) => setState(() => _filter = v),
                    onCategoryChanged: (v) =>
                        setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 24),
                  _RecentlyVerifiedSection(items: recent),
                  const SizedBox(height: 18),
                  _ResultsHeader(
                    onExport: () {},
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) {
                      final int cols = c.maxWidth >= 720 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: results.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: cols == 1 ? 1.65 : 1.75,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          return _RegistryResultCard(result: results[index]);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const _B2bCtaCard(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) {
                      final int cols = c.maxWidth >= 860 ? 3 : 1;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHubCard extends StatelessWidget {
  const _HeroHubCard({
    required this.filter,
    required this.selectedCategory,
    required this.onFilterChanged,
    required this.onCategoryChanged,
  });

  final _EntityFilter filter;
  final String selectedCategory;
  final ValueChanged<_EntityFilter> onFilterChanged;
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
          _EntitySegmented(
            value: filter,
            onChanged: onFilterChanged,
          ),
          const SizedBox(height: 16),
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

class _EntitySegmented extends StatelessWidget {
  const _EntitySegmented({required this.value, required this.onChanged});

  final _EntityFilter value;
  final ValueChanged<_EntityFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF3F3FE);
    const Color border = Color(0xFFC3C6D7);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _SegButton(
            label: 'All Entities',
            active: value == _EntityFilter.all,
            onTap: () => onChanged(_EntityFilter.all),
          ),
          _SegButton(
            label: 'Individuals',
            active: value == _EntityFilter.individuals,
            onTap: () => onChanged(_EntityFilter.individuals),
          ),
          _SegButton(
            label: 'Organisations',
            active: value == _EntityFilter.organisations,
            onTap: () => onChanged(_EntityFilter.organisations),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.brandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x332563EB),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Text(
          label,
          style: AppTypography.body2.copyWith(
            color: active ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
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
    return Stack(
      alignment: Alignment.centerLeft,
      children: <Widget>[
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC3C6D7)),
          ),
          padding: const EdgeInsets.only(left: 52, right: 16),
          child: TextField(
            onChanged: onChanged,
            style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.body1.copyWith(
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const Positioned(
          left: 18,
          child: Icon(Icons.search_rounded, color: AppColors.brandBlue, size: 26),
        ),
      ],
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

class _RecentVerified {
  const _RecentVerified({
    required this.title,
    required this.timeLabel,
    required this.badge,
    this.imageUrl,
    this.badgeBg,
    this.badgeFg,
  });

  final String title;
  final String timeLabel;
  final String badge;
  final String? imageUrl;
  final Color? badgeBg;
  final Color? badgeFg;

  static List<_RecentVerified> sample() => const <_RecentVerified>[
    _RecentVerified(
      title: 'NexGen Systems',
      timeLabel: '2 mins ago',
      badge: 'NS',
      badgeBg: Color(0xFFEFF6FF),
      badgeFg: AppColors.brandBlue,
    ),
    _RecentVerified(
      title: 'Sarah Mitchell',
      timeLabel: '15 mins ago',
      badge: 'SM',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDHV6Ah7MV4AlpMeISFp-qOJfp9ArKAwNUzZR29uoXWQSDV3x4S6E65gwZGqzi8HvOy4RWCLqj8y387x8TR2nU3LJSIjXmnA4-Cdsz1iKrLKWjZgTTUTh44kdYBFkmij80E0FFJD6e6WFV4m6NiM73DGfDUTSWNgbQaQEmonm4cOb9YOIva1enNu4fzgIqOR-FWOr8ibUkxU_-Q2u8j8bjWUN3I99WPVimGTvk-eaLZyj8tUk7SIWQQCbXCZK97XxtlPpCb9V2VN6M',
    ),
    _RecentVerified(
      title: 'Flow Logistics',
      timeLabel: '1 hour ago',
      badge: 'FL',
      badgeBg: Color(0xFFFEF3C7),
      badgeFg: Color(0xFFB45309),
    ),
  ];
}

class _RecentlyVerifiedSection extends StatelessWidget {
  const _RecentlyVerifiedSection({required this.items});

  final List<_RecentVerified> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: <Widget>[
              const Icon(Icons.verified_rounded, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              Text(
                'Recently Verified Entities',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemBuilder: (BuildContext context, int index) {
              return _RecentVerifiedCard(item: items[index]);
            },
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 12),
            itemCount: items.length,
          ),
        ),
      ],
    );
  }
}

class _RecentVerifiedCard extends StatelessWidget {
  const _RecentVerifiedCard({required this.item});

  final _RecentVerified item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4DC3C6D7)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _AvatarSquare(
            badge: item.badge,
            imageUrl: item.imageUrl,
            bg: item.badgeBg,
            fg: item.badgeFg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.timeLabel,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

class _AvatarSquare extends StatelessWidget {
  const _AvatarSquare({
    required this.badge,
    this.imageUrl,
    this.bg,
    this.fg,
  });

  final String badge;
  final String? imageUrl;
  final Color? bg;
  final Color? fg;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        badge,
        style: AppTypography.body2.copyWith(
          color: fg ?? AppColors.brandBlue,
          fontWeight: FontWeight.w900,
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
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onExport,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: <Widget>[
                Text(
                  'Export Result List',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.download_rounded,
                  size: 18,
                  color: AppColors.brandBlue,
                ),
              ],
            ),
          ),
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
      actionsLeft: <IconData>[Icons.contact_page_outlined, Icons.share_outlined],
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
      actionsLeft: <IconData>[Icons.description_outlined, Icons.history_rounded],
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
        onTap: () => context.go(AppRouter.publicVerificationResultPath),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            children: <Widget>[
              _ResultAvatar(result: result),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                result.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.heading2.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                result.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _VerifiedBadge(
                          icon: result.badgeIcon,
                          label: result.badgeLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        _StatusChip(label: result.statusLabel),
                        const SizedBox(width: 10),
                        Text(
                          result.metaLeft,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        for (final IconData icon in result.actionsLeft) ...<Widget>[
                          _IconActionButton(icon: icon, onTap: () {}),
                          const SizedBox(width: 10),
                        ],
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.go(AppRouter.publicVerificationResultPath),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  result.ctaLabel,
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
    if (result.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          result.imageUrl!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: result.avatarBg ?? const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        result.initials ?? 'TM',
        style: AppTypography.display2.copyWith(
          color: result.avatarFg ?? AppColors.brandBlue,
          fontWeight: FontWeight.w900,
          fontSize: 28,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blueTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.brandBlue),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: fg,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC3C6D7)),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
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

