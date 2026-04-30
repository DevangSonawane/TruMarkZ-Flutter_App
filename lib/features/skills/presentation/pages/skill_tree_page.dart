import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_card.dart';
import '../../../../core/widgets/tmz_input.dart';

class SkillTreePage extends StatefulWidget {
  const SkillTreePage({super.key});

  @override
  State<SkillTreePage> createState() => _SkillTreePageState();
}

class _SkillTreePageState extends State<SkillTreePage> {
  final List<String> _items = <String>[
    'Verified Identity',
    'Public Verification',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset('assets/icons/trumarkz_shield.svg', height: 24),
            const SizedBox(width: AppSpacing.x2),
            const Text('Individual Skill Tree'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Progress', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x3),
          ..._items.map((String label) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x2),
              child: TMZCard(
                onTap: () => context.push(AppRouter.individualRecordDetailPath),
                child: ListTile(
                  leading: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.brandBlue,
                  ),
                  title: Text(label),
                  subtitle: const Text('Tap to view details'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final String? result = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (BuildContext context) => const _AddSkillItemSheet(),
          );
          if (result == null || result.trim().isEmpty) return;
          setState(() => _items.add(result.trim()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddSkillItemSheet extends StatefulWidget {
  const _AddSkillItemSheet();

  @override
  State<_AddSkillItemSheet> createState() => _AddSkillItemSheetState();
}

class _AddSkillItemSheetState extends State<_AddSkillItemSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x2,
        AppSpacing.x4,
        AppSpacing.x4 + viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Add item', style: AppTypography.heading1),
          const SizedBox(height: AppSpacing.x3),
          TMZInput(
            label: 'Skill item',
            hint: 'e.g. Proof of Address',
            controller: _controller,
          ),
          const SizedBox(height: AppSpacing.x4),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
