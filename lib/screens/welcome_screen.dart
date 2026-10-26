import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/plateful_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onContinue,
    this.busy = false,
  });

  final VoidCallback onContinue;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const PlatefulLogo(height: 56),
              const SizedBox(height: 28),
              Text(
                'Make more.\nWaste less.',
                textAlign: TextAlign.center,
                style: AppText.display(fontSize: 34, height: 1.15),
              ),
              const SizedBox(height: 14),
              Text(
                'Photograph your kitchen, plan the week, and use food before it expires.',
                textAlign: TextAlign.center,
                style: AppText.body(fontSize: 15),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          onContinue();
                        },
                  child: Text(
                    busy ? 'Loading…' : 'Get started',
                    style: AppText.button(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
