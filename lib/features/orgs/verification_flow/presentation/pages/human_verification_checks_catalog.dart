import 'dart:math';

import 'package:flutter/material.dart';

enum HumanVerificationCheckMode { auto, manual }

class HumanVerificationCheckDefinition {
  const HumanVerificationCheckDefinition({
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
  final HumanVerificationCheckMode mode;
  final IconData icon;
  final int priceMinInr;
  final int priceMaxInr;
}

class HumanVerificationChecksCatalog {
  HumanVerificationChecksCatalog._();

  static const List<HumanVerificationCheckDefinition> items =
      <HumanVerificationCheckDefinition>[
        HumanVerificationCheckDefinition(
          id: 'police',
          title: 'Police',
          subtitle: 'Police station verification',
          mode: HumanVerificationCheckMode.auto,
          icon: Icons.local_police_rounded,
          priceMinInr: 140,
          priceMaxInr: 260,
        ),
        HumanVerificationCheckDefinition(
          id: 'dob',
          title: 'DOB',
          subtitle: 'Date of birth validation',
          mode: HumanVerificationCheckMode.auto,
          icon: Icons.cake_rounded,
          priceMinInr: 60,
          priceMaxInr: 120,
        ),
        HumanVerificationCheckDefinition(
          id: 'education',
          title: 'Education',
          subtitle: 'Degree and institute verification',
          mode: HumanVerificationCheckMode.manual,
          icon: Icons.school_rounded,
          priceMinInr: 220,
          priceMaxInr: 420,
        ),
        HumanVerificationCheckDefinition(
          id: 'skills',
          title: 'Skills',
          subtitle: 'Skill match and competency check',
          mode: HumanVerificationCheckMode.manual,
          icon: Icons.psychology_rounded,
          priceMinInr: 120,
          priceMaxInr: 280,
        ),
        HumanVerificationCheckDefinition(
          id: 'criminal_record',
          title: 'Criminal Record',
          subtitle: 'Background record search',
          mode: HumanVerificationCheckMode.auto,
          icon: Icons.gavel_rounded,
          priceMinInr: 180,
          priceMaxInr: 380,
        ),
        HumanVerificationCheckDefinition(
          id: 'address',
          title: 'Address',
          subtitle: 'Current and past address verification',
          mode: HumanVerificationCheckMode.manual,
          icon: Icons.location_on_rounded,
          priceMinInr: 120,
          priceMaxInr: 300,
        ),
        HumanVerificationCheckDefinition(
          id: 'driving_license',
          title: 'Driving License',
          subtitle: 'License validity and status check',
          mode: HumanVerificationCheckMode.auto,
          icon: Icons.drive_eta_rounded,
          priceMinInr: 100,
          priceMaxInr: 240,
        ),
        HumanVerificationCheckDefinition(
          id: 'experience',
          title: 'Experience',
          subtitle: 'Employment and tenure verification',
          mode: HumanVerificationCheckMode.manual,
          icon: Icons.work_history_rounded,
          priceMinInr: 180,
          priceMaxInr: 450,
        ),
        HumanVerificationCheckDefinition(
          id: 'drug_test',
          title: 'Drug Test',
          subtitle: 'Medical screening verification',
          mode: HumanVerificationCheckMode.auto,
          icon: Icons.science_rounded,
          priceMinInr: 250,
          priceMaxInr: 600,
        ),
        HumanVerificationCheckDefinition(
          id: 'police_verification',
          title: 'Police Verification',
          subtitle: 'Official police clearance verification',
          mode: HumanVerificationCheckMode.manual,
          icon: Icons.verified_user_rounded,
          priceMinInr: 180,
          priceMaxInr: 420,
        ),
        HumanVerificationCheckDefinition(
          id: 'company',
          title: 'Company',
          subtitle: 'Employer and organization verification',
          mode: HumanVerificationCheckMode.manual,
          icon: Icons.domain_rounded,
          priceMinInr: 120,
          priceMaxInr: 280,
        ),
      ];

  static final Map<String, int> humanPricesInr = _buildPrices();

  static final Map<String, HumanVerificationCheckDefinition> byId =
      <String, HumanVerificationCheckDefinition>{
        for (final HumanVerificationCheckDefinition item in items)
          item.id: item,
      };

  static Map<String, int> _buildPrices() {
    final Random random = Random();
    return <String, int>{
      for (final HumanVerificationCheckDefinition item in items)
        item.id:
            item.priceMinInr +
            random.nextInt(item.priceMaxInr - item.priceMinInr + 1),
    };
  }
}
