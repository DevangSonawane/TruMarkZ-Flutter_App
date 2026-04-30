import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TMZAvatar extends StatelessWidget {
  const TMZAvatar({
    super.key,
    this.imageProvider,
    this.size = 36,
    this.fallbackIcon = Icons.person,
  });

  final ImageProvider? imageProvider;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.silverGray,
      foregroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(fallbackIcon, size: size * 0.55, color: AppColors.darkNavy)
          : null,
    );
  }
}
