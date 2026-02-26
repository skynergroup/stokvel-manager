import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/stokvel.dart';

/// Group avatar with initials fallback and type-based color.
class StokvelAvatar extends StatelessWidget {
  final String name;
  final StokvelType type;
  final String? imageUrl;
  final double radius;

  const StokvelAvatar({
    super.key,
    required this.name,
    required this.type,
    this.imageUrl,
    this.radius = 24,
  });

  static Color colorForType(StokvelType type) {
    switch (type) {
      case StokvelType.rotational:
        return AppColors.rotational;
      case StokvelType.savings:
        return AppColors.savings;
      case StokvelType.burial:
        return AppColors.burial;
      case StokvelType.grocery:
        return AppColors.grocery;
      case StokvelType.investment:
        return AppColors.investment;
      case StokvelType.hybrid:
        return AppColors.hybrid;
    }
  }

  String _initials() {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorForType(type);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: color.withValues(alpha: 0.1),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        _initials(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}
