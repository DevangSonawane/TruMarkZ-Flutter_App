import 'dart:math';

import 'package:flutter/material.dart';

enum ProductVerificationCheckMode { auto, manual }

class ProductVerificationCheckDefinition {
  const ProductVerificationCheckDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.icon,
    required this.priceMinInr,
    required this.priceMaxInr,
  });

  final String id;
  final String title;
  final String subtitle;
  final ProductVerificationCheckMode mode;
  final IconData icon;
  final int priceMinInr;
  final int priceMaxInr;
}

class ProductVerificationChecksCatalog {
  ProductVerificationChecksCatalog._();

  static const List<ProductVerificationCheckDefinition> items =
      <ProductVerificationCheckDefinition>[
        ProductVerificationCheckDefinition(
          id: 'bis_certificate',
          title: 'BIS Certificate',
          subtitle: 'Regulatory compliance and registration validity',
          mode: ProductVerificationCheckMode.auto,
          icon: Icons.verified_rounded,
          priceMinInr: 120,
          priceMaxInr: 260,
        ),
        ProductVerificationCheckDefinition(
          id: 'factory_quality_test_report',
          title: 'Factory Quality Test Report',
          subtitle: 'Manufacturing QC report review',
          mode: ProductVerificationCheckMode.manual,
          icon: Icons.fact_check_rounded,
          priceMinInr: 180,
          priceMaxInr: 420,
        ),
        ProductVerificationCheckDefinition(
          id: 'electrical_safety_report',
          title: 'Electrical Safety Report',
          subtitle: 'Electrical safety and compliance validation',
          mode: ProductVerificationCheckMode.auto,
          icon: Icons.electrical_services_rounded,
          priceMinInr: 160,
          priceMaxInr: 360,
        ),
        ProductVerificationCheckDefinition(
          id: 'installation_certificate',
          title: 'Installation Certificate',
          subtitle: 'Installation completion and sign-off',
          mode: ProductVerificationCheckMode.manual,
          icon: Icons.handyman_rounded,
          priceMinInr: 120,
          priceMaxInr: 280,
        ),
        ProductVerificationCheckDefinition(
          id: 'warranty_card',
          title: 'Warranty Card',
          subtitle: 'Warranty terms and activation verification',
          mode: ProductVerificationCheckMode.manual,
          icon: Icons.card_membership_rounded,
          priceMinInr: 100,
          priceMaxInr: 240,
        ),
        ProductVerificationCheckDefinition(
          id: 'service_centre_details',
          title: 'Service Centre Details',
          subtitle: 'Authorized service network validation',
          mode: ProductVerificationCheckMode.auto,
          icon: Icons.store_rounded,
          priceMinInr: 90,
          priceMaxInr: 220,
        ),
        ProductVerificationCheckDefinition(
          id: 'repair_history',
          title: 'Repair History',
          subtitle: 'Past repairs and service log review',
          mode: ProductVerificationCheckMode.manual,
          icon: Icons.build_circle_rounded,
          priceMinInr: 140,
          priceMaxInr: 320,
        ),
        ProductVerificationCheckDefinition(
          id: 'extended_warranty_eligibility',
          title: 'Extended Warranty Eligibility',
          subtitle: 'Eligibility for extended warranty coverage',
          mode: ProductVerificationCheckMode.auto,
          icon: Icons.workspace_premium_rounded,
          priceMinInr: 150,
          priceMaxInr: 340,
        ),
      ];

  static final Map<String, int> pricesInr = _buildPrices();

  static final Map<String, ProductVerificationCheckDefinition> byId =
      <String, ProductVerificationCheckDefinition>{
        for (final ProductVerificationCheckDefinition item in items)
          item.id: item,
      };

  static Map<String, int> _buildPrices() {
    final Random random = Random();
    return <String, int>{
      for (final ProductVerificationCheckDefinition item in items)
        item.id:
            item.priceMinInr +
            random.nextInt(item.priceMaxInr - item.priceMinInr + 1),
    };
  }
}
