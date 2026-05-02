import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class IndividualSkillTreePage extends StatelessWidget {
  const IndividualSkillTreePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color pageSurface = Color(0xFFFAF8FF);
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: pageSurface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Add entry (mock)')));
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFEEF3FF), width: 1),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'My Skill Tree',
                              style: AppTypography.heading1.copyWith(
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Share (mock)')),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.share_outlined,
                                color: AppColors.textSecondary,
                              ),
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
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(<Widget>[
                Text(
                  'Your verified digital resume - every item is blockchain-backed',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                const _StatsRow(),
                const SizedBox(height: AppSpacing.x6),
                const _SectionCard(
                  title: 'Education',
                  countLabel: '3 entries',
                  items: <_EntryItem>[
                    _EntryItem(
                      title: '10th',
                      subtitle: 'Delhi Public School · 2016',
                      code: 'TM-EDU-2026-00011',
                      status: _EntryStatus.verified,
                    ),
                    _EntryItem(
                      title: '12th',
                      subtitle: 'Delhi Public School · 2018',
                      code: 'TM-EDU-2026-00012',
                      status: _EntryStatus.verified,
                    ),
                    _EntryItem(
                      title: 'Graduation',
                      subtitle: 'Mumbai University · 2022',
                      code: 'TM-EDU-2026-00013',
                      status: _EntryStatus.verified,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x5),
                const _SectionCard(
                  title: 'Courses & Certifications',
                  countLabel: '3 entries',
                  items: <_EntryItem>[
                    _EntryItem(
                      title: 'Python Advanced',
                      subtitle: 'Coursera · 2023',
                      code: 'TM-CRS-2026-00021',
                      status: _EntryStatus.verified,
                    ),
                    _EntryItem(
                      title: 'Data Analysis',
                      subtitle: 'Internshala · 2023',
                      code: 'TM-CRS-2026-00023',
                      status: _EntryStatus.pending,
                    ),
                    _EntryItem(
                      title: 'Tally ERP',
                      subtitle: 'NIIT · 2022',
                      code: 'TM-CRS-2026-00022',
                      status: _EntryStatus.verified,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x5),
                const _SectionCard(
                  title: 'Work Experience',
                  countLabel: '1 entries',
                  items: <_EntryItem>[
                    _EntryItem(
                      title: 'Software Intern',
                      subtitle: 'XYZ Pvt Ltd · 2022',
                      code: 'TM-EXP-2026-00031',
                      status: _EntryStatus.verified,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x5),
                const _SectionCard(
                  title: 'Skills',
                  countLabel: '2 entries',
                  items: <_EntryItem>[
                    _EntryItem(
                      title: 'Advanced',
                      subtitle: '',
                      code: 'TM-SKL-2026-00041',
                      status: _EntryStatus.verified,
                    ),
                    _EntryItem(
                      title: 'Expert',
                      subtitle: '',
                      code: 'TM-SKL-2026-00042',
                      status: _EntryStatus.verified,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x8),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Expanded(
          child: _StatCard(
            label: 'Total Entries',
            value: '9',
            icon: Icons.library_books_outlined,
          ),
        ),
        SizedBox(width: AppSpacing.x3),
        Expanded(
          child: _StatCard(
            label: 'Verified',
            value: '8',
            icon: Icons.verified_rounded,
          ),
        ),
        SizedBox(width: AppSpacing.x3),
        Expanded(
          child: _StatCard(
            label: 'Pending',
            value: '1',
            icon: Icons.hourglass_top_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF3FF)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(0x12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withAlpha(14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.brandBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.heading1.copyWith(
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.countLabel,
    required this.items,
  });

  final String title;
  final String countLabel;
  final List<_EntryItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEF3FF)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(0x12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Add to $title (mock)')),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < items.length; i++) ...<Widget>[
            _EntryTile(item: items[i]),
            if (i != items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFEEF3FF)),
              ),
          ],
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.item});

  final _EntryItem item;

  @override
  Widget build(BuildContext context) {
    final _StatusPill status = switch (item.status) {
      _EntryStatus.verified => const _StatusPill(
        label: 'Verified',
        bg: Color(0xFFE7F7EE),
        fg: Color(0xFF0E7A3C),
        dot: Color(0xFF16A34A),
      ),
      _EntryStatus.pending => const _StatusPill(
        label: 'Pending',
        bg: Color(0xFFFFF7ED),
        fg: Color(0xFF9A3412),
        dot: Color(0xFFF59E0B),
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.title,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (item.subtitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                item.code,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        status,
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.bg,
    required this.fg,
    required this.dot,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

enum _EntryStatus { verified, pending }

class _EntryItem {
  const _EntryItem({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String code;
  final _EntryStatus status;
}
