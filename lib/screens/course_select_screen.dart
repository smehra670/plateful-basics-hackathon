import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/pressable.dart';
import '../widgets/primary_button.dart';
import '../widgets/rule_pill.dart';
import 'chef_screen.dart';

class CourseSelectScreen extends StatefulWidget {
  const CourseSelectScreen({
    super.key,
    this.fromPantry = false,
    this.focusIngredients,
  });

  final bool fromPantry;
  final List<String>? focusIngredients;

  @override
  State<CourseSelectScreen> createState() => _CourseSelectScreenState();
}

class _CourseOption {
  const _CourseOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
}

const _options = [
  _CourseOption(
    id: 'starter',
    title: 'Starter',
    subtitle: 'Small plates & first courses',
    icon: PhosphorIconsRegular.radioButton,
    background: AppColors.peachSoft,
    foreground: AppColors.peachText,
  ),
  _CourseOption(
    id: 'main',
    title: 'Main course',
    subtitle: 'A proper meal',
    icon: PhosphorIconsRegular.chefHat,
    background: AppColors.sageSoft,
    foreground: AppColors.forest,
  ),
  _CourseOption(
    id: 'drink',
    title: 'Drink',
    subtitle: 'Smoothies, juices & sips',
    icon: PhosphorIconsRegular.coffee,
    background: AppColors.skySoft,
    foreground: AppColors.skyText,
  ),
  _CourseOption(
    id: 'dessert',
    title: 'Dessert',
    subtitle: 'Something sweet to finish',
    icon: PhosphorIconsRegular.cake,
    background: AppColors.roseSoft,
    foreground: AppColors.roseText,
  ),
];

class _CourseSelectScreenState extends State<CourseSelectScreen> {
  String _selected = 'main';
  bool _submitting = false;

  Future<void> _generate() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    state.setSelectedCourse(_selected);
    await state.finalizeScanAndGenerate(
      fromPantryOnly: widget.fromPantry,
      pantryFocus: widget.focusIngredients,
    );
    if (!mounted) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChefScreen()),
      (route) => route.isFirst,
    );
  }

  List<String> _names(AppState state) {
    final focus = widget.focusIngredients;
    if (focus != null && focus.isNotEmpty) return focus;
    return state.cookableIngredients.map((item) => item.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    final names = _names(context.watch<AppState>());
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: PhosphorIconsRegular.arrowLeft,
                    semanticLabel: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  _StepBars(active: _submitting),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 22),
                    Text('What are we\nmaking?', style: AppText.h1()),
                    const SizedBox(height: 8),
                    Text(
                      'Recipes centre on what you picked.',
                      style: AppText.body(),
                    ),
                    const SizedBox(height: 22),
                    _IngredientBar(
                      names: names,
                      onEdit: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 22),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 172,
                      ),
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final selected = _selected == option.id;
                        return _CourseCard(
                          option: option,
                          selected: selected,
                          onTap: () => setState(() => _selected = option.id),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Center(child: AccountRulePills(centered: true)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Create 5 recipes',
                loading: _submitting,
                onPressed: _generate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBars extends StatelessWidget {
  const _StepBars({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _bar(AppColors.forest),
        const SizedBox(width: 6),
        _bar(active ? AppColors.forest : AppColors.sageTrack),
      ],
    );
  }

  Widget _bar(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _IngredientBar extends StatelessWidget {
  const _IngredientBar({required this.names, required this.onEdit});

  final List<String> names;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(4).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.chip,
      ),
      child: Row(
        children: [
          if (shown.isEmpty)
            const SizedBox(width: 8)
          else
            SizedBox(
              width: 30 + (shown.length - 1) * 22,
              height: 30,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: i * 22,
                      child: _LetterAvatar(letter: _initial(shown[i]), index: i),
                    ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _join(names),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(fontSize: 14),
            ),
          ),
          Pressable(
            semanticLabel: 'Edit ingredients',
            onTap: onEdit,
            child: Text(
              'Edit',
              style: AppText.label(color: AppColors.forest, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  String _join(List<String> names) {
    if (names.isEmpty) return 'Your pantry';
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} & ${names[1]}';
    return '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
  }
}

class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar({required this.letter, required this.index});

  final String letter;
  final int index;

  @override
  Widget build(BuildContext context) {
    const fills = [
      AppColors.peachSoft,
      AppColors.sageSoft,
      AppColors.butterSoft,
    ];
    const inks = [
      AppColors.peachText,
      AppColors.forest,
      AppColors.butterText,
    ];
    final i = index % fills.length;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fills[i],
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Text(
        letter,
        style: AppText.caption(color: inks[i], fontSize: 12),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _CourseOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: option.title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: option.background,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(
            color: selected ? AppColors.forest : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected ? AppShadows.primaryGlow : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(option.icon, color: option.foreground, size: 24),
                ),
                const Spacer(),
                Text(
                  option.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.courseTitle(),
                ),
                const SizedBox(height: 4),
                Text(
                  option.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption(
                    fontSize: 13,
                    color: AppColors.subtitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (selected)
              const Positioned(
                top: 0,
                right: 0,
                child: _CheckBadge(),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.forest,
        shape: BoxShape.circle,
      ),
      child: const Icon(PhosphorIconsRegular.check, color: Colors.white, size: 14),
    );
  }
}
