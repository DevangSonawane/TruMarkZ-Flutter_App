import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class RegistrySearchPage extends StatefulWidget {
  const RegistrySearchPage({super.key});

  @override
  State<RegistrySearchPage> createState() => _RegistrySearchPageState();
}

class _RegistrySearchPageState extends State<RegistrySearchPage> {
  static const double _referenceWidth = 402;
  final TextEditingController _searchController = TextEditingController();

  final List<_RegistryResult> _results = <_RegistryResult>[
    const _RegistryResult(
      name: 'Arjun Malhotra',
      subtitle: 'Lead Technical Consultant',
      badgeLabel: 'VERIFIED PROF.',
      badgeIcon: Icons.verified_rounded,
      statusLabel: 'ACTIVE',
      metaLabel: 'TM-I-2024-081',
      avatarLabel: 'TM',
      avatarBg: Color(0xFFEAF2FF),
      avatarFg: Color(0xFF0051AB),
      actions: <_RegistryAction>[
        _RegistryAction.document,
        _RegistryAction.share,
      ],
      ctaLabel: 'View Profile',
      ctaIcon: Icons.open_in_new_rounded,
    ),
    const _RegistryResult(
      name: 'Assam Web Services',
      subtitle: 'Cloud Infrastructure Provider',
      badgeLabel: 'VERIFIED VENDOR',
      badgeIcon: Icons.verified_rounded,
      statusLabel: 'PENDING REVIEW',
      metaLabel: 'TM-I-2024-081',
      avatarLabel: 'TM',
      avatarBg: Color(0xFFEAF2FF),
      avatarFg: Color(0xFF0051AB),
      actions: <_RegistryAction>[
        _RegistryAction.document,
        _RegistryAction.share,
      ],
      ctaLabel: 'View Profile',
      ctaIcon: Icons.open_in_new_rounded,
    ),
    const _RegistryResult(
      name: 'Sania Kapoor',
      subtitle: 'Senior Software Engineer',
      badgeLabel: 'VERIFIED PROF.',
      badgeIcon: Icons.verified_rounded,
      statusLabel: 'ACTIVE',
      metaLabel: 'TM-I-2024-082',
      avatarLabel: 'TM',
      avatarBg: Color(0xFFEAF2FF),
      avatarFg: Color(0xFF0051AB),
      actions: <_RegistryAction>[
        _RegistryAction.document,
        _RegistryAction.share,
      ],
      ctaLabel: 'View Profile',
      ctaIcon: Icons.open_in_new_rounded,
    ),
    const _RegistryResult(
      name: 'Ravi Desai',
      subtitle: 'Product Manager',
      badgeLabel: 'VERIFIED PROF.',
      badgeIcon: Icons.verified_rounded,
      statusLabel: 'ACTIVE',
      metaLabel: 'TM-I-2024-083',
      avatarLabel: 'TM',
      avatarBg: Color(0xFFEAF2FF),
      avatarFg: Color(0xFF0051AB),
      actions: <_RegistryAction>[
        _RegistryAction.document,
        _RegistryAction.share,
      ],
      ctaLabel: 'View Profile',
      ctaIcon: Icons.open_in_new_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
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
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double contentWidth = screenWidth < _referenceWidth
        ? screenWidth
        : _referenceWidth;
    final double scale = contentWidth / _referenceWidth;
    double s(double value) => value * scale;

    final List<_RegistryResult> filtered = _results.where((result) {
      final String query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return result.name.toLowerCase().contains(query) ||
          result.subtitle.toLowerCase().contains(query) ||
          result.metaLabel.toLowerCase().contains(query) ||
          result.statusLabel.toLowerCase().contains(query) ||
          result.badgeLabel.toLowerCase().contains(query);
    }).toList();

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
                  child: _RegistryHeader(
                    scale: scale,
                    title: 'Organisation Registry Hub',
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                        return;
                      }
                      context.go(AppRouter.dashboardPath);
                    },
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
                        s(28) + safeBottom + s(110),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SearchRow(
                            scale: scale,
                            controller: _searchController,
                            onFilterTap: () {},
                          ),
                          SizedBox(height: s(24)),
                          Row(
                            children: <Widget>[
                              Text(
                                'Search Results',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: s(12),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1833819,
                                  height: 17.750728607177734 / 12,
                                  color: const Color(0xFF323232),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {},
                                behavior: HitTestBehavior.opaque,
                                child: SvgPicture.asset(
                                  'assets/icons/figma/registry_download.svg',
                                  width: s(24),
                                  height: s(24),
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.brandBlue,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: s(12)),
                          for (int i = 0; i < filtered.length; i++) ...<Widget>[
                            _RegistryResultCard(
                              scale: scale,
                              result: filtered[i],
                            ),
                            if (i != filtered.length - 1)
                              SizedBox(height: s(16)),
                          ],
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
}

class _RegistryHeader extends StatelessWidget {
  const _RegistryHeader({
    required this.scale,
    required this.title,
    required this.onBack,
  });

  final double scale;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;

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
    double s(double value) => value * scale;

    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: s(48),
            child: TextField(
              controller: controller,
              maxLines: 1,
              cursorColor: AppColors.brandBlue,
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                fontSize: s(14),
                fontWeight: FontWeight.w400,
                height: 16.70703125 / 14,
                color: const Color(0xFF111827),
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
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF111827),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: s(44),
                  minHeight: s(48),
                ),
                contentPadding: EdgeInsets.zero,
                hintText: 'Search by Name, GSTIN, ...',
                hintStyle: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: s(14),
                  fontWeight: FontWeight.w400,
                  height: 16.70703125 / 14,
                  color: const Color(0xFF94A3B8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(s(16)),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(s(16)),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(s(16)),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: s(16)),
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
              colorFilter: const ColorFilter.mode(
                Color(0xFF111827),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RegistryResultCard extends StatelessWidget {
  const _RegistryResultCard({required this.scale, required this.result});

  final double scale;
  final _RegistryResult result;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(24)),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0x142563EB),
            blurRadius: s(12),
            offset: Offset(0, s(2)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _RegistryAvatar(scale: scale, result: result),
              SizedBox(width: s(16)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      result.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(18),
                        fontWeight: FontWeight.w600,
                        height: 22.5 / 18,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: s(2)),
                    Text(
                      result.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: s(6)),
                    Wrap(
                      spacing: s(8),
                      runSpacing: s(8),
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        _BadgePill(
                          scale: scale,
                          icon: result.badgeIcon,
                          label: result.badgeLabel,
                        ),
                        _StatusPill(scale: scale, label: result.statusLabel),
                      ],
                    ),
                    SizedBox(height: s(8)),
                    Text(
                      result.metaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        fontSize: s(10),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.048828125,
                        height: 15 / 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: s(8)),
          Divider(color: const Color(0xFFF1F5F9), height: 1, thickness: 1),
          SizedBox(height: s(8)),
          Row(
            children: <Widget>[
              for (final _RegistryAction action in result.actions) ...<Widget>[
                _ActionSquare(scale: scale, action: action),
                SizedBox(width: s(8)),
              ],
              const Spacer(),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(s(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      result.ctaLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w600,
                        height: 20 / 14,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    SizedBox(width: s(6)),
                    Icon(
                      result.ctaIcon,
                      size: s(12),
                      color: AppColors.brandBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegistryAvatar extends StatelessWidget {
  const _RegistryAvatar({required this.scale, required this.result});

  final double scale;
  final _RegistryResult result;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;

    return Container(
      width: s(56),
      height: s(56),
      decoration: BoxDecoration(
        color: result.avatarBg,
        borderRadius: BorderRadius.circular(s(16)),
      ),
      alignment: Alignment.center,
      child: Text(
        result.avatarLabel,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: s(18),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4921875,
          height: 28 / 18,
          color: result.avatarFg,
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.scale,
    required this.icon,
    required this.label,
  });

  final double scale;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(8), vertical: s(6)),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(s(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: s(12), color: AppColors.brandBlue),
          SizedBox(width: s(6)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: s(10),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              height: 15 / 10,
              color: AppColors.brandBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;

    final bool active = label.toUpperCase() == 'ACTIVE';
    final Color fg = active ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final Color bg = active ? const Color(0xFFE8FAEF) : const Color(0xFFFFF7E8);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(8), vertical: s(6)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(s(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: s(6),
            height: s(6),
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          SizedBox(width: s(6)),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: s(10),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              height: 15 / 10,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSquare extends StatelessWidget {
  const _ActionSquare({required this.scale, required this.action});

  final double scale;
  final _RegistryAction action;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;

    return Container(
      width: s(40),
      height: s(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(12)),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      alignment: Alignment.center,
      child: action == _RegistryAction.share
          ? SvgPicture.asset(
              'assets/icons/figma/registry_share.svg',
              width: s(24),
              height: s(24),
              colorFilter: const ColorFilter.mode(
                Color(0xFF3F3F46),
                BlendMode.srcIn,
              ),
            )
          : SvgPicture.asset(
              'assets/icons/figma/registry_document.svg',
              width: s(24),
              height: s(24),
              colorFilter: const ColorFilter.mode(
                Color(0xFF3F3F46),
                BlendMode.srcIn,
              ),
            ),
    );
  }
}

class _RegistryResult {
  const _RegistryResult({
    required this.name,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.statusLabel,
    required this.metaLabel,
    required this.avatarLabel,
    required this.avatarBg,
    required this.avatarFg,
    required this.actions,
    required this.ctaLabel,
    required this.ctaIcon,
  });

  final String name;
  final String subtitle;
  final String badgeLabel;
  final IconData badgeIcon;
  final String statusLabel;
  final String metaLabel;
  final String avatarLabel;
  final Color avatarBg;
  final Color avatarFg;
  final List<_RegistryAction> actions;
  final String ctaLabel;
  final IconData ctaIcon;
}

enum _RegistryAction { document, share }
