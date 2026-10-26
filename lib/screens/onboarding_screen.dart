import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user_preferences.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/toggle_chip.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  final _name = TextEditingController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final state = context.read<AppState>();
    final name = _name.text.trim();
    if (name.isNotEmpty) {
      await state.updatePreferences(
        state.preferences.copyWith(displayName: name),
      );
    }
    await state.markOnboardingSeen();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final prefs = state.preferences;
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _pageBody(
                    title: 'What should we call you?',
                    body: 'This is only stored on your phone. Skip it if you’d rather stay anonymous.',
                    child: TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Your name'),
                    ),
                  ),
                  _pageBody(
                    title: 'Anything you can’t eat?',
                    body: 'These are hard rules. Recipes will never include them.',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in UserPreferences.allergyOptions)
                          ToggleChip(
                            label: option,
                            selected: prefs.allergies.contains(option),
                            variant: ToggleChipVariant.danger,
                            onTap: () {
                              final next = [...prefs.allergies];
                              if (!next.remove(option)) next.add(option);
                              state.updatePreferences(
                                prefs.copyWith(allergies: next),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  _pageBody(
                    title: 'How do you eat?',
                    body: 'Pick one style. Halal and Kosher can be added on top.',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in UserPreferences.dietOptions)
                          ToggleChip(
                            label: option,
                            selected: prefs.diets.contains(option),
                            variant: ToggleChipVariant.solid,
                            onTap: () => state.updatePreferences(
                              prefs.copyWith(
                                diets: UserPreferences.toggleDiet(prefs.diets, option),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PrimaryButton(
                label: _index == 2 ? 'Start cooking' : 'Continue',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_index == 2) {
                    _finish();
                  } else {
                    _page.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBody({
    required String title,
    required String body,
    required Widget child,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      children: [
        Text(title, style: AppText.h1()),
        const SizedBox(height: 10),
        Text(body, style: AppText.body()),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}
