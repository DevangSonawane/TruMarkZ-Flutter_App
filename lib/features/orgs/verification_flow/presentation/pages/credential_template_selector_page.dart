import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class CredentialTemplateSelectorPage extends StatefulWidget {
  const CredentialTemplateSelectorPage({super.key});

  @override
  State<CredentialTemplateSelectorPage> createState() =>
      _CredentialTemplateSelectorPageState();
}

class _CredentialTemplateSelectorPageState
    extends State<CredentialTemplateSelectorPage> {
  static const List<_CredentialTemplate> _templates = <_CredentialTemplate>[
    _CredentialTemplate(
      id: 't1',
      title: 'Workforce / Driver ID',
      subtitle: 'Photo, Name, Designation, Licence No., Verified checks, QR',
      icon: Icons.badge_rounded,
      tag: 'T1',
    ),
    _CredentialTemplate(
      id: 't2',
      title: 'Healthcare / Nurse',
      subtitle:
          'Photo, Name, Qualification, Registration No., Issuing body, QR',
      icon: Icons.medical_services_outlined,
      tag: 'T2',
    ),
    _CredentialTemplate(
      id: 't3',
      title: 'Education / Student',
      subtitle: 'Photo, Name, Course, Institution, Year, Credential ID, QR',
      icon: Icons.school_outlined,
      tag: 'T3',
    ),
    _CredentialTemplate(
      id: 't4',
      title: 'Product / Compliance',
      subtitle:
          'Product name, Batch No., Compliance type, Issuing org, Verified by, QR',
      icon: Icons.inventory_2_outlined,
      tag: 'T4',
    ),
    _CredentialTemplate(
      id: 't5',
      title: 'Service / Professional',
      subtitle:
          'Photo, Name, Skill/Service, Years of experience, Verified by, QR',
      icon: Icons.construction_rounded,
      tag: 'T5',
    ),
    _CredentialTemplate(
      id: 't6',
      title: 'Skill Tree Credential',
      subtitle: 'Photo, Name, Skills with verification nodes, IDs, QR',
      icon: Icons.account_tree_outlined,
      tag: 'T6',
    ),
  ];

  String _selectedId = _templates.first.id;

  void _continue(BuildContext context) {
    final Map<String, String> qp = Map<String, String>.from(
      GoRouterState.of(context).uri.queryParameters,
    );
    qp['template'] = _selectedId;
    final String qs = qp.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    context.push(
      qs.isEmpty
          ? AppRouter.mapCredentialFieldsPath
          : '${AppRouter.mapCredentialFieldsPath}?$qs',
    );
  }

  @override
  Widget build(BuildContext context) {
    final _CredentialTemplate selected = _templates.firstWhere(
      (t) => t.id == _selectedId,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(230),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 8,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Pick a Template',
          style: AppTypography.heading1.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const <Widget>[SizedBox(width: AppSpacing.x2)],
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x4,
              AppSpacing.x4,
              190,
            ),
            children: <Widget>[
              Text(
                'Select the template that matches your use case.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _templates.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.x3,
                  crossAxisSpacing: AppSpacing.x3,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final _CredentialTemplate template = _templates[index];
                  final bool isSelected = template.id == _selectedId;
                  return _TemplateGridCard(
                    template: template,
                    selected: isSelected,
                    onTap: () => setState(() => _selectedId = template.id),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.x5),
              _FeaturedPreviewCard(template: selected),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Builder(
              builder: (BuildContext context) {
                final double bottomInset = MediaQuery.viewPaddingOf(
                  context,
                ).bottom;

                return Container(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.x4,
                    AppSpacing.x3,
                    AppSpacing.x4,
                    AppSpacing.x3 + bottomInset,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.brandBlue.withAlpha(26),
                              width: 2,
                            ),
                            foregroundColor: AppColors.brandBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.visibility_rounded,
                            color: AppColors.brandBlue,
                          ),
                          label: Text(
                            'Preview Template',
                            style: AppTypography.button.copyWith(
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _continue(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  'Continue with ${selected.tag}: ${selected.title}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.button.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialTemplate {
  const _CredentialTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;
}

class _TemplateGridCard extends StatelessWidget {
  const _TemplateGridCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final _CredentialTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? const Color(0xFFEEF3FF) : Colors.white;
    final Color borderColor = selected
        ? AppColors.brandBlue.withAlpha(90)
        : Colors.black.withAlpha(12);
    final BoxShadow shadow = BoxShadow(
      color: const Color(0xFF2563EB).withAlpha(20),
      blurRadius: 12,
      offset: const Offset(0, 2),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[shadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.brandBlue
                              : AppColors.brandBlue.withAlpha(18),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          template.icon,
                          size: 20,
                          color: selected ? Colors.white : AppColors.brandBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        template.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body1.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.brandBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
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

class _FeaturedPreviewCard extends StatelessWidget {
  const _FeaturedPreviewCard({required this.template});

  final _CredentialTemplate template;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.brandBlue.withAlpha(40),
                      const Color(0xFF7C3AED).withAlpha(28),
                      const Color(0xFF0B1220).withAlpha(18),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withAlpha(178),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withAlpha(40),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withAlpha(26),
                        ),
                      ),
                      child: Text(
                        'Live Preview',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      '${template.title} Standard',
                      style: AppTypography.display2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Visualizing the secure verification layer.',
                      style: AppTypography.body2.copyWith(
                        color: Colors.white.withAlpha(204),
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
