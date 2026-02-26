import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/stokvel.dart';

class StokvelTypeChip extends StatelessWidget {
  final StokvelType type;

  const StokvelTypeChip({super.key, required this.type});

  Color get _backgroundColor {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _backgroundColor,
        ),
      ),
    );
  }
}
