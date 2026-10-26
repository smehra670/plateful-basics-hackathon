import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class RulePill extends StatelessWidget {
  const RulePill._({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  factory RulePill.never(String label) {
    return RulePill._(
      label: label,
      background: AppColors.roseSoft,
      foreground: AppColors.roseText,
      icon: PhosphorIconsRegular.prohibit,
    );
  }

  factory RulePill.always(String label) {
    return RulePill._(
      label: label,
      background: AppColors.sageSoft,
      foreground: AppColors.forest,
      icon: PhosphorIconsRegular.check,
    );
  }

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.caption(color: foreground, fontSize: 12).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One "No …" pill per allergy and one pill for the saved diet.
class AccountRulePills extends StatelessWidget {
  const AccountRulePills({super.key, this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppState>().preferences;
    final pills = <Widget>[
      for (final allergy in prefs.allergies)
        RulePill.never('No ${allergy.toLowerCase()}'),
      for (final diet in prefs.diets)
        if (diet != 'Omnivore' || prefs.diets.length == 1)
          RulePill.always(diet),
    ];
    if (pills.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      children: pills,
    );
  }
}
