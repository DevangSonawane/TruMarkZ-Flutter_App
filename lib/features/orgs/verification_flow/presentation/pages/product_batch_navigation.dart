import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/auth_models.dart';
import '../../../../../core/models/verification_models.dart';
import '../../../../../core/router/app_router.dart';
import '../../../data/verification_repository.dart';

String savedProductIndustry(UserProfile? profile) {
  final List<String> savedIndustries =
      (profile?.industryTypes ?? const <String>[])
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .toList();
  if (savedIndustries.isNotEmpty) return savedIndustries.first;
  return (profile?.industry ?? '').trim();
}

Future<void> openProductBatchFlowForSavedIndustry({
  required BuildContext context,
  required WidgetRef ref,
  required UserProfile? profile,
  bool replace = false,
}) async {
  final String industry = savedProductIndustry(profile);
  if (industry.isEmpty) {
    _go(
      context: context,
      location: AppRouter.productSectorSelectorPath,
      replace: replace,
    );
    return;
  }

  VerificationIndustryType? matchedIndustry;
  try {
    final List<VerificationIndustryType> industries = await ref
        .read(verificationRepositoryProvider)
        .getIndustryTypes();
    if (!context.mounted) return;
    final String key = industry.toLowerCase();
    for (final VerificationIndustryType item in industries) {
      if (item.name.trim().toLowerCase() == key) {
        matchedIndustry = item;
        break;
      }
    }
  } catch (_) {
    if (!context.mounted) return;
    // Keep the create flow moving; unknown saved industries should still
    // expose the product service choice instead of jumping to checks.
  }

  final String warrantySupport =
      matchedIndustry?.warrantySupport.trim().isNotEmpty == true
      ? matchedIndustry!.warrantySupport.trim()
      : 'optional';
  final bool supportsWarranty = matchedIndustry?.supportsWarranty ?? true;
  final Map<String, String> queryParameters = <String, String>{
    'flow': 'product',
    'sector': industry,
    'sector_title': industry,
    'industry': industry,
    'category_id': industry,
    'warranty_support': warrantySupport,
    'supports_warranty': supportsWarranty ? 'true' : 'false',
  };
  final Uri uri = Uri(
    path: supportsWarranty
        ? AppRouter.productServiceTypeSelectorPath
        : AppRouter.verificationChecksPath,
    queryParameters: <String, String>{
      ...queryParameters,
      if (!supportsWarranty) 'mode': 'verification',
    },
  );
  _go(
    context: context,
    location: uri.toString(),
    extra: industry,
    replace: replace,
  );
}

void _go({
  required BuildContext context,
  required String location,
  Object? extra,
  required bool replace,
}) {
  if (replace) {
    context.pushReplacement(location, extra: extra);
  } else {
    context.push(location, extra: extra);
  }
}
