import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../screens/account_settings_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Food preferences',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
        );
      },
      child: Tooltip(
        message: 'Food preferences',
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.sageSoft,
            shape: BoxShape.circle,
          ),
          child: _face(context),
        ),
      ),
    );
  }

  Widget _face(BuildContext context) {
    final name = context.watch<AppState>().preferences.displayName.trim();
    if (name.isEmpty) {
      return const Icon(
        PhosphorIconsRegular.user,
        color: AppColors.forest,
        size: 20,
      );
    }
    return Text(
      name.characters.first.toUpperCase(),
      style: AppText.display(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.forest,
        height: 1,
        letterSpacing: 0,
      ),
    );
  }
}
