import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'quantity_label.dart';

class PantryChip extends StatelessWidget {
  const PantryChip({
    super.key,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String name;
  final double quantity;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final qty = formatQuantity(quantity);
    final unitText = _visibleUnit(unit);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: AppShadows.chip,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: name,
              style: AppText.label(color: AppColors.ink, fontSize: 14),
            ),
            TextSpan(
              text: unitText == null ? ' $qty' : ' $qty $unitText',
              style: AppText.label(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String? _visibleUnit(String raw) {
    final u = raw.trim();
    const hidden = {'pcs', 'pc', 'piece', 'pieces', 'count', 'x'};
    if (u.isEmpty || hidden.contains(u.toLowerCase())) return null;
    return u;
  }
}
