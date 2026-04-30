import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_card.dart';

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
      title: 'T1 — Workforce / Driver ID',
      subtitle: 'Name, photo, ID number, employer',
      icon: Icons.local_shipping_outlined,
      tag: 'WORKFORCE',
    ),
    _CredentialTemplate(
      id: 't2',
      title: 'T2 — Healthcare / Nurse',
      subtitle: 'License ID, hospital, validity, role',
      icon: Icons.medical_services_outlined,
      tag: 'HEALTH',
    ),
    _CredentialTemplate(
      id: 't3',
      title: 'T3 — Education / Student',
      subtitle: 'Institute, enrollment, course, batch',
      icon: Icons.school_outlined,
      tag: 'EDU',
    ),
    _CredentialTemplate(
      id: 't4',
      title: 'T4 — Product / Compliance',
      subtitle: 'Product ID, batch, standards, audit proof',
      icon: Icons.inventory_2_outlined,
      tag: 'COMPLIANCE',
    ),
    _CredentialTemplate(
      id: 't5',
      title: 'T5 — Service / Professional',
      subtitle: 'Service ID, credentials, validity, scope',
      icon: Icons.work_outline_rounded,
      tag: 'SERVICE',
    ),
    _CredentialTemplate(
      id: 't6',
      title: 'T6 — Skill Tree Credential',
      subtitle: 'Skill, level, issuer, endorsements',
      icon: Icons.account_tree_outlined,
      tag: 'SKILLS',
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final _CredentialTemplate selected = _templates.firstWhere(
      (t) => t.id == _selectedId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 22,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('Template Selector'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x4,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                children: <Widget>[
                  Text('Choose a template', style: AppTypography.display2),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Select a credential template that matches your batch industry.',
                    style: AppTypography.body2.copyWith(
                      color: scheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final bool wide = constraints.maxWidth >= 720;
                          final int columns = wide ? 2 : 1;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _templates.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: AppSpacing.x3,
                                  crossAxisSpacing: AppSpacing.x3,
                                  childAspectRatio: wide ? 2.6 : 2.9,
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              final _CredentialTemplate template =
                                  _templates[index];
                              final bool selected = template.id == _selectedId;
                              return _TemplateCard(
                                template: template,
                                selected: selected,
                                onTap: () =>
                                    setState(() => _selectedId = template.id),
                              );
                            },
                          );
                        },
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x2,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                child: TMZButton(
                  label: 'Continue with ${selected.id.toUpperCase()}',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => _continue(context),
                ),
              ),
            ),
          ],
        ),
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final _CredentialTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return TMZCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withAlpha(16),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(template.icon, color: AppColors.brandBlue, size: 22),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        template.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.brandBlue.withAlpha(22)
                            : scheme.onSurface.withAlpha(10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? AppColors.brandBlue.withAlpha(60)
                              : scheme.onSurface.withAlpha(18),
                        ),
                      ),
                      child: Text(
                        template.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                          color: selected
                              ? AppColors.brandBlue
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  template.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body2.copyWith(
                    color: scheme.onSurface.withAlpha(160),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected
                ? AppColors.brandBlue
                : scheme.onSurface.withAlpha(90),
          ),
        ],
      ),
    );
  }
}
