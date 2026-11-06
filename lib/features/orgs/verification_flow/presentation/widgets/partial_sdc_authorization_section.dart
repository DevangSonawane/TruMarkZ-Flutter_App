import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/sdc_approval_models.dart';
import '../../../../../core/models/verification_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../data/verification_repository.dart';

/// Organization authorization only. It deliberately contains no generation UI:
/// issuing a full or partial SDC is a SuperAdmin operation.
class PartialSdcAuthorizationSection extends ConsumerStatefulWidget {
  const PartialSdcAuthorizationSection({
    super.key,
    required this.batchId,
    required this.users,
  });
  final String batchId;
  final List<VerificationUser> users;

  @override
  ConsumerState<PartialSdcAuthorizationSection> createState() =>
      _PartialSdcAuthorizationSectionState();
}

class _PartialSdcAuthorizationSectionState
    extends ConsumerState<PartialSdcAuthorizationSection> {
  final Map<String, Set<String>> _selected = <String, Set<String>>{};
  final Map<String, List<String>> _holderErrors = <String, List<String>>{};
  bool _saving = false;

  bool _isFullyApproved(VerificationUser user) {
    final List<VerificationCheckStatus> checks = user.verificationChecks;
    return checks.isNotEmpty &&
        checks.every(
          (VerificationCheckStatus c) =>
              c.status.trim().toLowerCase() == 'approved',
        );
  }

  List<VerificationCheckStatus> _approved(VerificationUser user) => user
      .verificationChecks
      .where(
        (VerificationCheckStatus c) =>
            c.status.trim().toLowerCase() == 'approved',
      )
      .toList();

  Future<void> _save() async {
    final List<Map<String, dynamic>> holders = _selected.entries
        .where((MapEntry<String, Set<String>> e) => e.value.isNotEmpty)
        .map(
          (MapEntry<String, Set<String>> e) => <String, dynamic>{
            'batch_user_id': e.key,
            'verification_types': e.value.toList(),
          },
        )
        .toList();
    if (holders.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(verificationRepositoryProvider)
          .createPartialSdcAuthorizations(
            batchId: widget.batchId,
            holders: holders,
          );
      ref.invalidate(partialSdcAuthorizationsProvider(widget.batchId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Authorization saved. A SuperAdmin can now generate the partial SDC.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      final dynamic rawHolders = error.detail?['holders'];
      if (rawHolders is List) {
        _holderErrors
          ..clear()
          ..addEntries(
            rawHolders
                .whereType<Map>()
                .map((Map raw) {
                  final Map<String, dynamic> item = Map<String, dynamic>.from(
                    raw,
                  );
                  final List<String> messages =
                      (item['errors'] as List? ?? const <dynamic>[])
                          .map((dynamic value) => value.toString())
                          .where((String value) => value.trim().isNotEmpty)
                          .toList();
                  return MapEntry(
                    (item['batch_user_id'] ?? '').toString(),
                    messages,
                  );
                })
                .where(
                  (MapEntry<String, List<String>> entry) =>
                      entry.key.isNotEmpty,
                ),
          );
        if (mounted) setState(() {});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.statusCode == 409
                  ? 'This changed concurrently. Refresh and try again.'
                  : error.message,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<VerificationUser> eligible = widget.users
        .where(
          (VerificationUser u) =>
              !_isFullyApproved(u) && _approved(u).isNotEmpty,
        )
        .toList();
    final AsyncValue<List<PartialSdcAuthorization>> authorizations = ref.watch(
      partialSdcAuthorizationsProvider(widget.batchId),
    );
    if (eligible.isEmpty && authorizations.valueOrNull == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Partial SDC authorization',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Authorize approved checks for holders who are not fully verified. SDCs are generated by a SuperAdmin.',
            ),
            for (final VerificationUser user in eligible) ...<Widget>[
              const Divider(height: 24),
              Text(
                user.fullName.isNotEmpty ? user.fullName : user.email,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              for (final VerificationCheckStatus check in _approved(user))
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(check.name),
                  subtitle: const Text('Approved'),
                  value: _selected[user.id]?.contains(check.name) ?? false,
                  onChanged: (bool? selected) => setState(() {
                    final Set<String> types = _selected.putIfAbsent(
                      user.id,
                      () => <String>{},
                    );
                    if (selected == true) {
                      types.add(check.name);
                    } else {
                      types.remove(check.name);
                    }
                  }),
                ),
              if ((_holderErrors[user.id] ?? const <String>[]).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    _holderErrors[user.id]!
                        .map((String error) => '• $error')
                        .join('\n'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
            if (eligible.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Authorize selected'),
                ),
              ),
            authorizations.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (List<PartialSdcAuthorization> items) => Column(
                children: <Widget>[
                  for (final PartialSdcAuthorization authorization in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        authorization.holderName.isNotEmpty
                            ? authorization.holderName
                            : authorization.batchUserId,
                      ),
                      subtitle: Text(
                        !authorization.isValid
                            ? 'Results changed — authorize again'
                            : authorization.status,
                      ),
                      trailing: authorization.status == 'active'
                          ? TextButton(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(verificationRepositoryProvider)
                                      .cancelPartialSdcAuthorization(
                                        authorization.id,
                                      );
                                  ref.invalidate(
                                    partialSdcAuthorizationsProvider(
                                      widget.batchId,
                                    ),
                                  );
                                } on ApiException catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error.message)),
                                    );
                                  }
                                }
                              },
                              child: const Text('Cancel'),
                            )
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
